//! The chat router: follows the channels of the active node and loaded key,
//! receives and stores their messages, and sends this key's.
//!
//! **Channels.** One per party of every dispute this key holds on the active
//! node (`in-progress`, taken by it, not expired) whose trade key the take
//! named. They are worked out again whenever the node, the key or a dispute
//! changes (a take, a recovery, a close, a reopen: every one comes through
//! the 38386 feed's updates), and each is one long-lived subscription,
//! `authors = [pub(K_sign)]`, through `nostr::live_subs`, so a reconnect
//! re-issues it. A closed dispute's channels close; its messages stay, read
//! only.
//!
//! **Since.** Each subscription starts at its cursor, the newest
//! `min(created_at, received_at)` of the channel's stored messages, minus an
//! overlap; the first time, a little before the dispute was opened (or
//! taken). The cursor never passes the local clock: a message dated in the
//! future cannot silence the conversation. At most [`BACKLOG_LIMIT`] stored
//! events are replayed.
//!
//! **Checks, cheapest first** (the spec's order): the outer author, then the
//! outer id already handled ([`SeenOuter`]), then the conversation's rate
//! budget, then `mostro_core::chat::unwrap_chat_message` (the `p` tag, the
//! future bound, the size, both signatures, the allowed inner signers, the
//! inner kind, the inner/outer time skew), then the durable inner id (the
//! row's key). The budget counts only what a relay sends live, after its
//! stored events: a first sync of a long conversation is bounded by
//! [`BACKLOG_LIMIT`] instead, and nothing of it is dropped.
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

use super::{
    allowed_signers, channel_keys, sender_of, subscription_since, ChannelRef, ChatRecord,
    RateLimits, SeenOuter, BACKLOG_LIMIT, MAX_MESSAGE_BYTES,
};
use crate::api::chat::{
    ChatChannelState, ChatDelivery, ChatError, ChatMessageView, ChatParty, ChatSender,
    ChatThread, ChatUpdate,
};
use crate::api::disputes::DisputeStatus;
use crate::db::Storage;
use crate::disputes::feed::Feed;
use crate::disputes::DisputeRecord;
use crate::nostr::live_subs::LiveSubs;

/// Capacity of the update channel toward Dart.
const UPDATE_CAPACITY: usize = 256;

fn lock<T>(mutex: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    mutex
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}

// ── Where messages go ─────────────────────────────────────────────────────────

/// The app's storage, or memory when it never opened.
pub(crate) enum ChatStore {
    Db(&'static crate::db::app_db::AppStorage),
    Memory(Mutex<HashMap<ChannelRef, Vec<ChatRecord>>>),
}

impl ChatStore {
    pub(crate) fn memory() -> Self {
        ChatStore::Memory(Mutex::new(HashMap::new()))
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
                let mut map = lock(m);
                let rows = map.entry(record.channel.clone()).or_default();
                if rows.iter().any(|r| r.message_id == record.message_id) {
                    return Ok(false);
                }
                rows.push(record.clone());
                Ok(true)
            }
        }
    }

    async fn get(&self, channel: &ChannelRef, id: &str) -> anyhow::Result<Option<ChatRecord>> {
        match self {
            ChatStore::Db(db) => db.get_chat_message(channel, id).await,
            ChatStore::Memory(m) => Ok(lock(m)
                .get(channel)
                .and_then(|rows| rows.iter().find(|r| r.message_id == id).cloned())),
        }
    }

    pub(crate) async fn list(&self, channel: &ChannelRef) -> anyhow::Result<Vec<ChatRecord>> {
        match self {
            ChatStore::Db(db) => db.list_chat_messages(channel).await,
            ChatStore::Memory(m) => Ok(lock(m).get(channel).cloned().unwrap_or_default()),
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
                if let Some(row) = lock(m)
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
                if let Some(rows) = lock(m).get_mut(channel) {
                    rows.retain(|r| r.message_id != id);
                }
                Ok(())
            }
        }
    }

    async fn cursor(&self, channel: &ChannelRef) -> anyhow::Result<Option<i64>> {
        match self {
            ChatStore::Db(db) => db.chat_cursor(channel).await,
            ChatStore::Memory(_) => Ok(self.list(channel).await?.iter().map(ChatRecord::cursor).max()),
        }
    }
}

// ── Channels ──────────────────────────────────────────────────────────────────

/// One followed conversation, with its keys (in memory only).
pub(crate) struct Channel {
    pub(crate) channel: ChannelRef,
    pub(crate) sub: SubscriptionId,
    party_key: PublicKey,
    conv: Keys,
    sign: Keys,
}

/// The subscription id of a channel: `chat-<16 hex of pub(K_sign)>-<8 of the
/// dispute id>`, within NIP-01's 64 characters. `pub(K_sign)` is already in
/// the filter, so the id tells a relay nothing new.
pub(crate) fn subscription_id(sign: &PublicKey, dispute_id: &str) -> SubscriptionId {
    let sign: String = sign.to_hex().chars().take(16).collect();
    let dispute: String = dispute_id.chars().take(8).collect();
    SubscriptionId::new(format!("chat-{sign}-{dispute}"))
}

/// Every chat event of a channel, from `since` on, at most [`BACKLOG_LIMIT`]
/// stored ones.
pub(crate) fn channel_filter(sign: &PublicKey, since: i64) -> Filter {
    Filter::new()
        .kind(Kind::PrivateDirectMessage)
        .author(*sign)
        .since(Timestamp::from_secs(since.max(0) as u64))
        .limit(BACKLOG_LIMIT)
}

/// The party's trade key the take named, if it parses.
fn party_key(row: &DisputeRecord, party: ChatParty) -> Option<PublicKey> {
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

/// Who the router works for: the active node (hex) and the loaded key.
#[derive(Clone)]
struct Target {
    node: String,
    keys: Keys,
}

pub(crate) struct Router {
    client: Arc<Client>,
    subs: &'static LiveSubs,
    feed: Arc<Feed>,
    pub(crate) store: ChatStore,
    updates: broadcast::Sender<ChatUpdate>,
    target: Mutex<Option<Target>>,
    channels: Mutex<HashMap<ChannelRef, Arc<Channel>>>,
    /// The ids of [`Self::channels`]' subscriptions, for the reader.
    sub_ids: Mutex<HashSet<SubscriptionId>>,
    seen: Mutex<SeenOuter>,
    limits: Mutex<RateLimits<SubscriptionId>>,
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
            sub_ids: Mutex::new(HashSet::new()),
            seen: Mutex::new(SeenOuter::default()),
            limits: Mutex::new(RateLimits::default()),
            live: Mutex::new(HashSet::new()),
            in_flight: Mutex::new(HashSet::new()),
            started: crate::rt::time::Instant::now(),
            sync_lock: tokio::sync::Mutex::new(()),
            ingest_lock: tokio::sync::Mutex::new(()),
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

    fn channel_of_sub(&self, sub: &SubscriptionId) -> Option<Arc<Channel>> {
        lock(&self.channels)
            .values()
            .find(|c| &c.sub == sub)
            .cloned()
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

        // Close what is no longer wanted (or wanted with another party key).
        let closing: Vec<Arc<Channel>> = {
            let mut channels = lock(&self.channels);
            let gone: Vec<ChannelRef> = channels
                .iter()
                .filter(|(r, c)| wanted.get(*r).is_none_or(|w| w.party_key != c.party_key))
                .map(|(r, _)| r.clone())
                .collect();
            gone.iter().filter_map(|r| channels.remove(r)).collect()
        };
        for channel in closing {
            lock(&self.sub_ids).remove(&channel.sub);
            lock(&self.limits).remove(&channel.sub);
            lock(&self.live).retain(|(_, sub)| sub != &channel.sub);
            self.subs.close(&self.client, &channel.sub).await;
        }

        // Open the new ones.
        let Some(target) = target else {
            return;
        };
        let opening: Vec<(ChannelRef, Wanted)> = {
            let channels = lock(&self.channels);
            wanted
                .into_iter()
                .filter(|(r, _)| !channels.contains_key(r))
                .collect()
        };
        for (channel, wanted) in opening {
            let Wanted {
                party_key,
                opened_at,
                taken_at,
            } = wanted;
            let (conv, sign) = match channel_keys(&target.keys, &party_key) {
                Ok(keys) => keys,
                Err(e) => {
                    log::warn!("[chat] channel not opened: {e}");
                    continue;
                }
            };
            let cursor = match self.store.cursor(&channel).await {
                Ok(cursor) => cursor,
                Err(e) => {
                    log::warn!("[chat] cursor not read: {e}");
                    None
                }
            };
            let since = subscription_since(cursor, opened_at, taken_at, crate::rt::unix_now());
            let sub = subscription_id(&sign.public_key(), &channel.dispute_id);
            let filter = channel_filter(&sign.public_key(), since);
            let followed = Arc::new(Channel {
                channel: channel.clone(),
                sub: sub.clone(),
                party_key,
                conv,
                sign,
            });
            // Known before the REQ, so its first events are not passed over.
            lock(&self.channels).insert(channel, followed);
            lock(&self.sub_ids).insert(sub.clone());
            if let Err(e) = self.subs.replace(&self.client, sub.clone(), filter).await {
                log::warn!("[chat] subscribe {sub} failed: {e}");
            }
        }
    }

    /// One kind 14 of a channel's subscription, checked cheapest first.
    pub(crate) async fn handle(&self, relay: &str, sub: &SubscriptionId, event: &Event) {
        let Some(channel) = self.channel_of_sub(sub) else {
            return;
        };
        if event.pubkey != channel.sign.public_key() {
            return;
        }
        if lock(&self.seen).contains(&event.id) {
            return;
        }
        let is_live = lock(&self.live).contains(&(relay.to_string(), sub.clone()));
        if is_live {
            let now = self.started.elapsed().as_secs_f64();
            if !lock(&self.limits).allow(sub, now) {
                // Not marked: a copy from another relay may still pass.
                log::debug!("[chat] {sub}: over the rate budget, event dropped");
                return;
            }
        }
        let solver = PublicKey::parse(&channel.channel.solver_pubkey).ok();
        let Some(solver) = solver else {
            return;
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
                lock(&self.seen).insert(event.id);
                return;
            }
        };
        let Some(sender) = sender_of(
            &message.sender,
            &solver,
            channel.channel.party,
            &channel.party_key,
        ) else {
            lock(&self.seen).insert(event.id);
            return;
        };
        let record = ChatRecord {
            channel: channel.channel.clone(),
            message_id: message.inner_event_id.to_hex(),
            sender,
            content: message.content,
            created_at: message.created_at.as_secs() as i64,
            received_at: crate::rt::unix_now(),
            delivery: ChatDelivery::Sent,
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
                                .set_delivery(&record.channel, &record.message_id, ChatDelivery::Sent)
                                .await
                            {
                                log::warn!("[chat] delivery not stored: {e}");
                                return;
                            }
                            true
                        }
                        _ => false,
                    }
                }
                Ok(false) => false,
                Err(e) => {
                    // Not marked: the next copy tries again.
                    log::warn!("[chat] message not stored: {e}");
                    return;
                }
            }
        };
        lock(&self.seen).insert(event.id);
        if changed {
            self.announce(&record.channel);
        }
    }

    fn announce(&self, channel: &ChannelRef) {
        let _ = self.updates.send(ChatUpdate {
            mostro_pubkey: channel.mostro_pubkey.clone(),
            dispute_id: Some(channel.dispute_id.clone()),
            party: Some(channel.party),
        });
    }

    fn target(&self) -> Option<Target> {
        lock(&self.target).clone()
    }

    /// The conversation `party` of `dispute_id`, when this key may write to
    /// it now; the reason otherwise.
    async fn writable(
        &self,
        dispute_id: &str,
        party: ChatParty,
    ) -> Result<(Target, ChannelRef, PublicKey), ChatError> {
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
        if row.status.is_terminal() {
            return Err(ChatError::Closed);
        }
        if row.status != DisputeStatus::InProgress {
            return Err(ChatError::UnknownDispute);
        }
        let key = party_key(&row, party).ok_or(ChatError::NoPartyKey)?;
        let channel = ChannelRef {
            mostro_pubkey: target.node.clone(),
            dispute_id: dispute_id.to_string(),
            party,
            solver_pubkey: solver,
        };
        Ok((target, channel, key))
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
        let (target, channel, party_key) = self.writable(dispute_id, party).await?;
        let (conv, sign) = channel_keys(&target.keys, &party_key).map_err(|e| {
            log::warn!("[chat] message not built: {e}");
            ChatError::NoPartyKey
        })?;
        let event = wrap_chat_message(&target.keys, &conv, &sign, text)
            .await
            .map_err(|e| {
                log::warn!("[chat] message not built: {e}");
                ChatError::NoPartyKey
            })?;
        // The inner id, read back the way the party will read it.
        let solver = target.keys.public_key();
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

    /// The conversation as the chat shows it: oldest first, ties by id.
    pub(crate) async fn messages(&self, channel: &ChannelRef) -> anyhow::Result<Vec<ChatMessageView>> {
        let in_flight = lock(&self.in_flight).clone();
        Ok(sorted_views(
            &self.store.list(channel).await?,
            |id| in_flight.contains(id),
        ))
    }
}

/// `records` oldest first (ties by id), as views.
fn sorted_views(records: &[ChatRecord], in_flight: impl Fn(&str) -> bool) -> Vec<ChatMessageView> {
    let mut views: Vec<ChatMessageView> = records
        .iter()
        .map(|r| r.view(in_flight(&r.message_id)))
        .collect();
    views.sort_by(|a, b| a.created_at.cmp(&b.created_at).then_with(|| a.id.cmp(&b.id)));
    views
}

// ── The process-wide router ───────────────────────────────────────────────────

static ROUTER: OnceLock<Arc<Router>> = OnceLock::new();

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
async fn node_and_keys() -> Result<(String, Keys), ChatError> {
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
pub(crate) async fn thread(dispute_id: &str, party: ChatParty) -> anyhow::Result<Option<ChatThread>> {
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
mod tests {
    use super::*;
    use crate::disputes::event::tests::mostrod_event;
    use crate::disputes::feed::Store;
    use crate::disputes::TakenDispute;
    use mostro_core::chat::SharedKey;
    use nostr::nips::nip44;
    use nostr_sdk::local_relay::MockRelay;
    use nostr_sdk::prelude::*;
    use std::time::Duration;

    const DISPUTE_A: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
    const DISPUTE_B: &str = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";

    async fn connected(relay: &MockRelay) -> Arc<Client> {
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
    async fn eventually<F, Fut>(what: &str, mut check: F)
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
    struct Party {
        keys: Keys,
        client: Arc<Client>,
    }

    impl Party {
        /// Write `text` to the solver, as a party's client does.
        async fn say(&self, solver: &PublicKey, text: &str) -> Event {
            let (conv, sign) = channel_keys(&self.keys, solver).unwrap();
            let event = wrap_chat_message(&self.keys, &conv, &sign, text)
                .await
                .unwrap();
            self.publish(&event).await;
            event
        }

        async fn publish(&self, event: &Event) {
            let output = self.client.send_event(event).await.unwrap();
            assert!(!output.success.is_empty(), "the relay refused it");
        }

        /// What the party reads from the solver's channel, as (sender, text).
        async fn read(&self, solver: &PublicKey) -> Vec<(PublicKey, String)> {
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

    struct Bench {
        relay: MockRelay,
        node: Keys,
        solver: Keys,
        buyer: Party,
        seller: Party,
        feed: Arc<Feed>,
        router: Arc<Router>,
        updates: broadcast::Receiver<ChatUpdate>,
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
        }
    }

    async fn bench_with(feed_store: Store, chat_store: ChatStore) -> Bench {
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

    async fn bench() -> Bench {
        bench_with(Store::memory(), ChatStore::memory()).await
    }

    impl Bench {
        fn channel(&self, dispute: &str, party: ChatParty) -> ChannelRef {
            ChannelRef {
                mostro_pubkey: self.node.public_key().to_hex(),
                dispute_id: dispute.into(),
                party,
                solver_pubkey: self.solver.public_key().to_hex(),
            }
        }

        async fn messages(&self, dispute: &str, party: ChatParty) -> Vec<ChatMessageView> {
            self.router
                .messages(&self.channel(dispute, party))
                .await
                .unwrap()
        }

        async fn wait_for(&self, dispute: &str, party: ChatParty, count: usize) {
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
            .send(DISPUTE_A, ChatParty::Buyer, "  Send me the receipt, please.\n")
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
            .handle("wss://another.relay", &b.router.channel_refs_sub(DISPUTE_A, ChatParty::Buyer), &event)
            .await;
        // Re-wrap the same inner event in a fresh envelope.
        let (conv, sign) = channel_keys(&b.buyer.keys, &solver).unwrap();
        let inner_json = nip44::decrypt(conv.secret_key(), &conv.public_key(), &event.content)
            .unwrap();
        let content =
            nip44::encrypt(conv.secret_key(), &conv.public_key(), inner_json, nip44::Version::V2)
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
        let content =
            nip44::encrypt(conv.secret_key(), &conv.public_key(), inner.as_json(), nip44::Version::V2)
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
        b.router.sync(Some(node.clone()), Some(b.solver.clone())).await;
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
        assert_eq!(thread_state(&row, ChatParty::Buyer), ChatChannelState::Closed);

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
        assert_eq!(send(" \n\t ", DISPUTE_A).await.unwrap_err(), ChatError::Empty);
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
                taken(&Keys::generate(), Some(&Keys::generate()), Some(&Keys::generate())),
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
        /// The subscription id of one followed channel (tests).
        fn channel_refs_sub(&self, dispute: &str, party: ChatParty) -> SubscriptionId {
            lock(&self.channels)
                .iter()
                .find(|(r, _)| r.dispute_id == dispute && r.party == party)
                .map(|(_, c)| c.sub.clone())
                .unwrap()
        }
    }

    /// A long first sync is not cut by the rate budget (it counts only live
    /// events), while a live flood is.
    #[tokio::test]
    async fn the_rate_budget_counts_live_events_only() {
        let b = bench().await;
        let sub = b.router.channel_refs_sub(DISPUTE_A, ChatParty::Buyer);
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
}
