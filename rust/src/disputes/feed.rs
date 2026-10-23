//! The active node's kind 38386 feed: one subscription set per node, every
//! revision merged into storage, every change announced.
//!
//! **What is asked for.** Two long-lived filters, both authored by the node:
//! every `initiated` dispute (no limit, no window — that is the Pending list,
//! and it must be complete), and the node's newest [`RECENT_LIMIT`] disputes
//! of any status, which carries the status changes that take a dispute off
//! Pending. The second is Mostrix's history window (its list fetch:
//! `create_mostro_list_fetch_filter`, 500 events, no `since`). Two filters
//! rather than Mostrix's one, as ../app does for the order book: relays cap
//! how many stored events one REQ replays (relay.mostro.network: 300), so on a
//! busy node a bare limit could miss an old dispute still waiting.
//!
//! **Node switch.** The subscription ids carry the node, so a switch closes
//! the old node's and opens the new node's, and an EOSE or event still in
//! flight for the old REQ is never mistaken for the new one. Revisions are
//! accepted only from the node the feed points at; rows stay keyed by node
//! (D6), so switching back finds the old node's list where it was.
//!
//! **Reconnects.** The filters go through `nostr::live_subs`, which re-issues
//! them on every relay that reconnects; the pool's liveness probe bounces a
//! relay that stopped delivering. Events are read from the raw relay frames,
//! before nostr-sdk's first-seen dedup, so a revision first seen while
//! another node was active is not lost when its node comes back.

use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};

use nostr_sdk::prelude::{
    Client, ClientNotification, Event, Filter, Kind, PublicKey, RelayMessage, SingleLetterTag,
    StreamExt, SubscriptionId,
};
use tokio::sync::broadcast;

use super::event::{parse_dispute_event, KIND_DISPUTE};
use super::{merge, DisputeRecord};
use crate::api::disputes::DisputeUpdate;
use crate::db::Storage;
use crate::nostr::live_subs::LiveSubs;

/// The history window of the any-status filter: Mostrix's
/// `MOSTRO_LIST_FETCH_EVENT_LIMIT`. Relays keep one revision per dispute, so
/// this is the node's newest 500 disputes.
pub const RECENT_LIMIT: usize = 500;

/// How long a node may take to answer before its list counts as synced
/// anyway, so a silent relay set does not leave Pending loading forever.
/// The same bound as the node's other first reads (`api::nodes`).
const SYNC_WAIT: std::time::Duration = std::time::Duration::from_secs(10);

/// Capacity of the update channel. A node's whole history arrives at once on
/// a first sync; a reader that falls behind is told to re-read instead.
const UPDATE_CAPACITY: usize = 256;

/// Every `initiated` dispute of `node`: the Pending list, complete.
pub fn initiated_filter(node: &PublicKey) -> Filter {
    Filter::new()
        .kind(Kind::Custom(KIND_DISPUTE))
        .author(*node)
        .custom_tag(SingleLetterTag::LOWERCASE_S, "initiated")
}

/// The newest [`RECENT_LIMIT`] disputes of `node`, any status.
pub fn recent_filter(node: &PublicKey) -> Filter {
    Filter::new()
        .kind(Kind::Custom(KIND_DISPUTE))
        .author(*node)
        .limit(RECENT_LIMIT)
}

/// The two subscription ids of `node` (hex): `disputes-initiated-<16 hex>`
/// and `disputes-recent-<16 hex>`. Short of NIP-01's 64-character cap.
pub fn subscription_ids(node: &str) -> (SubscriptionId, SubscriptionId) {
    let tag: String = node.chars().take(16).collect();
    (
        SubscriptionId::new(format!("disputes-initiated-{tag}")),
        SubscriptionId::new(format!("disputes-recent-{tag}")),
    )
}

/// Where rows go: the app's storage, or memory when it never opened (the
/// app then runs from memory, as everywhere else).
pub(crate) enum Store {
    Db(&'static crate::db::app_db::AppStorage),
    Memory(Mutex<HashMap<(String, String), DisputeRecord>>),
}

impl Store {
    fn memory() -> Self {
        Store::Memory(Mutex::new(HashMap::new()))
    }

    async fn get(&self, node: &str, id: &str) -> anyhow::Result<Option<DisputeRecord>> {
        match self {
            Store::Db(db) => db.get_dispute(node, id).await,
            Store::Memory(rows) => Ok(lock(rows).get(&(node.into(), id.into())).cloned()),
        }
    }

    async fn save(&self, row: &DisputeRecord) -> anyhow::Result<()> {
        match self {
            Store::Db(db) => db.save_dispute(row).await,
            Store::Memory(rows) => {
                lock(rows).insert(
                    (row.mostro_pubkey.clone(), row.dispute_id.clone()),
                    row.clone(),
                );
                Ok(())
            }
        }
    }

    pub(crate) async fn list(&self, node: &str) -> anyhow::Result<Vec<DisputeRecord>> {
        match self {
            Store::Db(db) => db.list_disputes(node).await,
            Store::Memory(rows) => Ok(lock(rows)
                .values()
                .filter(|row| row.mostro_pubkey == node)
                .cloned()
                .collect()),
        }
    }
}

fn lock<T>(mutex: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    mutex
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}

#[derive(Default)]
struct FeedState {
    /// The node the subscriptions point at (hex).
    node: Option<String>,
    /// Whether that node answered (or [`SYNC_WAIT`] ran out).
    synced: bool,
    /// Bumped on every retarget, so a late timeout or EOSE for a previous
    /// node changes nothing.
    generation: u64,
}

pub(crate) struct Feed {
    client: Arc<Client>,
    store: Store,
    subs: &'static LiveSubs,
    updates: broadcast::Sender<DisputeUpdate>,
    state: Mutex<FeedState>,
    /// Serialises retargets: each closes the previous node's subscriptions
    /// and opens its own.
    retarget_lock: tokio::sync::Mutex<()>,
    /// Serialises read → merge → save, so two relays delivering revisions of
    /// one dispute at once cannot both write.
    ingest_lock: tokio::sync::Mutex<()>,
}

impl Feed {
    pub(crate) fn new(
        client: Arc<Client>,
        store: Store,
        subs: &'static LiveSubs,
        updates: broadcast::Sender<DisputeUpdate>,
    ) -> Arc<Self> {
        Arc::new(Self {
            client,
            store,
            subs,
            updates,
            state: Mutex::new(FeedState::default()),
            retarget_lock: tokio::sync::Mutex::new(()),
            ingest_lock: tokio::sync::Mutex::new(()),
        })
    }

    /// Read the client's notifications for as long as it lives. Taken before
    /// the first subscription, so nothing a relay sends first is missed.
    pub(crate) fn spawn_reader(self: &Arc<Self>) {
        let feed = self.clone();
        let mut notifications = self.client.notifications();
        crate::rt::spawn(async move {
            while let Some(notification) = notifications.next().await {
                let ClientNotification::Message { relay_url, message } = notification else {
                    continue;
                };
                match *message {
                    RelayMessage::Event { event, .. } if is_dispute_kind(&event) => {
                        feed.ingest(&event).await;
                    }
                    RelayMessage::EndOfStoredEvents(id) => feed.on_end_of_stored(&id),
                    RelayMessage::Closed {
                        subscription_id, ..
                    } => {
                        // The SDK forgot it on that relay; get it back
                        // (MostroP2P/app#523). A no-op for ids nobody records.
                        feed.subs
                            .on_closed(&feed.client, relay_url.as_str(), &subscription_id)
                            .await;
                    }
                    _ => {}
                }
            }
        });
    }

    /// Point the feed at `node` (hex), or at nothing: close the previous
    /// node's subscriptions, open `node`'s, and start waiting for its first
    /// answer. Pointing it at the node it already follows changes nothing.
    pub(crate) async fn retarget(self: &Arc<Self>, node: Option<String>) {
        let _guard = self.retarget_lock.lock().await;
        let (previous, generation) = {
            let mut state = lock(&self.state);
            if state.node == node {
                return;
            }
            let previous = std::mem::replace(&mut state.node, node.clone());
            state.synced = false;
            state.generation += 1;
            (previous, state.generation)
        };
        if let Some(previous) = previous {
            let (initiated, recent) = subscription_ids(&previous);
            self.subs.close(&self.client, &initiated).await;
            self.subs.close(&self.client, &recent).await;
        }
        let Some(node) = node else {
            return;
        };
        let Ok(author) = PublicKey::from_hex(&node) else {
            log::warn!("[disputes] active node is not a valid pubkey; not subscribing");
            return;
        };

        // Tells the list to show the new node's stored disputes meanwhile.
        self.send(DisputeUpdate {
            mostro_pubkey: node.clone(),
            dispute: None,
            synced: false,
        });
        let (initiated, recent) = subscription_ids(&node);
        for (id, filter) in [
            (initiated, initiated_filter(&author)),
            (recent, recent_filter(&author)),
        ] {
            if let Err(e) = self.subs.replace(&self.client, id.clone(), filter).await {
                log::warn!("[disputes] subscribe {id} failed: {e}");
            }
        }
        log::info!("[disputes] following the 38386 feed of node {}", &node[..8]);

        let feed = self.clone();
        crate::rt::spawn(async move {
            crate::rt::time::sleep(SYNC_WAIT).await;
            feed.mark_synced(generation);
        });
    }

    /// The node the feed follows.
    pub(crate) fn node(&self) -> Option<String> {
        lock(&self.state).node.clone()
    }

    pub(crate) fn is_synced(&self, node: &str) -> bool {
        let state = lock(&self.state);
        state.node.as_deref() == Some(node) && state.synced
    }

    /// Merge one 38386 revision into storage and announce the change. Refused
    /// silently (logged at debug) when it is not a valid revision of the
    /// followed node's, or not newer than the stored one.
    pub(crate) async fn ingest(&self, event: &Event) -> Option<DisputeRecord> {
        let node = self.node()?;
        let author = PublicKey::from_hex(&node).ok()?;
        let now = crate::rt::unix_now();
        let parsed = match parse_dispute_event(event, &author, now) {
            Ok(parsed) => parsed,
            Err(why) => {
                log::debug!("[disputes] event {} refused: {why:?}", event.id.to_hex());
                return None;
            }
        };

        let row = {
            let _guard = self.ingest_lock.lock().await;
            let existing = match self
                .store
                .get(&parsed.mostro_pubkey, &parsed.dispute_id)
                .await
            {
                Ok(existing) => existing,
                Err(e) => {
                    log::warn!("[disputes] stored dispute not read: {e}");
                    return None;
                }
            };
            let row = merge(existing.as_ref(), &parsed)?;
            if let Err(e) = self.store.save(&row).await {
                log::warn!("[disputes] dispute not stored: {e}");
                return None;
            }
            row
        };
        self.send(DisputeUpdate {
            mostro_pubkey: row.mostro_pubkey.clone(),
            dispute: Some(row.summary(now)),
            synced: self.is_synced(&row.mostro_pubkey),
        });
        Some(row)
    }

    fn on_end_of_stored(&self, id: &SubscriptionId) {
        let generation = {
            let state = lock(&self.state);
            match state.node.as_deref() {
                Some(node) if subscription_ids(node).0 == *id => state.generation,
                _ => return,
            }
        };
        self.mark_synced(generation);
    }

    /// Mark the followed node synced, if it is still the one of `generation`
    /// and was not already, and announce it.
    fn mark_synced(&self, generation: u64) {
        let node = {
            let mut state = lock(&self.state);
            if state.generation != generation || state.synced {
                return;
            }
            state.synced = true;
            state.node.clone()
        };
        if let Some(node) = node {
            self.send(DisputeUpdate {
                mostro_pubkey: node,
                dispute: None,
                synced: true,
            });
        }
    }

    fn send(&self, update: DisputeUpdate) {
        // No receiver (Dart not listening yet) is not an error.
        let _ = self.updates.send(update);
    }
}

fn is_dispute_kind(event: &Event) -> bool {
    event.kind == Kind::Custom(KIND_DISPUTE)
}

// ── The process-wide feed ─────────────────────────────────────────────────────

static FEED: OnceLock<Arc<Feed>> = OnceLock::new();

/// The update channel, there before the feed starts so Dart can subscribe at
/// any time.
fn updates() -> &'static broadcast::Sender<DisputeUpdate> {
    static UPDATES: OnceLock<broadcast::Sender<DisputeUpdate>> = OnceLock::new();
    UPDATES.get_or_init(|| broadcast::channel(UPDATE_CAPACITY).0)
}

pub(crate) fn subscribe_updates() -> broadcast::Receiver<DisputeUpdate> {
    updates().subscribe()
}

/// Start the feed on the relay pool's client and point it at the active
/// node. Called once the pool exists (`api::relays::initialize_relays`);
/// later calls only re-point it.
pub(crate) async fn start(client: Arc<Client>) {
    let feed = FEED.get_or_init(|| {
        let store = match crate::db::app_db::db() {
            Some(db) => Store::Db(db),
            None => Store::memory(),
        };
        let feed = Feed::new(
            client,
            store,
            crate::nostr::live_subs::live_subs(),
            updates().clone(),
        );
        feed.spawn_reader();
        feed
    });
    feed.retarget(crate::config::active_mostro_pubkey()).await;
}

/// Re-point the feed at the active node after a selection. A no-op before
/// the pool started.
pub(crate) async fn follow_active_node() {
    if let Some(feed) = FEED.get() {
        feed.retarget(crate::config::active_mostro_pubkey()).await;
    }
}

/// Whether `node`'s disputes have been answered for. Without a feed (no
/// relay pool) there is nothing to wait for.
pub(crate) fn is_synced(node: &str) -> bool {
    FEED.get().is_none_or(|feed| feed.is_synced(node))
}

/// `node`'s rows from the feed's memory store, when storage never opened.
pub(crate) async fn memory_rows(node: &str) -> Vec<DisputeRecord> {
    match FEED.get().map(|feed| &feed.store) {
        Some(store @ Store::Memory(_)) => store.list(node).await.unwrap_or_default(),
        _ => Vec::new(),
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::api::disputes::DisputeStatus;
    use crate::disputes::event::tests::{mostrod_event, DISPUTE_ID};
    use nostr_sdk::local_relay::MockRelay;
    use nostr_sdk::prelude::Keys;
    use std::time::Duration;

    const OTHER_ID: &str = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";

    async fn connected_client(relay: &MockRelay) -> Arc<Client> {
        let url = relay.url().await;
        let client = Arc::new(Client::new());
        client.add_relay(&url).await.unwrap();
        client
            .try_connect_relay(&url, Duration::from_secs(3))
            .await
            .unwrap();
        client
    }

    async fn sqlite_store() -> Store {
        let storage = crate::db::sqlite::tests::store().await;
        Store::Db(Box::leak(Box::new(storage)))
    }

    fn feed_on(
        client: Arc<Client>,
        store: Store,
    ) -> (Arc<Feed>, broadcast::Receiver<DisputeUpdate>) {
        let (tx, rx) = broadcast::channel(UPDATE_CAPACITY);
        let subs: &'static LiveSubs = Box::leak(Box::default());
        let feed = Feed::new(client, store, subs, tx);
        feed.spawn_reader();
        (feed, rx)
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

    async fn status_of(feed: &Feed, node: &Keys, id: &str) -> Option<DisputeStatus> {
        feed.store
            .get(&node.public_key().to_hex(), id)
            .await
            .unwrap()
            .map(|row| row.status)
    }

    #[test]
    fn the_filters_are_author_pinned_and_the_recent_one_is_mostrix_window() {
        let node = Keys::generate().public_key();
        let pending = initiated_filter(&node);
        assert_eq!(pending.authors, Some([node].into_iter().collect()));
        assert_eq!(
            pending.kinds,
            Some([Kind::Custom(KIND_DISPUTE)].into_iter().collect())
        );
        let s: Vec<String> = pending
            .generic_tags
            .get(&SingleLetterTag::LOWERCASE_S)
            .expect("an s tag")
            .iter()
            .cloned()
            .collect();
        assert_eq!(s, vec!["initiated".to_string()]);
        assert_eq!(pending.limit, None, "a limit could truncate Pending");
        assert_eq!(pending.since, None);

        let recent = recent_filter(&node);
        assert_eq!(recent.authors, Some([node].into_iter().collect()));
        assert_eq!(recent.limit, Some(500));
        assert_eq!(recent.since, None, "no time window, as Mostrix");
        assert!(recent.generic_tags.is_empty());
    }

    #[test]
    fn subscription_ids_name_the_node_and_fit_nip01() {
        let a = "00000235a3e904cfe1213a8a54d6f1ec1bef7cc6bfaabd6193e82931ccf1366a";
        let b = "0000cc02101ec29eea9ce623258752b9d7da66c27845ed26846dd0b0fc736b40";
        let (ai, ar) = subscription_ids(a);
        let (bi, _) = subscription_ids(b);
        assert_ne!(ai, ar);
        assert_ne!(ai, bi, "two nodes never share an id");
        assert!(ai.to_string().len() <= 64 && ar.to_string().len() <= 64);
    }

    /// The whole path against a relay: the node's stored disputes arrive,
    /// a forgery in its name and another node's disputes do not, the first
    /// answer marks the node synced, and a status change reaches the row.
    #[tokio::test]
    async fn follows_the_node_and_reconciles_status_changes() {
        let relay = MockRelay::run().await.unwrap();
        let client = connected_client(&relay).await;
        let node = Keys::generate();
        let stranger = Keys::generate();
        client
            .send_event(&mostrod_event(
                &node,
                DISPUTE_ID,
                "initiated",
                1_700_000_100,
            ))
            .await
            .unwrap();
        client
            .send_event(&mostrod_event(
                &stranger,
                OTHER_ID,
                "initiated",
                1_700_000_100,
            ))
            .await
            .unwrap();
        let (feed, mut rx) = feed_on(client.clone(), sqlite_store().await);

        feed.retarget(Some(node.public_key().to_hex())).await;

        eventually("the node's dispute stored", || async {
            status_of(&feed, &node, DISPUTE_ID).await == Some(DisputeStatus::Initiated)
        })
        .await;
        eventually("synced on EOSE", || async {
            feed.is_synced(&node.public_key().to_hex())
        })
        .await;
        assert_eq!(status_of(&feed, &stranger, OTHER_ID).await, None);
        assert_eq!(status_of(&feed, &node, OTHER_ID).await, None);

        // The node takes it (a solver did), then the parties settle it.
        client
            .send_event(&mostrod_event(
                &node,
                DISPUTE_ID,
                "in-progress",
                1_700_000_200,
            ))
            .await
            .unwrap();
        eventually("in-progress", || async {
            status_of(&feed, &node, DISPUTE_ID).await == Some(DisputeStatus::InProgress)
        })
        .await;
        client
            .send_event(&mostrod_event(&node, DISPUTE_ID, "released", 1_700_000_300))
            .await
            .unwrap();
        eventually("closed", || async {
            status_of(&feed, &node, DISPUTE_ID).await == Some(DisputeStatus::Released)
        })
        .await;

        // The updates said so, in order, for this node only.
        let mut seen = Vec::new();
        while let Ok(update) = rx.try_recv() {
            assert_eq!(update.mostro_pubkey, node.public_key().to_hex());
            if let Some(d) = update.dispute {
                seen.push((d.status, d.is_pending));
            }
        }
        assert_eq!(
            seen,
            vec![
                (DisputeStatus::Initiated, true),
                (DisputeStatus::InProgress, false),
                (DisputeStatus::Released, false),
            ]
        );
    }

    /// D6: a switch follows the new node only; the old node's rows stay as
    /// they were, and its later revisions are not taken while it is not the
    /// active one.
    #[tokio::test]
    async fn a_node_switch_follows_the_new_node_and_never_mixes_them() {
        let relay = MockRelay::run().await.unwrap();
        let client = connected_client(&relay).await;
        let (a, b) = (Keys::generate(), Keys::generate());
        client
            .send_event(&mostrod_event(&a, DISPUTE_ID, "initiated", 1_700_000_100))
            .await
            .unwrap();
        client
            .send_event(&mostrod_event(&b, OTHER_ID, "initiated", 1_700_000_100))
            .await
            .unwrap();
        let (feed, _rx) = feed_on(client.clone(), sqlite_store().await);

        feed.retarget(Some(a.public_key().to_hex())).await;
        eventually("A's dispute", || async {
            status_of(&feed, &a, DISPUTE_ID).await.is_some()
        })
        .await;

        feed.retarget(Some(b.public_key().to_hex())).await;
        assert!(
            !feed.is_synced(&b.public_key().to_hex()),
            "a new node starts unsynced"
        );
        eventually("B's dispute", || async {
            status_of(&feed, &b, OTHER_ID).await.is_some()
        })
        .await;

        // A's subscriptions are closed: its next revision is not followed.
        client
            .send_event(&mostrod_event(&a, DISPUTE_ID, "in-progress", 1_700_000_200))
            .await
            .unwrap();
        tokio::time::sleep(Duration::from_millis(300)).await;
        assert_eq!(
            status_of(&feed, &a, DISPUTE_ID).await,
            Some(DisputeStatus::Initiated)
        );
        assert_eq!(status_of(&feed, &a, OTHER_ID).await, None);
        assert_eq!(status_of(&feed, &b, DISPUTE_ID).await, None);
        let (a_initiated, a_recent) = subscription_ids(&a.public_key().to_hex());
        assert!(client.subscription(&a_initiated).await.is_empty());
        assert!(client.subscription(&a_recent).await.is_empty());

        // Back to A: its missed revision arrives, although the SDK saw that
        // event once already (the feed reads frames before its dedup).
        feed.retarget(Some(a.public_key().to_hex())).await;
        eventually("A's revision on return", || async {
            status_of(&feed, &a, DISPUTE_ID).await == Some(DisputeStatus::InProgress)
        })
        .await;
    }

    /// An old revision a relay replays after a newer one never undoes it.
    #[tokio::test]
    async fn an_older_revision_never_undoes_a_newer_one() {
        let client = Arc::new(Client::new());
        let (feed, mut rx) = feed_on(client, Store::memory());
        let node = Keys::generate();
        feed.retarget(Some(node.public_key().to_hex())).await;
        let _ = rx.try_recv();

        let newer = mostrod_event(&node, DISPUTE_ID, "settled", 1_700_000_300);
        let older = mostrod_event(&node, DISPUTE_ID, "initiated", 1_700_000_100);
        assert!(feed.ingest(&newer).await.is_some());
        assert!(feed.ingest(&older).await.is_none());
        assert!(feed.ingest(&newer).await.is_none(), "a copy is no change");
        assert_eq!(
            status_of(&feed, &node, DISPUTE_ID).await,
            Some(DisputeStatus::Settled)
        );
        let changes = std::iter::from_fn(|| rx.try_recv().ok())
            .filter(|u| u.dispute.is_some())
            .count();
        assert_eq!(changes, 1);
    }

    #[tokio::test]
    async fn without_a_node_nothing_is_taken() {
        let (feed, _rx) = feed_on(Arc::new(Client::new()), Store::memory());
        let node = Keys::generate();
        let event = mostrod_event(&node, DISPUTE_ID, "initiated", 1);
        assert!(feed.ingest(&event).await.is_none());
    }
}
