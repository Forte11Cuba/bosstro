//! Relay pool — manages connections to Nostr relays. From ../app's
//! `nostr/relay_pool.rs`.
//!
//! Connection state is derived: Online if ≥1 relay is connected, Reconnecting
//! while one is trying, Offline otherwise.
//!
//! Since phase 3 keeps a live subscription (the active node's kind 38386), the
//! pool also runs ../app's liveness probe (`relay_probe.rs`): a `Connected`
//! relay that has gone quiet is asked whether it still answers, and bounced
//! when it does not, so `live_subs` re-issues its subscriptions.
use anyhow::{anyhow, Result};
use nostr_sdk::prelude::*;
// The SDK re-exports its own `RelayStatus`; alias it to keep ours unambiguous.
use nostr_sdk::prelude::RelayStatus as SdkRelayStatus;
use std::collections::HashSet;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::sync::{broadcast, RwLock};

use crate::api::relays::{ConnectionState, RelayInfo, RelaySource, RelayStatus};
use crate::nostr::relay_probe::{self, RelayLiveness};

/// How often the background task polls each relay's SDK status (seconds).
const STATUS_POLL_INTERVAL_SECS: u64 = 2;

/// How often the probe monitor looks for a relay worth asking. Shorter than
/// `relay_probe::PROBE_INTERVAL`, which is what actually spaces the probes:
/// the tick only decides when a relay becomes eligible.
const PROBE_TICK: Duration = Duration::from_secs(30);

/// How often it looks while the pool has never been connected, and for how
/// long: a handshake is over in a few hundred milliseconds, and the app bar
/// should not say "Connecting" for two seconds after it is done.
const STARTUP_POLL_INTERVAL: Duration = Duration::from_millis(100);
const STARTUP_POLL_WINDOW: Duration = Duration::from_secs(10);

/// The host of `url`, for logs: a user-added relay URL may carry a token or
/// userinfo that must not be kept in a log.
pub(crate) fn display_relay(url: &str) -> String {
    let rest = url.split_once("://").map_or(url, |(_, rest)| rest);
    let host = rest.split(['/', '?', '#']).next().unwrap_or(rest);
    host.rsplit('@').next().unwrap_or(host).to_string()
}

/// Shared relay pool state.
pub struct RelayPool {
    client: Arc<Client>,
    relays: Arc<RwLock<Vec<RelayInfo>>>,
    /// Relays the solver removed, whatever their source. A node's kind 10002
    /// list is re-applied on every reconnect and node switch, and the
    /// defaults are the Mostro node's own list, so without this a removed
    /// relay would come straight back.
    blacklist: RwLock<HashSet<String>>,
    conn_tx: broadcast::Sender<ConnectionState>,
    /// The last state actually sent on `conn_tx`, shared by every path that
    /// publishes (`new`, add/remove and the status monitor) so a subscriber
    /// only ever sees real transitions — see `broadcast_if_changed`.
    last_broadcast: Arc<Mutex<Option<ConnectionState>>>,
    relay_tx: broadcast::Sender<RelayInfo>,
    /// When each relay was last heard from and last asked, for the liveness
    /// probe (`nostr::relay_probe`).
    liveness: Arc<RwLock<RelayLiveness>>,
}

impl RelayPool {
    /// Create a new pool with the given relay URLs and start connecting.
    pub async fn new(relay_urls: Vec<String>) -> Result<Arc<Self>> {
        // No signer: every event this pool sends is signed by its caller.
        let client = Arc::new(Client::new());

        let (conn_tx, _) = broadcast::channel(16);
        let (relay_tx, _) = broadcast::channel(64);

        let pool = Arc::new(Self {
            client: client.clone(),
            relays: Arc::new(RwLock::new(Vec::new())),
            blacklist: RwLock::new(HashSet::new()),
            conn_tx,
            last_broadcast: Arc::new(Mutex::new(None)),
            relay_tx,
            liveness: Arc::new(RwLock::new(RelayLiveness::default())),
        });

        for url in relay_urls {
            pool.add_relay_internal(&url, RelaySource::Default, None)
                .await?;
        }

        client.connect().await;

        // Reads `Reconnecting` whatever the sockets are doing: statuses are
        // written by the status monitor alone, which has not run yet.
        pool.broadcast_connection_state().await;
        pool.spawn_status_monitor();
        pool.spawn_liveness_observer();
        pool.spawn_probe_monitor();
        Ok(pool)
    }

    async fn add_relay_internal(
        &self,
        url: &str,
        source: RelaySource,
        announced_by: Option<String>,
    ) -> Result<RelayInfo> {
        self.client
            .add_relay(url)
            .await
            .map_err(|e| anyhow!("add relay failed: {e}"))?;
        // `add_relay` only registers the relay. During construction `new()`
        // connects the whole set afterwards; a relay added to a running pool
        // would otherwise sit in `Initialized` forever. Non-blocking.
        if let Err(e) = self.client.connect_relay(url).await {
            log::warn!("[relay] connect {} not started: {e}", display_relay(url));
        }

        let info = RelayInfo {
            url: url.to_string(),
            is_active: true,
            is_default: matches!(source, RelaySource::Default),
            source,
            is_blacklisted: false,
            status: RelayStatus::Connecting,
            last_connected_at: None,
            last_error: None,
            announced_by,
        };

        {
            // Checked with the write lock held, right before the push: two
            // adds of one URL (a node switch's sync racing the `Online` sync,
            // or the solver's add racing either) both pass any earlier check,
            // and the second would add a duplicate row. The SDK's own
            // `add_relay` above is idempotent, so the loser leaves nothing
            // behind there.
            let mut relays = self.relays.write().await;
            if relays.iter().any(|r| r.url == url) {
                return Err(anyhow!("RelayAlreadyExists"));
            }
            relays.push(info.clone());
        }
        let _ = self.relay_tx.send(info.clone());
        self.broadcast_connection_state().await;
        Ok(info)
    }

    /// Add a relay the user typed, and connect to it.
    ///
    /// An explicit add lifts the relay off the blacklist: the user asking for
    /// it back overrides their earlier removal.
    pub async fn add_relay(&self, url: &str) -> Result<RelayInfo> {
        // A fast refusal; `add_relay_internal` makes the check that counts.
        if self.relays.read().await.iter().any(|r| r.url == url) {
            return Err(anyhow!("RelayAlreadyExists"));
        }
        let info = self
            .add_relay_internal(url, RelaySource::UserAdded, None)
            .await?;
        self.blacklist.write().await.remove(url);
        Ok(info)
    }

    /// Remove a relay and disconnect. The last relay cannot be removed.
    ///
    /// Every removed relay is blacklisted (see `blacklist`), whatever its
    /// source: the defaults are the relays the Mostro node announces in its
    /// kind 10002 list, so a removed default would otherwise come straight
    /// back with the next relay-list sync. Only the solver's own add lifts
    /// it ([`Self::add_relay`]).
    ///
    /// The SDK is asked first, with the list locked: if it refuses, the
    /// error leaves the list, the blacklist and storage as they were.
    pub async fn remove_relay(&self, url: &str) -> Result<RelayInfo> {
        let mut relays = self.relays.write().await;
        let pos = relays
            .iter()
            .position(|r| r.url == url)
            .ok_or_else(|| anyhow!("RelayNotFound"))?;
        // The in-memory list never holds a blacklisted row, so every one
        // counted here is in use.
        if relays.iter().filter(|r| r.is_active).count() <= 1 {
            return Err(anyhow!("LastRelay"));
        }
        self.client
            .remove_relay(url)
            .await
            .map_err(|e| anyhow!("remove relay failed: {e}"))?;
        let mut removed = relays.remove(pos);
        drop(relays);
        removed.status = RelayStatus::Disconnected;
        self.liveness.write().await.forget(url);
        self.blacklist.write().await.insert(url.to_string());

        let _ = self.relay_tx.send(removed.clone());
        self.broadcast_connection_state().await;
        Ok(removed)
    }

    /// Seed the blacklist (e.g. from persisted state) before the first sync.
    pub async fn set_blacklist(&self, urls: impl IntoIterator<Item = String>) {
        *self.blacklist.write().await = urls.into_iter().collect();
    }

    /// Re-apply what a previous session persisted: the source, default flag
    /// and announcing node of relays this pool was constructed with
    /// (construction marks them all `Default`), and the blacklist. Rows for
    /// relays not in the pool are only consulted for the blacklist.
    pub async fn restore_persisted(&self, persisted: &[RelayInfo]) {
        {
            let mut relays = self.relays.write().await;
            for row in persisted.iter().filter(|r| !r.is_blacklisted) {
                if let Some(info) = relays.iter_mut().find(|r| r.url == row.url) {
                    info.source = row.source.clone();
                    info.is_default = row.is_default;
                    info.announced_by = row.announced_by.clone();
                }
            }
        }
        self.set_blacklist(
            persisted
                .iter()
                .filter(|r| r.is_blacklisted)
                .map(|r| r.url.clone()),
        )
        .await;
    }

    /// Relays the solver removed.
    #[cfg(test)]
    pub async fn blacklist(&self) -> Vec<String> {
        let mut urls: Vec<String> = self.blacklist.read().await.iter().cloned().collect();
        urls.sort();
        urls
    }

    /// Apply the relay list `node` (hex) announced. **Additive only**: relays
    /// already configured are left alone (whatever their source), blacklisted
    /// ones are skipped, and nothing is ever disconnected — a node that drops
    /// a relay from its list does not take it away from the solver. Returns
    /// the URLs newly added, in announcement order.
    pub async fn sync_discovered(&self, announced: &[String], node: &str) -> Vec<String> {
        let to_add = {
            let relays = self.relays.read().await;
            let blacklist = self.blacklist.read().await;
            plan_relay_sync(&relays, announced, &blacklist)
        };
        let mut added = Vec::with_capacity(to_add.len());
        for url in to_add {
            match self
                .add_relay_internal(&url, RelaySource::MostroDiscovered, Some(node.to_string()))
                .await
            {
                Ok(_) => added.push(url),
                // Another add of the same URL won the race: nothing to do.
                Err(e) if e.to_string() == "RelayAlreadyExists" => {}
                Err(e) => log::warn!(
                    "[relay] discovered relay {} not added: {e}",
                    display_relay(&url)
                ),
            }
        }
        added
    }

    pub async fn get_relays(&self) -> Vec<RelayInfo> {
        self.relays.read().await.clone()
    }

    pub async fn connection_state(&self) -> ConnectionState {
        derive_connection_state(&self.relays.read().await)
    }

    pub fn subscribe_connection_state(&self) -> broadcast::Receiver<ConnectionState> {
        self.conn_tx.subscribe()
    }

    pub fn subscribe_relay_status(&self) -> broadcast::Receiver<RelayInfo> {
        self.relay_tx.subscribe()
    }

    pub fn client(&self) -> Arc<Client> {
        self.client.clone()
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    async fn broadcast_connection_state(&self) {
        let relays = self.relays.read().await;
        broadcast_if_changed(&self.last_broadcast, &self.conn_tx, &relays);
    }

    /// Spawn a background task that polls each relay's SDK status and
    /// broadcasts changes on `relay_tx` / `conn_tx`.
    ///
    /// `ClientNotification` in nostr-sdk 0.45 carries no relay-level status
    /// transitions, so polling `client.relay(url).status()` is the available
    /// mechanism (as in ../app).
    fn spawn_status_monitor(self: &Arc<Self>) {
        let client = self.client.clone();
        let relays = self.relays.clone();
        let conn_tx = self.conn_tx.clone();
        let last_broadcast = self.last_broadcast.clone();
        let relay_tx = self.relay_tx.clone();

        crate::rt::spawn(async move {
            let started = crate::rt::time::Instant::now();
            let mut has_connected = false;
            loop {
                crate::rt::time::sleep(status_poll_interval(started.elapsed(), has_connected))
                    .await;

                let relay_urls: Vec<String> =
                    relays.read().await.iter().map(|r| r.url.clone()).collect();

                let mut any_changed = false;
                for url in relay_urls {
                    let Ok(Some(sdk_relay)) = client.relay(&url).await else {
                        continue;
                    };
                    let new_status = map_sdk_status(sdk_relay.status());

                    let mut relays_w = relays.write().await;
                    if let Some(info) = relays_w.iter_mut().find(|r| r.url == url) {
                        if info.status != new_status {
                            log::debug!(
                                "[relay] {} {:?}→{new_status:?}",
                                display_relay(&url),
                                info.status
                            );
                            info.status = new_status;
                            if matches!(info.status, RelayStatus::Connected) {
                                info.last_connected_at = Some(crate::rt::unix_now());
                                has_connected = true;
                            }
                            any_changed = true;
                            let _ = relay_tx.send(info.clone());
                        }
                    }
                    drop(relays_w);
                }

                if any_changed {
                    let relays_r = relays.read().await;
                    broadcast_if_changed(&last_broadcast, &conn_tx, &relays_r);
                }
            }
        });
    }

    /// Stamp every relay we hear from, so the probe can skip the ones that
    /// are plainly working (../app).
    ///
    /// One pool-owned receiver rather than instrumenting each consumer: the
    /// signal has to outlive any single subscription being dropped and
    /// rebuilt. `Message` covers every relay message, not only novel events,
    /// which is the broadest "this socket delivers" evidence available.
    fn spawn_liveness_observer(self: &Arc<Self>) {
        let client = self.client.clone();
        let liveness = self.liveness.clone();

        crate::rt::spawn(async move {
            let mut notifications = client.notifications();
            loop {
                match notifications.next().await {
                    Some(ClientNotification::Event { relay_url, .. })
                    | Some(ClientNotification::Message { relay_url, .. }) => {
                        liveness
                            .write()
                            .await
                            .record_traffic(relay_url.as_str(), crate::rt::unix_now());
                    }
                    Some(_) => continue,
                    None => break,
                }
            }
        });
    }

    /// Ask a quiet `Connected` relay whether it is still there, and bounce
    /// its connection when it does not answer (../app).
    ///
    /// The reconnect is the point: it produces the `→Connected` transition
    /// `live_subs` repairs on, and that repair re-REQs — which is what
    /// replays what was missed.
    fn spawn_probe_monitor(self: &Arc<Self>) {
        let client = self.client.clone();
        let relays = self.relays.clone();
        let liveness = self.liveness.clone();

        crate::rt::spawn(async move {
            loop {
                crate::rt::time::sleep(PROBE_TICK).await;

                let relay_urls: Vec<String> =
                    relays.read().await.iter().map(|r| r.url.clone()).collect();

                for url in relay_urls {
                    let Ok(Some(sdk_relay)) = client.relay(&url).await else {
                        continue;
                    };
                    let now = crate::rt::unix_now();
                    let (last_seen, last_probe) = {
                        let liveness_r = liveness.read().await;
                        (liveness_r.last_seen(&url), liveness_r.last_probe(&url))
                    };
                    if !relay_probe::should_probe(sdk_relay.status(), last_seen, last_probe, now) {
                        continue;
                    }
                    // Stamped on the attempt, not the outcome: a relay that
                    // never answers must not be re-asked on the next tick.
                    liveness.write().await.record_probe(&url, now);

                    if relay_probe::probe_once(&sdk_relay).await {
                        continue;
                    }
                    log::warn!(
                        "[relay] liveness probe unanswered relay={} — Connected but not \
                         delivering; reconnecting it",
                        display_relay(&url)
                    );
                    relay_probe::force_reconnect(&client, &url).await;
                }
            }
        });
    }
}

// ── Pure helpers ──────────────────────────────────────────────────────────────

/// How long the status monitor waits before its next look: the start-up
/// cadence until a relay has connected or the start-up window ran out, the
/// steady interval from then on.
fn status_poll_interval(since_start: Duration, has_connected: bool) -> Duration {
    if !has_connected && since_start < STARTUP_POLL_WINDOW {
        STARTUP_POLL_INTERVAL
    } else {
        Duration::from_secs(STATUS_POLL_INTERVAL_SECS)
    }
}

/// Derive the state from `relays` and send it on `tx` only if it differs
/// from what was last sent. Every publisher goes through here, so one shared
/// gate decides what is a transition (../app PR #364). The caller holds the
/// `relays` read guard, so a newer state is never sent before an older one.
fn broadcast_if_changed(
    last: &Mutex<Option<ConnectionState>>,
    tx: &broadcast::Sender<ConnectionState>,
    relays: &[RelayInfo],
) {
    let state = derive_connection_state(relays);
    let next = next_broadcast(&mut last.lock().unwrap_or_else(|e| e.into_inner()), state);
    if let Some(state) = next {
        let _ = tx.send(state);
    }
}

/// The state to broadcast, or `None` when it has not actually changed: a
/// relay that flaps while another stays connected must stay silent.
fn next_broadcast(
    last: &mut Option<ConnectionState>,
    current: ConnectionState,
) -> Option<ConnectionState> {
    if last.as_ref() == Some(&current) {
        return None;
    }
    *last = Some(current.clone());
    Some(current)
}

/// Which of `announced` should be added: not configured yet, not
/// blacklisted, first occurrence only, in announcement order.
fn plan_relay_sync(
    current: &[RelayInfo],
    announced: &[String],
    blacklist: &HashSet<String>,
) -> Vec<String> {
    let mut planned: Vec<String> = Vec::new();
    for url in announced {
        let known = current.iter().any(|r| &r.url == url);
        if known || blacklist.contains(url) || planned.contains(url) {
            continue;
        }
        planned.push(url.clone());
    }
    planned
}

pub(crate) fn derive_connection_state(relays: &[RelayInfo]) -> ConnectionState {
    let any_connected = relays
        .iter()
        .any(|r| matches!(r.status, RelayStatus::Connected));
    let any_connecting = relays
        .iter()
        .any(|r| matches!(r.status, RelayStatus::Connecting));

    if any_connected {
        ConnectionState::Online
    } else if any_connecting {
        ConnectionState::Reconnecting
    } else {
        ConnectionState::Offline
    }
}

/// Map an SDK `RelayStatus` to ours.
fn map_sdk_status(s: SdkRelayStatus) -> RelayStatus {
    match s {
        SdkRelayStatus::Connected => RelayStatus::Connected,
        SdkRelayStatus::Connecting | SdkRelayStatus::Pending => RelayStatus::Connecting,
        SdkRelayStatus::Disconnected
        | SdkRelayStatus::Terminated
        | SdkRelayStatus::Initialized
        | SdkRelayStatus::Sleeping
        | SdkRelayStatus::Shutdown => RelayStatus::Disconnected,
        SdkRelayStatus::Banned => RelayStatus::Error,
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    #[test]
    fn the_monitor_looks_often_until_the_pool_first_connects() {
        assert_eq!(status_poll_interval(Duration::ZERO, false), STARTUP_POLL_INTERVAL);
        assert_eq!(
            status_poll_interval(STARTUP_POLL_WINDOW - Duration::from_millis(1), false),
            STARTUP_POLL_INTERVAL
        );
        assert_eq!(
            status_poll_interval(Duration::from_millis(300), true),
            Duration::from_secs(STATUS_POLL_INTERVAL_SECS)
        );
        assert_eq!(
            status_poll_interval(STARTUP_POLL_WINDOW, false),
            Duration::from_secs(STATUS_POLL_INTERVAL_SECS)
        );
    }

    #[test]
    fn an_unchanged_state_is_not_rebroadcast_and_a_real_one_is() {
        let mut last = None;
        assert_eq!(
            next_broadcast(&mut last, ConnectionState::Online),
            Some(ConnectionState::Online)
        );
        assert_eq!(next_broadcast(&mut last, ConnectionState::Online), None);
        assert_eq!(
            next_broadcast(&mut last, ConnectionState::Offline),
            Some(ConnectionState::Offline)
        );
        assert_eq!(
            next_broadcast(&mut last, ConnectionState::Online),
            Some(ConnectionState::Online)
        );
    }

    fn relay(url: &str, source: RelaySource, status: RelayStatus) -> RelayInfo {
        RelayInfo {
            url: url.to_string(),
            is_active: true,
            is_default: matches!(source, RelaySource::Default),
            source,
            is_blacklisted: false,
            status,
            last_connected_at: None,
            last_error: None,
            announced_by: None,
        }
    }

    fn urls(list: &[&str]) -> Vec<String> {
        list.iter().map(|s| s.to_string()).collect()
    }

    #[test]
    fn the_state_is_online_with_one_connected_relay() {
        let up = relay("wss://a", RelaySource::Default, RelayStatus::Connected);
        let trying = relay("wss://b", RelaySource::Default, RelayStatus::Connecting);
        let down = relay("wss://c", RelaySource::Default, RelayStatus::Disconnected);
        assert_eq!(
            derive_connection_state(&[down.clone(), up]),
            ConnectionState::Online
        );
        assert_eq!(
            derive_connection_state(&[down.clone(), trying]),
            ConnectionState::Reconnecting
        );
        assert_eq!(derive_connection_state(&[down]), ConnectionState::Offline);
        assert_eq!(derive_connection_state(&[]), ConnectionState::Offline);
    }

    #[test]
    fn sync_plan_adds_only_unknown_unblacklisted_relays_in_order() {
        let current = vec![relay(
            "wss://relay.mostro.network",
            RelaySource::Default,
            RelayStatus::Connected,
        )];
        let announced = urls(&[
            "wss://mostro-p2p.tech",
            "wss://relay.mostro.network",
            "wss://nos.lol",
            "wss://nos.lol",
            "wss://banned.example",
        ]);
        let blacklist: HashSet<String> = ["wss://banned.example".to_string()].into_iter().collect();

        let planned = plan_relay_sync(&current, &announced, &blacklist);

        assert_eq!(planned, urls(&["wss://mostro-p2p.tech", "wss://nos.lol"]));
    }

    #[test]
    fn sync_plan_never_removes_relays_the_node_stopped_announcing() {
        let current = vec![
            relay("wss://a", RelaySource::Default, RelayStatus::Connected),
            relay("wss://old", RelaySource::MostroDiscovered, RelayStatus::Connected),
        ];
        assert!(plan_relay_sync(&current, &urls(&["wss://a"]), &HashSet::new()).is_empty());
    }

    #[test]
    fn logs_show_only_the_host() {
        assert_eq!(display_relay("wss://relay.example/path?token=x"), "relay.example");
        assert_eq!(display_relay("wss://user:pw@relay.example"), "relay.example");
        assert_eq!(display_relay("relay.example"), "relay.example");
    }

    /// A node's relay is added with the node's pubkey (D6); removing it
    /// blacklists it until the solver adds it back by hand.
    #[tokio::test]
    async fn a_discovered_relay_names_its_node_and_a_removal_blacklists_it() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
        let added = pool.sync_discovered(&urls(&["ws://127.0.0.1:2"]), "aa").await;
        assert_eq!(added, urls(&["ws://127.0.0.1:2"]));
        let row = pool
            .get_relays()
            .await
            .into_iter()
            .find(|r| r.url == "ws://127.0.0.1:2")
            .unwrap();
        assert_eq!(row.announced_by.as_deref(), Some("aa"));
        assert!(matches!(row.source, RelaySource::MostroDiscovered));

        pool.remove_relay("ws://127.0.0.1:2").await.unwrap();
        assert_eq!(pool.blacklist().await, urls(&["ws://127.0.0.1:2"]));
        assert!(pool
            .sync_discovered(&urls(&["ws://127.0.0.1:2"]), "aa")
            .await
            .is_empty());

        pool.add_relay("ws://127.0.0.1:2").await.unwrap();
        assert!(pool.blacklist().await.is_empty());
    }

    /// Two syncs of one announced URL at once (a node switch's refresh
    /// meeting the pool's `Online` refresh) leave one row, never two. Before
    /// the check moved under the write lock this failed on every run.
    #[tokio::test(flavor = "multi_thread", worker_threads = 4)]
    async fn concurrent_syncs_of_one_url_add_one_row() {
        for round in 0..200 {
            let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
            let url = "ws://127.0.0.1:2".to_string();
            let tasks: Vec<_> = (0..2)
                .map(|_| {
                    let pool = pool.clone();
                    let url = url.clone();
                    tokio::spawn(async move { pool.sync_discovered(&[url], "aa").await })
                })
                .collect();
            let mut added = 0;
            for task in tasks {
                added += task.await.unwrap().len();
            }
            let rows = pool
                .get_relays()
                .await
                .into_iter()
                .filter(|r| r.url == url)
                .count();
            assert_eq!(rows, 1, "round {round}: {rows} rows");
            assert_eq!(added, 1, "round {round}: reported {added} additions");
        }
    }

    /// The solver's add racing a sync of the same URL: one row, and the
    /// loser is told the relay exists.
    #[tokio::test(flavor = "multi_thread", worker_threads = 4)]
    async fn an_add_racing_a_sync_adds_one_row() {
        for round in 0..200 {
            let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
            let url = "ws://127.0.0.1:2";
            let sync = {
                let pool = pool.clone();
                tokio::spawn(async move { pool.sync_discovered(&urls(&[url]), "aa").await })
            };
            let add = {
                let pool = pool.clone();
                tokio::spawn(async move { pool.add_relay(url).await })
            };
            let synced = sync.await.unwrap().len();
            let added = add.await.unwrap();
            let rows = pool.get_relays().await.iter().filter(|r| r.url == url).count();
            assert_eq!(rows, 1, "round {round}");
            match added {
                Ok(_) => assert_eq!(synced, 0, "round {round}"),
                Err(e) => {
                    assert_eq!(e.to_string(), "RelayAlreadyExists", "round {round}");
                    assert_eq!(synced, 1, "round {round}");
                }
            }
        }
    }

    /// The defaults are the Mostro node's own kind 10002 list: a removed one
    /// must not come back with the next sync, only when the solver adds it.
    #[tokio::test]
    async fn a_removed_default_stays_out_until_added_by_hand() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1", "ws://127.0.0.1:2"]))
            .await
            .unwrap();
        pool.remove_relay("ws://127.0.0.1:2").await.unwrap();
        assert_eq!(pool.blacklist().await, urls(&["ws://127.0.0.1:2"]));
        assert!(pool
            .sync_discovered(&urls(&["ws://127.0.0.1:2"]), "aa")
            .await
            .is_empty());
        assert_eq!(pool.get_relays().await.len(), 1);

        pool.add_relay("ws://127.0.0.1:2").await.unwrap();
        assert!(pool.blacklist().await.is_empty());
        assert_eq!(pool.get_relays().await.len(), 2);
    }

    /// Blacklisted rows of any source restore as the blacklist and never
    /// join the pool, so they never count for `LastRelay`.
    #[tokio::test]
    async fn restored_blacklisted_rows_of_any_source_stay_out() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
        let gone = |url: &str, source| RelayInfo {
            is_active: false,
            is_blacklisted: true,
            ..relay(url, source, RelayStatus::Disconnected)
        };
        pool.restore_persisted(&[
            gone("ws://127.0.0.1:2", RelaySource::Default),
            gone("ws://127.0.0.1:3", RelaySource::UserAdded),
            gone("ws://127.0.0.1:4", RelaySource::MostroDiscovered),
        ])
        .await;
        assert_eq!(pool.blacklist().await.len(), 3);
        assert!(pool
            .sync_discovered(&urls(&["ws://127.0.0.1:2", "ws://127.0.0.1:3"]), "aa")
            .await
            .is_empty());
        let err = pool.remove_relay("ws://127.0.0.1:1").await.unwrap_err();
        assert_eq!(err.to_string(), "LastRelay");
    }

    /// A removal the SDK refuses changes nothing: the row stays listed and
    /// nothing is blacklisted. Here the SDK refuses because the row was put
    /// in the list without being registered with it.
    #[tokio::test]
    async fn a_refused_removal_leaves_everything_as_it_was() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
        pool.relays.write().await.push(relay(
            "ws://127.0.0.1:9",
            RelaySource::Default,
            RelayStatus::Connected,
        ));
        let err = pool.remove_relay("ws://127.0.0.1:9").await.unwrap_err();
        assert!(err.to_string().starts_with("remove relay failed"), "{err}");
        assert_eq!(pool.get_relays().await.len(), 2);
        assert!(pool.blacklist().await.is_empty());
    }

    #[tokio::test]
    async fn the_last_relay_cannot_be_removed_and_duplicates_are_refused() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1"])).await.unwrap();
        let err = pool.remove_relay("ws://127.0.0.1:1").await.unwrap_err();
        assert!(err.to_string().contains("LastRelay"));
        let err = pool.remove_relay("ws://127.0.0.1:9").await.unwrap_err();
        assert!(err.to_string().contains("RelayNotFound"));
        let err = pool.add_relay("ws://127.0.0.1:1").await.unwrap_err();
        assert!(err.to_string().contains("RelayAlreadyExists"));
    }

    /// All publishers share one gate (../app PR #364): after a removal sent
    /// `Reconnecting` directly, the monitor's next `Online` still gets out.
    #[tokio::test]
    async fn direct_and_monitor_publishers_share_one_gate() {
        let pool = RelayPool::new(urls(&["ws://127.0.0.1:1", "ws://127.0.0.1:2"]))
            .await
            .unwrap();
        let mut rx = pool.subscribe_connection_state();

        pool.relays.write().await[0].status = RelayStatus::Connected;
        broadcast_if_changed(&pool.last_broadcast, &pool.conn_tx, &pool.relays.read().await);
        assert_eq!(rx.try_recv().unwrap(), ConnectionState::Online);

        pool.remove_relay("ws://127.0.0.1:1").await.unwrap();
        assert_eq!(rx.try_recv().unwrap(), ConnectionState::Reconnecting);

        pool.relays.write().await[0].status = RelayStatus::Connected;
        broadcast_if_changed(&pool.last_broadcast, &pool.conn_tx, &pool.relays.read().await);
        assert_eq!(rx.try_recv().unwrap(), ConnectionState::Online);

        pool.add_relay("ws://127.0.0.1:3").await.unwrap();
        assert!(rx.try_recv().is_err(), "unchanged state must stay silent");
    }
}
