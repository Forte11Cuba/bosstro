//! The chat router: follows the channels of the active node and loaded key,
//! receives and stores their messages, and sends this key's.
//!
//! **Channels.** One per party of every dispute this key holds on the active
//! node (`in-progress`, taken by it, not expired) whose trade key the take
//! named. They are worked out again whenever the node, the key or a dispute
//! changes (a take, a recovery, a close, a reopen: every one comes through
//! the 38386 feed's updates). A closed dispute's channels close; its messages
//! stay, read only.
//!
//! **One subscription for them all.** Relays cap concurrent REQs per
//! connection (strfry: 20; nos.lol refused ../app's one-per-order REQs), so
//! the channels share one long-lived kind 14 REQ, `authors` = every channel's
//! `pub(K_sign)` (Mostrix `live_chat_filters`), through `nostr::live_subs`.
//! Each event goes to its conversation by its outer author. The REQ is
//! rebuilt only when the set of authors changes, make-before-break (Mostrix
//! `resubscribe`): the new one, under a new id, is issued before the old one
//! closes, so nothing published meanwhile falls between them. Past
//! [`MAX_AUTHORS_PER_REQ`] authors the set is split into a few REQs.
//!
//! **Since.** The REQ starts at the earliest of its channels' starts: each
//! channel's cursor (the newest `min(created_at, received_at)` of its stored
//! messages) minus an overlap, or, the first time, a little before the
//! dispute was opened (or taken). It never passes the local clock, so a
//! message dated in the future cannot silence a conversation. The copies the
//! earliest start brings to the other channels are dropped by id. **No
//! `limit`:** shared by every channel, a limit would let one long
//! conversation push another's messages out of the replay; `since` is what
//! bounds it. A relay's own cap on a filter's results still applies.
//!
//! **Checks, cheapest first** (the spec's order): the outer author, then the
//! outer id already handled ([`SeenOuter`]), then the conversation's rate
//! budget, then `mostro_core::chat::unwrap_chat_message` (the `p` tag, the
//! future bound, the size, both signatures, the allowed inner signers, the
//! inner kind, the inner/outer time skew), then the durable inner id (the
//! row's key). The budget is per conversation (per outer author) and counts
//! only what a relay sends live, after its stored events: a first sync of a
//! long conversation is bounded by `since` instead, and nothing of it is
//! dropped.
//!
//! **Back-pressure.** As the 38386 feed: the reader only passes this
//! router's events and EOSEs, in order, through an unbounded channel, so it
//! never falls behind the client's bounded broadcast; a second task does the
//! work.
//!
//! **Own messages.** `K_sign` is shared with the party, so this key's own
//! messages come back from the relays: the same inner id, the same row. One
//! that comes back is sent, whatever the publish said.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, OnceLock};

use mostro_core::chat::{unwrap_chat_message, wrap_chat_message};
use nostr_sdk::prelude::{
    Client, ClientNotification, Event, Filter, Keys, Kind, PublicKey, RelayMessage, StreamExt,
    SubscriptionId, Timestamp,
};
use tokio::sync::{broadcast, mpsc};

use super::observer::{ObservedRecord, ObservedRef, PastedKeys};
use super::{
    allowed_signers, channel_keys, sender_of, subscription_since, ChannelRef, ChatRecord,
    RateLimits, SeenOuter, MAX_AUTHORS_PER_REQ, MAX_MESSAGE_BYTES,
};
use crate::api::chat::{
    ChatChannelState, ChatDelivery, ChatError, ChatMessageView, ChatParty, ChatSender, ChatThread,
    ChatUpdate,
};
use crate::api::disputes::DisputeStatus;
use crate::db::Storage;
use crate::disputes::feed::Feed;
use crate::disputes::DisputeRecord;
use crate::nostr::live_subs::LiveSubs;

/// Capacity of the update channel toward Dart.
const UPDATE_CAPACITY: usize = 256;

pub(crate) fn lock<T>(mutex: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    mutex
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}

// ── Where messages go ─────────────────────────────────────────────────────────

/// The app's storage, or memory when it never opened.
pub(crate) enum ChatStore {
    Db(&'static crate::db::app_db::AppStorage),
    Memory(MemoryChat),
}

/// [`ChatStore::Memory`]: the messages, the attachment cache (encrypted
/// blobs by hash) and the observed chats (phase 5c).
#[derive(Default)]
pub(crate) struct MemoryChat {
    messages: Mutex<HashMap<ChannelRef, Vec<ChatRecord>>>,
    blobs: Mutex<HashMap<String, Vec<u8>>>,
    observed: Mutex<HashMap<ObservedRef, Vec<ObservedRecord>>>,
}

impl ChatStore {
    pub(crate) fn memory() -> Self {
        ChatStore::Memory(MemoryChat::default())
    }

    fn app() -> Self {
        match crate::db::app_db::db() {
            Some(db) => ChatStore::Db(db),
            None => ChatStore::memory(),
        }
    }

    async fn insert(&self, record: &ChatRecord) -> anyhow::Result<bool> {
        match self {
            ChatStore::Db(db) => db.insert_chat_message(record).await,
            ChatStore::Memory(m) => {
                let mut map = lock(&m.messages);
                let rows = map.entry(record.channel.clone()).or_default();
                if rows.iter().any(|r| r.message_id == record.message_id) {
                    return Ok(false);
                }
                rows.push(ChatRecord {
                    seq: super::next_seq(),
                    ..record.clone()
                });
                Ok(true)
            }
        }
    }

    pub(crate) async fn get(&self, channel: &ChannelRef, id: &str) -> anyhow::Result<Option<ChatRecord>> {
        match self {
            ChatStore::Db(db) => db.get_chat_message(channel, id).await,
            ChatStore::Memory(m) => Ok(lock(&m.messages)
                .get(channel)
                .and_then(|rows| rows.iter().find(|r| r.message_id == id).cloned())),
        }
    }

    pub(crate) async fn list(&self, channel: &ChannelRef) -> anyhow::Result<Vec<ChatRecord>> {
        match self {
            ChatStore::Db(db) => db.list_chat_messages(channel).await,
            ChatStore::Memory(m) => Ok(lock(&m.messages)
                .get(channel)
                .cloned()
                .unwrap_or_default()),
        }
    }

    async fn set_delivery(
        &self,
        channel: &ChannelRef,
        id: &str,
        delivery: ChatDelivery,
    ) -> anyhow::Result<()> {
        match self {
            ChatStore::Db(db) => db.set_chat_delivery(channel, id, delivery).await,
            ChatStore::Memory(m) => {
                if let Some(row) = lock(&m.messages)
                    .get_mut(channel)
                    .and_then(|rows| rows.iter_mut().find(|r| r.message_id == id))
                {
                    row.delivery = delivery;
                }
                Ok(())
            }
        }
    }

    async fn delete(&self, channel: &ChannelRef, id: &str) -> anyhow::Result<()> {
        match self {
            ChatStore::Db(db) => db.delete_chat_message(channel, id).await,
            ChatStore::Memory(m) => {
                if let Some(rows) = lock(&m.messages).get_mut(channel) {
                    rows.retain(|r| r.message_id != id);
                }
                Ok(())
            }
        }
    }

    async fn cursor(&self, channel: &ChannelRef) -> anyhow::Result<Option<i64>> {
        match self {
            ChatStore::Db(db) => db.chat_cursor(channel).await,
            ChatStore::Memory(_) => Ok(self
                .list(channel)
                .await?
                .iter()
                .map(ChatRecord::cursor)
                .max()),
        }
    }

    /// Keep an encrypted attachment blob under its hash (bounded cache).
    pub(crate) async fn save_blob(&self, sha256: &str, blob: &[u8]) -> anyhow::Result<()> {
        match self {
            ChatStore::Db(db) => db.save_attachment_blob(sha256, blob).await,
            ChatStore::Memory(m) => {
                lock(&m.blobs).insert(sha256.to_string(), blob.to_vec());
                Ok(())
            }
        }
    }

    /// The cached encrypted blob of `sha256`, if any.
    pub(crate) async fn get_blob(&self, sha256: &str) -> anyhow::Result<Option<Vec<u8>>> {
        match self {
            ChatStore::Db(db) => db.get_attachment_blob(sha256).await,
            ChatStore::Memory(m) => Ok(lock(&m.blobs).get(sha256).cloned()),
        }
    }

    /// Keep one message of an observed chat, unless that chat has its id.
    pub(crate) async fn insert_observed(&self, record: &ObservedRecord) -> anyhow::Result<bool> {
        match self {
            ChatStore::Db(db) => db.insert_observed_message(record).await,
            ChatStore::Memory(m) => {
                let mut map = lock(&m.observed);
                let rows = map.entry(record.conversation.clone()).or_default();
                if rows.iter().any(|r| r.message_id == record.message_id) {
                    return Ok(false);
                }
                rows.push(record.clone());
                Ok(true)
            }
        }
    }

    /// Every stored message of one observed chat.
    pub(crate) async fn list_observed(
        &self,
        observed: &ObservedRef,
    ) -> anyhow::Result<Vec<ObservedRecord>> {
        match self {
            ChatStore::Db(db) => db.list_observed_messages(observed).await,
            ChatStore::Memory(m) => Ok(lock(&m.observed)
                .get(observed)
                .cloned()
                .unwrap_or_default()),
        }
    }
}

// ── Channels ──────────────────────────────────────────────────────────────────

/// One followed conversation, with its keys (in memory only).
pub(crate) struct Channel {
    pub(crate) channel: ChannelRef,
    party_key: PublicKey,
    conv: Keys,
    sign: Keys,
    /// Where its first subscription reaches back to, when nothing is stored.
    opened_at: Option<i64>,
    taken_at: i64,
}

/// The id of one of the shared REQs of `node` and `solver` (hex):
/// `chat-<16 node>-<16 solver>-<generation>-<chunk>`, within NIP-01's 64
/// characters. A rebuild takes the next generation, so the new REQ can be
/// issued before the old one closes.
pub(crate) fn subscription_id(
    node: &str,
    solver: &str,
    generation: u64,
    chunk: usize,
) -> SubscriptionId {
    let short = |s: &str| s.chars().take(16).collect::<String>();
    SubscriptionId::new(format!(
        "chat-{}-{}-{generation}-{chunk}",
        short(node),
        short(solver)
    ))
}

/// Every chat event of `authors` (the channels' `pub(K_sign)`) from `since`
/// on. No `limit`: see the module's "Since".
pub(crate) fn channels_filter(authors: &[PublicKey], since: i64) -> Filter {
    Filter::new()
        .kind(Kind::PrivateDirectMessage)
        .authors(authors.iter().copied())
        .since(Timestamp::from_secs(since.max(0) as u64))
}

/// The shared REQs in place now: for whom, which authors, under which ids.
#[derive(Default)]
struct Shared {
    /// (node, solver) hex.
    owner: Option<(String, String)>,
    authors: std::collections::BTreeSet<PublicKey>,
    ids: Vec<SubscriptionId>,
}

/// The party's trade key the take named, if it parses.
pub(crate) fn party_key(row: &DisputeRecord, party: ChatParty) -> Option<PublicKey> {
    let taken = row.taken.as_ref()?;
    let hex = match party {
        ChatParty::Buyer => taken.buyer_pubkey.as_deref(),
        ChatParty::Seller => taken.seller_pubkey.as_deref(),
    }?;
    PublicKey::parse(hex).ok()
}

/// What a wanted channel needs to open: the party's trade key, the dispute's
/// open time and when this key took it.
#[derive(Clone, Copy)]
struct Wanted {
    party_key: PublicKey,
    opened_at: Option<i64>,
    taken_at: i64,
}

/// What the reader hands the worker, in the order the relays sent it.
enum Inbound {
    Event {
        relay: String,
        sub: SubscriptionId,
        event: Box<Event>,
    },
    EndOfStored {
        relay: String,
        sub: SubscriptionId,
    },
    Closed {
        relay: String,
        sub: SubscriptionId,
    },
}

/// A conversation of a dispute this key holds: the key, the channel, the
/// party's trade key when the take named it, and the dispute's row.
pub(crate) struct Conversation {
    pub(crate) keys: Keys,
    pub(crate) channel: ChannelRef,
    pub(crate) party_key: Option<PublicKey>,
    pub(crate) row: DisputeRecord,
}

/// Who the router works for: the active node (hex) and the loaded key.
#[derive(Clone)]
struct Target {
    node: String,
    keys: Keys,
}

pub(crate) struct Router {
    pub(crate) client: Arc<Client>,
    subs: &'static LiveSubs,
    feed: Arc<Feed>,
    pub(crate) store: ChatStore,
    updates: broadcast::Sender<ChatUpdate>,
    target: Mutex<Option<Target>>,
    channels: Mutex<HashMap<ChannelRef, Arc<Channel>>>,
    /// The shared REQs ([`Self::rebuild`]).
    shared: Mutex<Shared>,
    /// Bumped by every rebuild: the next REQs' id.
    generation: std::sync::atomic::AtomicU64,
    /// Every REQ id whose events are taken: the shared ones, and during a
    /// rebuild the previous ones too, for the reader.
    sub_ids: Mutex<HashSet<SubscriptionId>>,
    seen: Mutex<SeenOuter>,
    /// Per conversation, keyed by its outer author (`pub(K_sign)`).
    limits: Mutex<RateLimits<PublicKey>>,
    /// (relay, subscription) pairs past their EOSE: what those relays send
    /// now is live and counts against the rate budget.
    live: Mutex<HashSet<(String, SubscriptionId)>>,
    /// This key's messages being published now.
    in_flight: Mutex<HashSet<String>>,
    /// The monotonic origin of the rate budget's clock.
    started: crate::rt::time::Instant,
    /// Serialises the channel syncs.
    sync_lock: tokio::sync::Mutex<()>,
    /// Serialises read → write of one message's row.
    ingest_lock: tokio::sync::Mutex<()>,
    /// The shared keys the solver pasted (phase 5c), in memory only: every
    /// one not of the loaded key goes when the key changes or unloads.
    pub(crate) pasted: Mutex<PastedKeys>,
}

impl Router {
    pub(crate) fn new(
        client: Arc<Client>,
        subs: &'static LiveSubs,
        feed: Arc<Feed>,
        store: ChatStore,
        updates: broadcast::Sender<ChatUpdate>,
    ) -> Arc<Self> {
        Arc::new(Self {
            client,
            subs,
            feed,
            store,
            updates,
            target: Mutex::new(None),
            channels: Mutex::new(HashMap::new()),
            shared: Mutex::new(Shared::default()),
            generation: std::sync::atomic::AtomicU64::new(0),
            sub_ids: Mutex::new(HashSet::new()),
            seen: Mutex::new(SeenOuter::default()),
            limits: Mutex::new(RateLimits::default()),
            live: Mutex::new(HashSet::new()),
            in_flight: Mutex::new(HashSet::new()),
            started: crate::rt::time::Instant::now(),
            sync_lock: tokio::sync::Mutex::new(()),
            ingest_lock: tokio::sync::Mutex::new(()),
            pasted: Mutex::new(PastedKeys::new()),
        })
    }

    /// Read the client's notifications for as long as it lives (see the
    /// module's "Back-pressure").
    pub(crate) fn spawn_reader(self: &Arc<Self>) {
        let (tx, mut rx) = mpsc::unbounded_channel::<Inbound>();
        let mut notifications = self.client.notifications();
        let router = self.clone();
        crate::rt::spawn(async move {
            while let Some(notification) = notifications.next().await {
                let ClientNotification::Message { relay_url, message } = notification else {
                    continue;
                };
                let relay = relay_url.to_string();
                let inbound = match *message {
                    RelayMessage::Event {
                        subscription_id,
                        event,
                    } if event.kind == Kind::PrivateDirectMessage
                        && router.follows(&subscription_id) =>
                    {
                        Inbound::Event {
                            relay,
                            sub: subscription_id.into_owned(),
                            event: Box::new(event.into_owned()),
                        }
                    }
                    RelayMessage::EndOfStoredEvents(id) if router.follows(&id) => {
                        Inbound::EndOfStored {
                            relay,
                            sub: id.into_owned(),
                        }
                    }
                    RelayMessage::Closed {
                        subscription_id, ..
                    } if router.follows(&subscription_id) => Inbound::Closed {
                        relay,
                        sub: subscription_id.into_owned(),
                    },
                    _ => continue,
                };
                if tx.send(inbound).is_err() {
                    break;
                }
            }
        });
        let router = self.clone();
        crate::rt::spawn(async move {
            while let Some(inbound) = rx.recv().await {
                match inbound {
                    Inbound::Event { relay, sub, event } => {
                        router.handle(&relay, &sub, &event).await;
                    }
                    Inbound::EndOfStored { relay, sub } => {
                        lock(&router.live).insert((relay, sub));
                    }
                    // The SDK forgot it on that relay; get it back.
                    Inbound::Closed { relay, sub } => {
                        lock(&router.live).remove(&(relay.clone(), sub.clone()));
                        router.subs.on_closed(&router.client, &relay, &sub).await;
                    }
                }
            }
        });
    }

    fn follows(&self, sub: &SubscriptionId) -> bool {
        lock(&self.sub_ids).contains(sub)
    }

    /// The channels whose `pub(K_sign)` is `author`: one, unless two
    /// disputes share a party trade key.
    fn channels_of(&self, author: &PublicKey) -> Vec<Arc<Channel>> {
        lock(&self.channels)
            .values()
            .filter(|c| c.sign.public_key() == *author)
            .cloned()
            .collect()
    }

    /// The shared REQ ids in place now (tests).
    #[cfg(all(test, not(target_arch = "wasm32")))]
    pub(crate) fn shared_ids(&self) -> Vec<SubscriptionId> {
        lock(&self.shared).ids.clone()
    }

    /// The channels followed now (tests).
    #[cfg(all(test, not(target_arch = "wasm32")))]
    pub(crate) fn channel_refs(&self) -> Vec<ChannelRef> {
        lock(&self.channels).keys().cloned().collect()
    }

    /// Follow the channels of `node` and `keys`, or none: close those no
    /// longer wanted and open the new ones (see the module's "Channels").
    pub(crate) async fn sync(&self, node: Option<String>, keys: Option<Keys>) {
        let _guard = self.sync_lock.lock().await;
        let target = match (node, keys) {
            (Some(node), Some(keys)) => Some(Target { node, keys }),
            _ => None,
        };
        *lock(&self.target) = target.clone();
        // A pasted key belongs to the key that pasted it: a log out or
        // another key forgets it.
        let solver = target.as_ref().map(|t| t.keys.public_key().to_hex());
        lock(&self.pasted).retain(|observed, _| Some(&observed.solver_pubkey) == solver.as_ref());

        let mut wanted: HashMap<ChannelRef, Wanted> = HashMap::new();
        if let Some(target) = &target {
            let solver = target.keys.public_key().to_hex();
            let rows = match self
                .feed
                .rows_with_status(&target.node, DisputeStatus::InProgress)
                .await
            {
                Ok(rows) => rows,
                Err(e) => {
                    // What is followed stays; the next change tries again.
                    log::warn!("[chat] disputes not read: {e}");
                    return;
                }
            };
            let now = crate::rt::unix_now();
            for row in rows.iter().filter(|r| !r.is_expired(now)) {
                let Some(taken) = row.taken.as_ref().filter(|t| t.solver_pubkey == solver) else {
                    continue;
                };
                for party in [ChatParty::Buyer, ChatParty::Seller] {
                    let Some(key) = party_key(row, party) else {
                        continue;
                    };
                    let channel = ChannelRef {
                        mostro_pubkey: row.mostro_pubkey.clone(),
                        dispute_id: row.dispute_id.clone(),
                        party,
                        solver_pubkey: solver.clone(),
                    };
                    wanted.insert(
                        channel,
                        Wanted {
                            party_key: key,
                            opened_at: row.opened_at,
                            taken_at: taken.taken_at,
                        },
                    );
                }
            }
        }

        // Forget what is no longer wanted (or wanted with another party key).
        {
            let mut channels = lock(&self.channels);
            let gone: Vec<ChannelRef> = channels
                .iter()
                .filter(|(r, c)| wanted.get(*r).is_none_or(|w| w.party_key != c.party_key))
                .map(|(r, _)| r.clone())
                .collect();
            for r in gone {
                if let Some(c) = channels.remove(&r) {
                    lock(&self.limits).remove(&c.sign.public_key());
                }
            }
        }

        // Derive the new ones' keys.
        if let Some(target) = &target {
            let opening: Vec<(ChannelRef, Wanted)> = {
                let channels = lock(&self.channels);
                wanted
                    .into_iter()
                    .filter(|(r, _)| !channels.contains_key(r))
                    .collect()
            };
            for (channel, wanted) in opening {
                let (conv, sign) = match channel_keys(&target.keys, &wanted.party_key) {
                    Ok(keys) => keys,
                    Err(e) => {
                        log::warn!("[chat] channel not opened: {e}");
                        continue;
                    }
                };
                let followed = Arc::new(Channel {
                    channel: channel.clone(),
                    party_key: wanted.party_key,
                    conv,
                    sign,
                    opened_at: wanted.opened_at,
                    taken_at: wanted.taken_at,
                });
                lock(&self.channels).insert(channel, followed);
            }
        }

        self.rebuild(target.as_ref()).await;
    }

    /// Point the shared REQs at the channels followed now, when their set of
    /// authors (or the node and key they are for) changed; otherwise leave
    /// them. Make-before-break: the new REQs are issued under the next
    /// generation's ids before the previous ones close. Run under
    /// `sync_lock`.
    async fn rebuild(&self, target: Option<&Target>) {
        let owner = target.map(|t| (t.node.clone(), t.keys.public_key().to_hex()));
        let channels: Vec<Arc<Channel>> = lock(&self.channels).values().cloned().collect();
        let authors: std::collections::BTreeSet<PublicKey> =
            channels.iter().map(|c| c.sign.public_key()).collect();
        let previous = {
            let shared = lock(&self.shared);
            if shared.owner == owner && shared.authors == authors {
                return;
            }
            shared.ids.clone()
        };

        let mut ids = Vec::new();
        if let (Some((node, solver)), false) = (&owner, authors.is_empty()) {
            let now = crate::rt::unix_now();
            let mut since = now;
            for channel in &channels {
                let cursor = match self.store.cursor(&channel.channel).await {
                    Ok(cursor) => cursor,
                    Err(e) => {
                        log::warn!("[chat] cursor not read: {e}");
                        None
                    }
                };
                since = since.min(subscription_since(
                    cursor,
                    channel.opened_at,
                    channel.taken_at,
                    now,
                ));
            }
            let generation = self
                .generation
                .fetch_add(1, std::sync::atomic::Ordering::SeqCst)
                + 1;
            let authors: Vec<PublicKey> = authors.iter().copied().collect();
            for (chunk, part) in authors.chunks(MAX_AUTHORS_PER_REQ).enumerate() {
                let id = subscription_id(node, solver, generation, chunk);
                // Taken from its first event on.
                lock(&self.sub_ids).insert(id.clone());
                if let Err(e) = self
                    .subs
                    .replace(&self.client, id.clone(), channels_filter(part, since))
                    .await
                {
                    log::warn!("[chat] subscribe {id} failed: {e}");
                }
                ids.push(id);
            }
            log::info!(
                "[chat] following {} conversation(s) in {} REQ(s)",
                authors.len(),
                ids.len()
            );
        }
        {
            let mut shared = lock(&self.shared);
            shared.owner = owner;
            shared.authors = authors;
            shared.ids = ids;
        }
        // Break: the previous REQs go once the new ones are in place.
        for id in previous {
            self.subs.close(&self.client, &id).await;
            lock(&self.sub_ids).remove(&id);
            lock(&self.live).retain(|(_, sub)| sub != &id);
        }
    }

    /// One kind 14 of the shared REQs, checked cheapest first and taken to
    /// the conversation its outer author names.
    pub(crate) async fn handle(&self, relay: &str, sub: &SubscriptionId, event: &Event) {
        let channels = self.channels_of(&event.pubkey);
        if channels.is_empty() {
            return;
        }
        if lock(&self.seen).contains(&event.id) {
            return;
        }
        let is_live = lock(&self.live).contains(&(relay.to_string(), sub.clone()));
        if is_live {
            let now = self.started.elapsed().as_secs_f64();
            if !lock(&self.limits).allow(&event.pubkey, now) {
                // Not marked: a copy from another relay may still pass.
                log::debug!("[chat] a conversation is over its rate budget, event dropped");
                return;
            }
        }
        let mut handled = true;
        for channel in channels {
            handled &= self.ingest(&channel, event).await;
        }
        if handled {
            lock(&self.seen).insert(event.id);
        }
    }

    /// Open `event` on `channel` and store it. Returns whether it is done
    /// with (stored, a copy, or refused for good); `false` when storage
    /// failed and the next copy should try again.
    async fn ingest(&self, channel: &Channel, event: &Event) -> bool {
        let Ok(solver) = PublicKey::parse(&channel.channel.solver_pubkey) else {
            return true;
        };
        let allowed = allowed_signers(&solver, &channel.party_key);
        let message = match unwrap_chat_message(
            &channel.conv,
            &channel.sign.public_key(),
            &allowed,
            event,
            Timestamp::now(),
        ) {
            Ok(message) => message,
            Err(e) => {
                // The reason, never the content.
                log::debug!("[chat] event {} dropped: {e}", event.id.to_hex());
                return true;
            }
        };
        let Some(sender) = sender_of(
            &message.sender,
            &solver,
            channel.channel.party,
            &channel.party_key,
        ) else {
            return true;
        };
        let record = ChatRecord {
            channel: channel.channel.clone(),
            message_id: message.inner_event_id.to_hex(),
            sender,
            content: message.content,
            created_at: message.created_at.as_secs() as i64,
            received_at: crate::rt::unix_now(),
            delivery: ChatDelivery::Sent,
            seq: 0,
        };
        let changed = {
            let _guard = self.ingest_lock.lock().await;
            match self.store.insert(&record).await {
                Ok(true) => true,
                // A copy. This key's own message coming back from a relay
                // is sent, whatever its publish said.
                Ok(false) if sender == ChatSender::You => {
                    match self.store.get(&record.channel, &record.message_id).await {
                        Ok(Some(row)) if row.delivery != ChatDelivery::Sent => {
                            if let Err(e) = self
                                .store
                                .set_delivery(
                                    &record.channel,
                                    &record.message_id,
                                    ChatDelivery::Sent,
                                )
                                .await
                            {
                                log::warn!("[chat] delivery not stored: {e}");
                                return false;
                            }
                            true
                        }
                        _ => false,
                    }
                }
                Ok(false) => false,
                Err(e) => {
                    log::warn!("[chat] message not stored: {e}");
                    return false;
                }
            }
        };
        if changed {
            self.announce(&record.channel);
        }
        true
    }

    pub(crate) fn announce(&self, channel: &ChannelRef) {
        let _ = self.updates.send(ChatUpdate {
            mostro_pubkey: channel.mostro_pubkey.clone(),
            dispute_id: Some(channel.dispute_id.clone()),
            party: Some(channel.party),
        });
    }

    fn target(&self) -> Option<Target> {
        lock(&self.target).clone()
    }

    /// The conversation `party` of `dispute_id`, a dispute this key holds (or
    /// held until it closed) on the active node, whatever its status.
    pub(crate) async fn conversation(
        &self,
        dispute_id: &str,
        party: ChatParty,
    ) -> Result<Conversation, ChatError> {
        let target = self.target().ok_or(ChatError::NoKey)?;
        let solver = target.keys.public_key().to_hex();
        let row = self
            .feed
            .row(&target.node, dispute_id)
            .await
            .ok()
            .flatten()
            .ok_or(ChatError::UnknownDispute)?;
        if row.taken.as_ref().is_none_or(|t| t.solver_pubkey != solver) {
            return Err(ChatError::UnknownDispute);
        }
        let channel = ChannelRef {
            mostro_pubkey: target.node.clone(),
            dispute_id: dispute_id.to_string(),
            party,
            solver_pubkey: solver,
        };
        Ok(Conversation {
            party_key: party_key(&row, party),
            keys: target.keys,
            channel,
            row,
        })
    }

    /// The conversation `party` of `dispute_id`, when this key may write to
    /// it now; the reason otherwise.
    pub(crate) async fn writable(
        &self,
        dispute_id: &str,
        party: ChatParty,
    ) -> Result<(Keys, ChannelRef, PublicKey), ChatError> {
        let conversation = self.conversation(dispute_id, party).await?;
        if conversation.row.status.is_terminal() {
            return Err(ChatError::Closed);
        }
        if conversation.row.status != DisputeStatus::InProgress {
            return Err(ChatError::UnknownDispute);
        }
        let key = conversation.party_key.ok_or(ChatError::NoPartyKey)?;
        Ok((conversation.keys, conversation.channel, key))
    }

    /// Wrap `text` for `party` of `dispute_id`, store it `Sending` and
    /// publish it in the background; its delivery is announced.
    pub(crate) async fn send(
        self: &Arc<Self>,
        dispute_id: &str,
        party: ChatParty,
        text: &str,
    ) -> Result<ChatMessageView, ChatError> {
        let text = text.trim();
        if text.is_empty() {
            return Err(ChatError::Empty);
        }
        if text.len() > MAX_MESSAGE_BYTES {
            return Err(ChatError::TooLong);
        }
        let (keys, channel, party_key) = self.writable(dispute_id, party).await?;
        let (conv, sign) = channel_keys(&keys, &party_key).map_err(|e| {
            log::warn!("[chat] message not built: {e}");
            ChatError::NoPartyKey
        })?;
        let event = wrap_chat_message(&keys, &conv, &sign, text)
            .await
            .map_err(|e| {
                log::warn!("[chat] message not built: {e}");
                ChatError::NoPartyKey
            })?;
        // The inner id, read back the way the party will read it.
        let solver = keys.public_key();
        let opened = unwrap_chat_message(
            &conv,
            &sign.public_key(),
            &allowed_signers(&solver, &party_key),
            &event,
            Timestamp::now(),
        )
        .map_err(|e| {
            log::warn!("[chat] own message does not open: {e}");
            ChatError::NoPartyKey
        })?;
        let record = ChatRecord {
            channel: channel.clone(),
            message_id: opened.inner_event_id.to_hex(),
            sender: ChatSender::You,
            content: text.to_string(),
            created_at: opened.created_at.as_secs() as i64,
            received_at: crate::rt::unix_now(),
            delivery: ChatDelivery::Sending,
            seq: 0,
        };
        lock(&self.in_flight).insert(record.message_id.clone());
        {
            let _guard = self.ingest_lock.lock().await;
            // The same text in the same second is the same event: a retry
            // made at once sends the stored row again.
            let stored = match self.store.insert(&record).await {
                Ok(true) => Ok(()),
                Ok(false) => {
                    self.store
                        .set_delivery(&channel, &record.message_id, ChatDelivery::Sending)
                        .await
                }
                Err(e) => Err(e),
            };
            if let Err(e) = stored {
                lock(&self.in_flight).remove(&record.message_id);
                log::warn!("[chat] message not stored: {e}");
                return Err(ChatError::UnknownDispute);
            }
        }
        self.announce(&channel);

        let router = self.clone();
        let id = record.message_id.clone();
        crate::rt::spawn(async move {
            router.publish(&channel, &id, &event).await;
        });
        Ok(record.view(true))
    }

    /// Publish one of this key's messages and store how it went: sent when
    /// at least one relay took it (`send_event` is `Ok` even when every relay
    /// refused), failed otherwise unless a relay echoed it meanwhile.
    async fn publish(&self, channel: &ChannelRef, id: &str, event: &Event) {
        let delivered = match self.client.send_event(event).await {
            Ok(output) => !output.success.is_empty(),
            Err(e) => {
                log::warn!("[chat] message not sent: {e}");
                false
            }
        };
        {
            let _guard = self.ingest_lock.lock().await;
            let current = self.store.get(channel, id).await.ok().flatten();
            let next = match (current.map(|r| r.delivery), delivered) {
                (Some(ChatDelivery::Sent), _) | (None, _) => None,
                (Some(_), true) => Some(ChatDelivery::Sent),
                (Some(_), false) => Some(ChatDelivery::Failed),
            };
            if let Some(next) = next {
                if let Err(e) = self.store.set_delivery(channel, id, next).await {
                    log::warn!("[chat] delivery not stored: {e}");
                }
            }
            lock(&self.in_flight).remove(id);
        }
        if !delivered {
            log::warn!("[chat] no relay took a message");
        }
        self.announce(channel);
    }

    /// Send a failed message of this key again, as a new message that
    /// replaces it.
    pub(crate) async fn retry(
        self: &Arc<Self>,
        dispute_id: &str,
        party: ChatParty,
        message_id: &str,
    ) -> Result<ChatMessageView, ChatError> {
        let (_, channel, _) = self.writable(dispute_id, party).await?;
        let in_flight = lock(&self.in_flight).contains(message_id);
        let record = self
            .store
            .get(&channel, message_id)
            .await
            .ok()
            .flatten()
            .filter(|r| r.sender == ChatSender::You)
            .filter(|r| r.view(in_flight).delivery == ChatDelivery::Failed)
            .ok_or(ChatError::UnknownMessage)?;
        let sent = self.send(dispute_id, party, &record.content).await?;
        if sent.id != message_id {
            if let Err(e) = self.store.delete(&channel, message_id).await {
                log::warn!("[chat] failed message not removed: {e}");
            }
        }
        self.announce(&channel);
        Ok(sent)
    }

    /// The conversation as the chat shows it: oldest first, a second's ties
    /// in arrival order ([`sorted_views`]).
    pub(crate) async fn messages(
        &self,
        channel: &ChannelRef,
    ) -> anyhow::Result<Vec<ChatMessageView>> {
        let in_flight = lock(&self.in_flight).clone();
        Ok(sorted_views(&self.store.list(channel).await?, |id| {
            in_flight.contains(id)
        }))
    }
}

/// `records` oldest first, as views. Messages of the same second (the
/// resolution of `created_at`) go in the order they arrived here: by
/// `received_at`, then the order they were stored in (`seq`); the random
/// inner id only decides between rows that predate `seq`.
fn sorted_views(records: &[ChatRecord], in_flight: impl Fn(&str) -> bool) -> Vec<ChatMessageView> {
    let mut sorted: Vec<&ChatRecord> = records.iter().collect();
    sorted.sort_by(|a, b| {
        a.created_at
            .cmp(&b.created_at)
            .then_with(|| a.received_at.cmp(&b.received_at))
            .then_with(|| a.seq.cmp(&b.seq))
            .then_with(|| a.message_id.cmp(&b.message_id))
    });
    sorted
        .into_iter()
        .map(|r| r.view(in_flight(&r.message_id)))
        .collect()
}

// ── The process-wide router ───────────────────────────────────────────────────

static ROUTER: OnceLock<Arc<Router>> = OnceLock::new();

/// The process-wide router, once the relay pool started it.
pub(crate) fn router() -> Option<&'static Arc<Router>> {
    ROUTER.get()
}

fn updates() -> &'static broadcast::Sender<ChatUpdate> {
    static UPDATES: OnceLock<broadcast::Sender<ChatUpdate>> = OnceLock::new();
    UPDATES.get_or_init(|| broadcast::channel(UPDATE_CAPACITY).0)
}

pub(crate) fn subscribe_updates() -> broadcast::Receiver<ChatUpdate> {
    updates().subscribe()
}

/// Start the router on the relay pool's client, beside the dispute feed, and
/// follow the feed's changes. Called once the pool exists; later calls only
/// re-point it.
pub(crate) async fn start(client: Arc<Client>, feed: Arc<Feed>) {
    let router = ROUTER.get_or_init(|| {
        let router = Router::new(
            client,
            crate::nostr::live_subs::live_subs(),
            feed,
            ChatStore::app(),
            updates().clone(),
        );
        router.spawn_reader();
        spawn_feed_listener(router.clone());
        router
    });
    follow_with(router).await;
}

/// Every dispute change may open or close a channel (a take, a recovery, a
/// close, a reopen). A burst of changes (a node's first sync) costs one sync
/// per batch.
fn spawn_feed_listener(router: Arc<Router>) {
    let mut rx = crate::disputes::feed::subscribe_updates();
    crate::rt::spawn(async move {
        use tokio::sync::broadcast::error::{RecvError, TryRecvError};
        loop {
            match rx.recv().await {
                Ok(_) | Err(RecvError::Lagged(_)) => {}
                Err(RecvError::Closed) => break,
            }
            while let Ok(_) | Err(TryRecvError::Lagged(_)) = rx.try_recv() {}
            follow_with(&router).await;
        }
    });
}

/// Re-point the router at the active node and the loaded key, after either
/// changes. A no-op before the pool started.
pub(crate) async fn follow() {
    if let Some(router) = ROUTER.get() {
        follow_with(router).await;
    }
}

async fn follow_with(router: &Router) {
    let keys = crate::solver_slot::SOLVER_SLOT.keys().await;
    router
        .sync(crate::config::active_mostro_pubkey(), keys)
        .await;
}

/// The active node and the loaded key, or why not.
pub(crate) async fn node_and_keys() -> Result<(String, Keys), ChatError> {
    let keys = crate::solver_slot::SOLVER_SLOT
        .keys()
        .await
        .ok_or(ChatError::NoKey)?;
    let node = crate::config::active_mostro_pubkey().ok_or(ChatError::NoNode)?;
    Ok((node, keys))
}

pub(crate) async fn send(
    dispute_id: &str,
    party: ChatParty,
    text: &str,
) -> Result<ChatMessageView, ChatError> {
    node_and_keys().await?;
    let router = ROUTER.get().ok_or(ChatError::NoRelays)?;
    router.send(dispute_id, party, text).await
}

pub(crate) async fn retry(
    dispute_id: &str,
    party: ChatParty,
    message_id: &str,
) -> Result<ChatMessageView, ChatError> {
    node_and_keys().await?;
    let router = ROUTER.get().ok_or(ChatError::NoRelays)?;
    router.retry(dispute_id, party, message_id).await
}

/// The conversation with `party` of `dispute_id`, a dispute this key took on
/// the active node; `None` otherwise. Read from storage, so it works before
/// the relays are up and after the dispute closed.
pub(crate) async fn thread(
    dispute_id: &str,
    party: ChatParty,
) -> anyhow::Result<Option<ChatThread>> {
    let Ok((node, keys)) = node_and_keys().await else {
        return Ok(None);
    };
    let solver = keys.public_key().to_hex();
    let row = match crate::db::app_db::db() {
        Some(db) => db.get_dispute(&node, dispute_id).await?,
        None => match crate::disputes::feed::feed() {
            Some(feed) => feed.row(&node, dispute_id).await?,
            None => None,
        },
    };
    let Some(row) = row else {
        return Ok(None);
    };
    if row.taken.as_ref().is_none_or(|t| t.solver_pubkey != solver) {
        return Ok(None);
    }
    let channel = ChannelRef {
        mostro_pubkey: node.clone(),
        dispute_id: dispute_id.to_string(),
        party,
        solver_pubkey: solver,
    };
    let messages = match ROUTER.get() {
        Some(router) => router.messages(&channel).await?,
        None => match crate::db::app_db::db() {
            Some(db) => sorted_views(&db.list_chat_messages(&channel).await?, |_| false),
            None => Vec::new(),
        },
    };
    Ok(Some(ChatThread {
        state: thread_state(&row, party),
        mostro_pubkey: node,
        dispute_id: dispute_id.to_string(),
        party,
        messages,
    }))
}

/// Whether `party`'s conversation of `row` can be written to.
pub(crate) fn thread_state(row: &DisputeRecord, party: ChatParty) -> ChatChannelState {
    if row.status.is_terminal() {
        ChatChannelState::Closed
    } else if party_key(row, party).is_none() {
        ChatChannelState::NoPartyKey
    } else {
        ChatChannelState::Open
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod tests {
    use super::*;
    use crate::disputes::event::tests::mostrod_event;
    use crate::disputes::feed::Store;
    use crate::disputes::TakenDispute;
    use mostro_core::chat::SharedKey;
    use nostr::nips::nip44;
    use nostr_sdk::local_relay::MockRelay;
    use nostr_sdk::prelude::*;
    use std::time::Duration;

    pub(crate) const DISPUTE_A: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
    const DISPUTE_B: &str = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";

    pub(crate) async fn connected(relay: &MockRelay) -> Arc<Client> {
        let url = relay.url().await;
        let client = Arc::new(Client::new());
        client.add_relay(&url).await.unwrap();
        client
            .try_connect_relay(&url, Duration::from_secs(3))
            .await
            .unwrap();
        client
    }

    /// Wait until `check` holds, or fail after a few seconds.
    pub(crate) async fn eventually<F, Fut>(what: &str, mut check: F)
    where
        F: FnMut() -> Fut,
        Fut: std::future::Future<Output = bool>,
    {
        for _ in 0..100 {
            if check().await {
                return;
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
        panic!("timed out waiting for: {what}");
    }

    /// One side of a dispute: its trade key.
    pub(crate) struct Party {
        pub(crate) keys: Keys,
        pub(crate) client: Arc<Client>,
    }

    impl Party {
        /// Write `text` to the solver, as a party's client does.
        pub(crate) async fn say(&self, solver: &PublicKey, text: &str) -> Event {
            let (conv, sign) = channel_keys(&self.keys, solver).unwrap();
            let event = wrap_chat_message(&self.keys, &conv, &sign, text)
                .await
                .unwrap();
            self.publish(&event).await;
            event
        }

        pub(crate) async fn publish(&self, event: &Event) {
            let output = self.client.send_event(event).await.unwrap();
            assert!(!output.success.is_empty(), "the relay refused it");
        }

        /// What the party reads from the solver's channel, as (sender, text).
        pub(crate) async fn read(&self, solver: &PublicKey) -> Vec<(PublicKey, String)> {
            let (conv, sign) = channel_keys(&self.keys, solver).unwrap();
            let events = self
                .client
                .fetch_events(mostro_core::chat::chat_filter(sign.public_key()))
                .timeout(Duration::from_secs(3))
                .await
                .unwrap();
            let allowed = [self.keys.public_key(), *solver];
            events
                .iter()
                .filter_map(|e| {
                    unwrap_chat_message(&conv, &sign.public_key(), &allowed, e, Timestamp::now())
                        .ok()
                })
                .map(|m| (m.sender, m.content))
                .collect()
        }
    }

    pub(crate) struct Bench {
        pub(crate) relay: MockRelay,
        pub(crate) node: Keys,
        pub(crate) solver: Keys,
        pub(crate) buyer: Party,
        pub(crate) seller: Party,
        pub(crate) feed: Arc<Feed>,
        pub(crate) router: Arc<Router>,
        pub(crate) updates: broadcast::Receiver<ChatUpdate>,
    }

    fn taken(solver: &Keys, buyer: Option<&Keys>, seller: Option<&Keys>) -> TakenDispute {
        TakenDispute {
            solver_pubkey: solver.public_key().to_hex(),
            taken_at: crate::rt::unix_now() - 3_600,
            order_id: Some("5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d".into()),
            order_kind: Some("sell".into()),
            amount: Some(10_000),
            fiat_amount: Some(5),
            fiat_code: None,
            payment_method: Some("bank".into()),
            premium: Some(0),
            fee: Some(10),
            initiator_pubkey: None,
            buyer_pubkey: buyer.map(|k| k.public_key().to_hex()),
            seller_pubkey: seller.map(|k| k.public_key().to_hex()),
            resolved_as: None,
            bond_slash: None,
            order_previous_status: None,
        }
    }

    pub(crate) async fn bench_with(feed_store: Store, chat_store: ChatStore) -> Bench {
        let relay = MockRelay::run().await.unwrap();
        let client = connected(&relay).await;
        let node = Keys::generate();
        let solver = Keys::generate();
        let (buyer, seller) = (Keys::generate(), Keys::generate());
        let (dispute_tx, _) = broadcast::channel(16);
        let feed_subs: &'static LiveSubs = Box::leak(Box::default());
        let feed = Feed::new(client.clone(), feed_store, feed_subs, dispute_tx);
        feed.spawn_reader();
        feed.record_take(
            &node.public_key().to_hex(),
            DISPUTE_A,
            taken(&solver, Some(&buyer), Some(&seller)),
        )
        .await
        .unwrap();
        let (tx, updates) = broadcast::channel(UPDATE_CAPACITY);
        let subs: &'static LiveSubs = Box::leak(Box::default());
        let router = Router::new(client, subs, feed.clone(), chat_store, tx);
        router.spawn_reader();
        router
            .sync(Some(node.public_key().to_hex()), Some(solver.clone()))
            .await;
        let buyer = Party {
            client: connected(&relay).await,
            keys: buyer,
        };
        let seller = Party {
            client: connected(&relay).await,
            keys: seller,
        };
        Bench {
            relay,
            node,
            solver,
            buyer,
            seller,
            feed,
            router,
            updates,
        }
    }

    pub(crate) async fn bench() -> Bench {
        bench_with(Store::memory(), ChatStore::memory()).await
    }

    impl Bench {
        pub(crate) fn channel(&self, dispute: &str, party: ChatParty) -> ChannelRef {
            ChannelRef {
                mostro_pubkey: self.node.public_key().to_hex(),
                dispute_id: dispute.into(),
                party,
                solver_pubkey: self.solver.public_key().to_hex(),
            }
        }

        pub(crate) async fn messages(&self, dispute: &str, party: ChatParty) -> Vec<ChatMessageView> {
            self.router
                .messages(&self.channel(dispute, party))
                .await
                .unwrap()
        }

        pub(crate) async fn wait_for(&self, dispute: &str, party: ChatParty, count: usize) {
            let what = format!("{count} message(s) with the {party:?} of {dispute}");
            eventually(&what, || async {
                self.messages(dispute, party).await.len() >= count
            })
            .await;
        }
    }

    #[tokio::test]
    async fn a_party_writes_and_the_solver_answers_both_ways() {
        let b = bench().await;
        let solver = b.solver.public_key();
        b.buyer.say(&solver, "  the fiat never arrived").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        let got = b.messages(DISPUTE_A, ChatParty::Buyer).await;
        assert_eq!(got[0].sender, ChatSender::Buyer);
        assert_eq!(got[0].content, "  the fiat never arrived");

        let sent = b
            .router
            .send(
                DISPUTE_A,
                ChatParty::Buyer,
                "  Send me the receipt, please.\n",
            )
            .await
            .unwrap();
        assert_eq!(sent.sender, ChatSender::You);
        assert_eq!(sent.content, "Send me the receipt, please.", "trimmed");
        assert_eq!(sent.delivery, ChatDelivery::Sending);

        // The party reads it, signed by the solver key.
        eventually("the buyer reads the answer", || async {
            b.buyer
                .read(&solver)
                .await
                .contains(&(solver, "Send me the receipt, please.".to_string()))
        })
        .await;
        // It came back from the relay (K_sign is shared): sent, and once.
        eventually("the answer is sent", || async {
            b.messages(DISPUTE_A, ChatParty::Buyer)
                .await
                .iter()
                .any(|m| m.id == sent.id && m.delivery == ChatDelivery::Sent)
        })
        .await;
        tokio::time::sleep(Duration::from_millis(300)).await;
        let all = b.messages(DISPUTE_A, ChatParty::Buyer).await;
        assert_eq!(all.len(), 2, "no copy of the echo");
        assert_eq!(all.iter().filter(|m| m.id == sent.id).count(), 1);
        // The seller's conversation saw none of it.
        assert!(b.messages(DISPUTE_A, ChatParty::Seller).await.is_empty());
        assert!(b.seller.read(&solver).await.is_empty());
    }

    #[tokio::test]
    async fn every_change_is_announced_for_its_conversation() {
        let mut b = bench().await;
        b.seller.say(&b.solver.public_key(), "hello").await;
        let update = tokio::time::timeout(Duration::from_secs(3), b.updates.recv())
            .await
            .unwrap()
            .unwrap();
        assert_eq!(update.dispute_id.as_deref(), Some(DISPUTE_A));
        assert_eq!(update.party, Some(ChatParty::Seller));
        assert_eq!(update.mostro_pubkey, b.node.public_key().to_hex());
    }

    /// An inner event signed by anyone but the party and the solver is
    /// dropped, even inside a valid envelope (the party holds K_sign), and
    /// the other party's key is a stranger on this channel.
    #[tokio::test]
    async fn an_unknown_inner_signer_is_dropped() {
        let b = bench().await;
        let solver = b.solver.public_key();
        let (conv, sign) = channel_keys(&b.buyer.keys, &solver).unwrap();
        for impostor in [Keys::generate(), b.seller.keys.clone()] {
            let forged = wrap_chat_message(&impostor, &conv, &sign, "pay me instead")
                .await
                .unwrap();
            b.buyer.publish(&forged).await;
        }
        b.buyer.say(&solver, "the real one").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        tokio::time::sleep(Duration::from_millis(300)).await;
        let got = b.messages(DISPUTE_A, ChatParty::Buyer).await;
        assert_eq!(got.len(), 1);
        assert_eq!(got[0].content, "the real one");
    }

    /// The same envelope delivered twice, and the same inner event re-wrapped
    /// in a new envelope (a replay), are one message.
    #[tokio::test]
    async fn copies_and_replays_are_one_message() {
        let b = bench().await;
        let solver = b.solver.public_key();
        let event = b.buyer.say(&solver, "once").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        b.router
            .handle("wss://another.relay", &b.router.the_sub(), &event)
            .await;
        // Re-wrap the same inner event in a fresh envelope.
        let (conv, sign) = channel_keys(&b.buyer.keys, &solver).unwrap();
        let inner_json =
            nip44::decrypt(conv.secret_key(), &conv.public_key(), &event.content).unwrap();
        let content = nip44::encrypt(
            conv.secret_key(),
            &conv.public_key(),
            inner_json,
            nip44::Version::V2,
        )
        .unwrap();
        let replay = EventBuilder::new(Kind::PrivateDirectMessage, content)
            .tag(nostr_sdk::prelude::Tag::public_key(conv.public_key()))
            .custom_created_at(event.created_at)
            .finalize(&sign)
            .unwrap();
        assert_ne!(replay.id, event.id);
        b.buyer.publish(&replay).await;
        tokio::time::sleep(Duration::from_millis(400)).await;
        assert_eq!(b.messages(DISPUTE_A, ChatParty::Buyer).await.len(), 1);
    }

    /// A message dated in the future (within the spec's 60 s) is taken, but
    /// the cursor stays at the local clock, so the next subscription still
    /// sees what comes after it.
    #[tokio::test]
    async fn a_future_date_never_moves_the_cursor_past_the_clock() {
        let b = bench().await;
        let solver = b.solver.public_key();
        let (conv, sign) = channel_keys(&b.seller.keys, &solver).unwrap();
        let ahead = Timestamp::from_secs(Timestamp::now().as_secs() + 50);
        let inner = EventBuilder::new(Kind::TextNote, "from the future")
            .custom_created_at(ahead)
            .finalize(&b.seller.keys)
            .unwrap();
        let content = nip44::encrypt(
            conv.secret_key(),
            &conv.public_key(),
            inner.as_json(),
            nip44::Version::V2,
        )
        .unwrap();
        let outer = EventBuilder::new(Kind::PrivateDirectMessage, content)
            .tag(nostr_sdk::prelude::Tag::public_key(conv.public_key()))
            .custom_created_at(ahead)
            .finalize(&sign)
            .unwrap();
        b.seller.publish(&outer).await;
        b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;

        let channel = b.channel(DISPUTE_A, ChatParty::Seller);
        let now = crate::rt::unix_now();
        let cursor = b.router.store.cursor(&channel).await.unwrap().unwrap();
        assert!(cursor <= now, "cursor {cursor} passed the clock {now}");
        assert!(subscription_since(Some(cursor), None, 0, now) < now);
    }

    #[tokio::test]
    async fn two_disputes_never_mix() {
        let b = bench().await;
        let solver = b.solver.public_key();
        let (other_buyer, other_seller) = (Keys::generate(), Keys::generate());
        b.feed
            .record_take(
                &b.node.public_key().to_hex(),
                DISPUTE_B,
                taken(&b.solver, Some(&other_buyer), Some(&other_seller)),
            )
            .await
            .unwrap();
        b.router
            .sync(Some(b.node.public_key().to_hex()), Some(b.solver.clone()))
            .await;
        assert_eq!(b.router.channel_refs().len(), 4);
        let other = Party {
            client: connected(&b.relay).await,
            keys: other_buyer,
        };
        other.say(&solver, "dispute B").await;
        b.buyer.say(&solver, "dispute A").await;
        b.wait_for(DISPUTE_B, ChatParty::Buyer, 1).await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        tokio::time::sleep(Duration::from_millis(300)).await;
        assert_eq!(
            b.messages(DISPUTE_A, ChatParty::Buyer).await[0].content,
            "dispute A"
        );
        let b_msgs = b.messages(DISPUTE_B, ChatParty::Buyer).await;
        assert_eq!(b_msgs.len(), 1);
        assert_eq!(b_msgs[0].content, "dispute B");
    }

    /// A closed dispute's channels close (its messages stay, read only); so
    /// does every channel when the key is unloaded.
    #[tokio::test]
    async fn closing_a_dispute_or_unloading_the_key_closes_its_channels() {
        let b = bench().await;
        b.buyer.say(&b.solver.public_key(), "before").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        let node = b.node.public_key().to_hex();
        assert_eq!(b.router.channel_refs().len(), 2);

        b.feed.retarget(Some(node.clone())).await;
        let now = crate::rt::unix_now() as u64;
        b.feed
            .ingest(&mostrod_event(&b.node, DISPUTE_A, "settled", now))
            .await
            .unwrap();
        b.router
            .sync(Some(node.clone()), Some(b.solver.clone()))
            .await;
        assert!(b.router.channel_refs().is_empty());
        assert_eq!(
            b.router
                .send(DISPUTE_A, ChatParty::Buyer, "too late")
                .await
                .unwrap_err(),
            ChatError::Closed
        );
        assert_eq!(b.messages(DISPUTE_A, ChatParty::Buyer).await.len(), 1);
        let row = b.feed.row(&node, DISPUTE_A).await.unwrap().unwrap();
        assert_eq!(
            thread_state(&row, ChatParty::Buyer),
            ChatChannelState::Closed
        );

        // A key unload closes everything.
        let c = bench().await;
        assert_eq!(c.router.channel_refs().len(), 2);
        c.router
            .sync(Some(c.node.public_key().to_hex()), None)
            .await;
        assert!(c.router.channel_refs().is_empty());
        assert_eq!(
            c.router
                .send(DISPUTE_A, ChatParty::Buyer, "hi")
                .await
                .unwrap_err(),
            ChatError::NoKey
        );
    }

    #[tokio::test]
    async fn what_cannot_be_sent_is_refused_before_anything_leaves() {
        let b = bench().await;
        let send = |text: &'static str, dispute: &'static str| {
            let router = b.router.clone();
            async move { router.send(dispute, ChatParty::Seller, text).await }
        };
        assert_eq!(
            send(" \n\t ", DISPUTE_A).await.unwrap_err(),
            ChatError::Empty
        );
        let long: &'static str = Box::leak("x".repeat(MAX_MESSAGE_BYTES + 1).into_boxed_str());
        assert_eq!(send(long, DISPUTE_A).await.unwrap_err(), ChatError::TooLong);
        assert_eq!(
            send("hi", DISPUTE_B).await.unwrap_err(),
            ChatError::UnknownDispute
        );

        // A take that named no seller has no seller channel.
        b.feed
            .record_take(
                &b.node.public_key().to_hex(),
                DISPUTE_B,
                taken(&b.solver, Some(&Keys::generate()), None),
            )
            .await
            .unwrap();
        assert_eq!(
            send("hi", DISPUTE_B).await.unwrap_err(),
            ChatError::NoPartyKey
        );
        // Another key's dispute is not this key's to write in.
        b.feed
            .record_take(
                &b.node.public_key().to_hex(),
                DISPUTE_B,
                taken(
                    &Keys::generate(),
                    Some(&Keys::generate()),
                    Some(&Keys::generate()),
                ),
            )
            .await
            .unwrap();
        assert_eq!(
            send("hi", DISPUTE_B).await.unwrap_err(),
            ChatError::UnknownDispute
        );
        assert!(b.messages(DISPUTE_A, ChatParty::Seller).await.is_empty());
    }

    /// No relay takes it: failed, and not sent again by itself. A retry is
    /// a new message that replaces it.
    #[tokio::test]
    async fn a_message_no_relay_took_fails_and_a_retry_replaces_it() {
        let b = bench().await;
        b.relay.shutdown();
        let sent = b
            .router
            .send(DISPUTE_A, ChatParty::Seller, "are you there?")
            .await
            .unwrap();
        eventually("the message fails", || async {
            b.messages(DISPUTE_A, ChatParty::Seller)
                .await
                .iter()
                .any(|m| m.id == sent.id && m.delivery == ChatDelivery::Failed)
        })
        .await;
        // Only a failed message of this key can be retried.
        assert_eq!(
            b.router
                .retry(DISPUTE_A, ChatParty::Seller, "not-an-id")
                .await
                .unwrap_err(),
            ChatError::UnknownMessage
        );
        // At once (often the same second, so the same event): sent again.
        let again = b
            .router
            .retry(DISPUTE_A, ChatParty::Seller, &sent.id)
            .await
            .unwrap();
        assert_eq!(again.content, "are you there?");
        assert_eq!(again.delivery, ChatDelivery::Sending);
        let all = b.messages(DISPUTE_A, ChatParty::Seller).await;
        assert_eq!(all.len(), 1, "the retry replaced it");
        assert_eq!(all[0].id, again.id);
        // nostr-sdk waits up to its send timeout on a relay reconnecting.
        for _ in 0..300 {
            if b.messages(DISPUTE_A, ChatParty::Seller).await[0].delivery == ChatDelivery::Failed {
                break;
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
        assert_eq!(
            b.messages(DISPUTE_A, ChatParty::Seller).await[0].delivery,
            ChatDelivery::Failed
        );

        // A second later it is a new event (a new id and time).
        tokio::time::sleep(Duration::from_millis(1_100)).await;
        let later = b
            .router
            .retry(DISPUTE_A, ChatParty::Seller, &again.id)
            .await
            .unwrap();
        assert_ne!(later.id, again.id);
        let all = b.messages(DISPUTE_A, ChatParty::Seller).await;
        assert_eq!(all.len(), 1, "the retry replaced it");
        assert_eq!(all[0].id, later.id);
    }

    /// Messages of the same second show in the order they arrived, not by
    /// their random ids: three stored in arrival order read in that order,
    /// in memory and in SQLite.
    #[tokio::test]
    async fn messages_of_the_same_second_keep_their_arrival_order() {
        let path = crate::db::sqlite::tests::temp_db_path();
        let storage: &'static crate::db::sqlite::SqliteStorage = Box::leak(Box::new(
            crate::db::sqlite::SqliteStorage::open(path.to_str().unwrap())
                .await
                .unwrap(),
        ));
        for store in [ChatStore::memory(), ChatStore::Db(storage)] {
            let b = bench_with(Store::memory(), store).await;
            let channel = b.channel(DISPUTE_A, ChatParty::Buyer);
            // Ids against the arrival order, so sorting by id would invert it.
            let arrived = [
                ("ff", ChatSender::Buyer, "Hola, ya te hice la transferencia"),
                ("88", ChatSender::You, "Gracias, lo reviso"),
                ("00", ChatSender::Buyer, "Te mando el comprobante"),
            ];
            for (id, sender, text) in arrived {
                let record = ChatRecord {
                    channel: channel.clone(),
                    message_id: id.into(),
                    sender,
                    content: text.into(),
                    created_at: 1_700_000_000,
                    received_at: 1_700_000_001,
                    delivery: ChatDelivery::Sent,
                    seq: 0,
                };
                assert!(b.router.store.insert(&record).await.unwrap());
            }
            let shown: Vec<String> = b
                .messages(DISPUTE_A, ChatParty::Buyer)
                .await
                .into_iter()
                .map(|m| m.id)
                .collect();
            assert_eq!(shown, ["ff", "88", "00"]);
        }
    }

    /// Nothing secret reaches the database: neither the solver's key, nor
    /// the ECDH secret Mostrix persists, nor K_conv or K_sign.
    #[tokio::test]
    async fn no_secret_is_written_to_storage() {
        let path = crate::db::sqlite::tests::temp_db_path();
        let storage: &'static crate::db::sqlite::SqliteStorage = Box::leak(Box::new(
            crate::db::sqlite::SqliteStorage::open(path.to_str().unwrap())
                .await
                .unwrap(),
        ));
        let b = bench_with(Store::Db(storage), ChatStore::Db(storage)).await;
        let solver = b.solver.public_key();
        b.buyer.say(&solver, "hello").await;
        b.seller.say(&solver, "hi").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;
        let sent = b
            .router
            .send(DISPUTE_A, ChatParty::Buyer, "noted")
            .await
            .unwrap();
        eventually("sent", || async {
            b.messages(DISPUTE_A, ChatParty::Buyer)
                .await
                .iter()
                .any(|m| m.id == sent.id && m.delivery == ChatDelivery::Sent)
        })
        .await;

        let mut secrets: Vec<[u8; 32]> = vec![b.solver.secret_key().to_secret_bytes()];
        for party in [&b.buyer.keys, &b.seller.keys] {
            let shared = SharedKey::derive(b.solver.secret_key(), &party.public_key()).unwrap();
            secrets.push(shared.secret_key().to_secret_bytes());
            let (conv, sign) = channel_keys(&b.solver, &party.public_key()).unwrap();
            secrets.push(conv.secret_key().to_secret_bytes());
            secrets.push(sign.secret_key().to_secret_bytes());
        }
        // Every byte the database wrote: the file and its WAL.
        let mut written = Vec::new();
        for suffix in ["", "-wal", "-shm"] {
            let file = format!("{}{suffix}", path.to_str().unwrap());
            if let Ok(bytes) = std::fs::read(&file) {
                written.extend(bytes);
            }
        }
        assert!(
            written.windows(5).any(|w| w == b"hello"),
            "the messages are there, so the scan sees what is written"
        );
        let text = String::from_utf8_lossy(&written).to_lowercase();
        for secret in &secrets {
            let hex: String = secret.iter().map(|b| format!("{b:02x}")).collect();
            assert!(!text.contains(&hex), "a secret was written as hex");
            assert!(
                !written.windows(32).any(|w| w == secret),
                "a secret was written as bytes"
            );
        }
        let nsec = nostr_sdk::prelude::ToBech32::to_bech32(b.solver.secret_key()).unwrap();
        assert!(!text.contains(&nsec));
    }

    impl Router {
        /// The shared REQ's id (tests: one REQ is in place).
        fn the_sub(&self) -> SubscriptionId {
            let ids = self.shared_ids();
            assert_eq!(ids.len(), 1, "{ids:?}");
            ids[0].clone()
        }
    }

    /// A long first sync is not cut by the rate budget (it counts only live
    /// events), while a live flood is.
    #[tokio::test]
    async fn the_rate_budget_counts_live_events_only() {
        let b = bench().await;
        let sub = b.router.the_sub();
        let solver = b.solver.public_key();
        let (conv, sign) = channel_keys(&b.buyer.keys, &solver).unwrap();
        let mut events = Vec::new();
        for n in 0..70 {
            events.push(
                wrap_chat_message(&b.buyer.keys, &conv, &sign, &format!("m{n}"))
                    .await
                    .unwrap(),
            );
        }
        // Stored replay (before EOSE on that relay): all taken.
        for event in &events {
            b.router.handle("wss://stored.example", &sub, event).await;
        }
        assert_eq!(b.messages(DISPUTE_A, ChatParty::Buyer).await.len(), 70);

        // Live (after EOSE): the burst, then nothing until tokens refill.
        lock(&b.router.live).insert(("wss://live.example".into(), sub.clone()));
        let mut flood = Vec::new();
        for n in 0..70 {
            flood.push(
                wrap_chat_message(&b.buyer.keys, &conv, &sign, &format!("f{n}"))
                    .await
                    .unwrap(),
            );
        }
        for event in &flood {
            b.router.handle("wss://live.example", &sub, event).await;
        }
        let taken = b.messages(DISPUTE_A, ChatParty::Buyer).await.len() - 70;
        assert_eq!(taken, crate::chat::RATE_BURST as usize);
    }

    /// The chat REQs the router's client holds on the relay.
    async fn chat_reqs(b: &Bench) -> Vec<SubscriptionId> {
        let url = b.relay.url().await;
        let relay = b.router.client.relay(&url).await.unwrap().unwrap();
        let mut ids: Vec<SubscriptionId> = relay
            .subscriptions()
            .await
            .into_keys()
            .filter(|id| id.to_string().starts_with("chat-"))
            .collect();
        ids.sort_by_key(|id| id.to_string());
        ids
    }

    fn dispute_id(n: usize) -> String {
        format!("00000000-0000-4000-8000-{n:012}")
    }

    /// Takes `count` more disputes, each with its own parties; returns them.
    async fn take_more(b: &Bench, count: usize) -> Vec<(String, Keys, Keys)> {
        let mut taken_now = Vec::new();
        for n in 0..count {
            let (buyer, seller) = (Keys::generate(), Keys::generate());
            let id = dispute_id(n);
            b.feed
                .record_take(
                    &b.node.public_key().to_hex(),
                    &id,
                    taken(&b.solver, Some(&buyer), Some(&seller)),
                )
                .await
                .unwrap();
            taken_now.push((id, buyer, seller));
        }
        b.router
            .sync(Some(b.node.public_key().to_hex()), Some(b.solver.clone()))
            .await;
        taken_now
    }

    /// A party of another dispute, writing through the buyer's connection.
    async fn say_as(b: &Bench, party: &Keys, text: &str) {
        let (conv, sign) = channel_keys(party, &b.solver.public_key()).unwrap();
        let event = wrap_chat_message(party, &conv, &sign, text).await.unwrap();
        b.buyer.publish(&event).await;
    }

    /// Twelve disputes held: one REQ on the relay, not twenty-four, and each
    /// message reaches its own conversation.
    #[tokio::test]
    async fn twelve_disputes_share_one_req_and_every_message_finds_its_conversation() {
        let b = bench().await;
        let others = take_more(&b, 11).await;
        assert_eq!(b.router.channel_refs().len(), 24);
        assert_eq!(chat_reqs(&b).await.len(), 1, "one REQ for every channel");

        b.buyer.say(&b.solver.public_key(), "A buyer").await;
        b.seller.say(&b.solver.public_key(), "A seller").await;
        for (id, buyer, seller) in &others {
            say_as(&b, buyer, &format!("{id} buyer")).await;
            say_as(&b, seller, &format!("{id} seller")).await;
        }
        for (id, _, _) in &others {
            b.wait_for(id, ChatParty::Buyer, 1).await;
            b.wait_for(id, ChatParty::Seller, 1).await;
        }
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;
        tokio::time::sleep(Duration::from_millis(300)).await;
        for (id, _, _) in &others {
            for (party, word) in [(ChatParty::Buyer, "buyer"), (ChatParty::Seller, "seller")] {
                let got = b.messages(id, party).await;
                assert_eq!(got.len(), 1, "{id} {word}");
                assert_eq!(got[0].content, format!("{id} {word}"));
                assert_eq!(got[0].sender, party.sender());
            }
        }
        assert_eq!(
            b.messages(DISPUTE_A, ChatParty::Buyer).await[0].content,
            "A buyer"
        );
        assert_eq!(
            b.messages(DISPUTE_A, ChatParty::Seller).await[0].content,
            "A seller"
        );
    }

    /// A take and a close each rebuild the REQ (one REQ still, under a new
    /// id) and lose nothing, not even a message published while it is
    /// rebuilt; a sync that changes no channel leaves the REQ as it is.
    #[tokio::test]
    async fn a_take_or_a_close_rebuilds_the_req_without_losing_messages() {
        let b = bench().await;
        let node = b.node.public_key().to_hex();
        let first = chat_reqs(&b).await;
        assert_eq!(first.len(), 1);

        // Nothing changed: the same REQ.
        b.router
            .sync(Some(node.clone()), Some(b.solver.clone()))
            .await;
        assert_eq!(chat_reqs(&b).await, first);

        // A message on A goes out as dispute B is taken.
        b.buyer.say(&b.solver.public_key(), "during the take").await;
        let others = take_more(&b, 1).await;
        let after_take = chat_reqs(&b).await;
        assert_eq!(after_take.len(), 1);
        assert_ne!(after_take, first, "a new REQ for the new authors");
        let (b_id, b_buyer, _) = &others[0];
        say_as(&b, b_buyer, "B buyer").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
        b.wait_for(b_id, ChatParty::Buyer, 1).await;

        // B closes; A's next message still arrives, on the rebuilt REQ.
        b.feed.retarget(Some(node.clone())).await;
        b.feed
            .ingest(&mostrod_event(
                &b.node,
                b_id,
                "settled",
                crate::rt::unix_now() as u64,
            ))
            .await
            .unwrap();
        b.seller
            .say(&b.solver.public_key(), "during the close")
            .await;
        b.router
            .sync(Some(node.clone()), Some(b.solver.clone()))
            .await;
        let after_close = chat_reqs(&b).await;
        assert_eq!(after_close.len(), 1);
        assert_ne!(after_close, after_take);
        b.buyer.say(&b.solver.public_key(), "after the close").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 2).await;
        b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;
        assert_eq!(b.router.channel_refs().len(), 2);
        assert_eq!(
            b.messages(b_id, ChatParty::Buyer).await.len(),
            1,
            "kept, read only"
        );

        // No channel left: no REQ.
        b.router.sync(Some(node), None).await;
        assert!(chat_reqs(&b).await.is_empty());
    }

    /// Past the author cap, a few REQs, never one per channel.
    #[tokio::test]
    async fn past_the_author_cap_the_channels_split_into_a_few_reqs() {
        let b = bench().await;
        let more = crate::chat::MAX_AUTHORS_PER_REQ / 2;
        take_more(&b, more).await;
        let channels = 2 * (more + 1);
        assert_eq!(b.router.channel_refs().len(), channels);
        let reqs = chat_reqs(&b).await;
        assert_eq!(
            reqs.len(),
            channels.div_ceil(crate::chat::MAX_AUTHORS_PER_REQ)
        );
        assert_eq!(reqs.len(), 2);
    }
}
