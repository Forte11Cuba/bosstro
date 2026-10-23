//! The relay pool, across the bridge. A thin facade over
//! [`crate::nostr::relay_pool::RelayPool`], from ../app's `api/nostr.rs`.
//!
//! One relay list for the device (not one per node): the defaults, the
//! relays the solver adds, and those the active node announces in its kind
//! 10002 list. An announced relay keeps the pubkey of the node that announced
//! it (`announced_by`, D6). Every change is persisted best effort: a failed
//! write is logged and the pool keeps working from memory.
//!
//! Errors are stable markers (`NotInitialized`, `InvalidRelayUrl`,
//! `RelayAlreadyExists`, `RelayNotFound`, `LastRelay`); Dart maps them to
//! its own copy.
use anyhow::Result;
use std::sync::Arc;
use tokio::sync::OnceCell;

use crate::db::Storage;
use crate::nostr::relay_pool::{display_relay, RelayPool};

/// Where a relay in the list came from.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum RelaySource {
    /// Seeded on first launch (`config::DEFAULT_RELAYS`).
    Default,
    /// Announced by a node in its kind 10002 list.
    MostroDiscovered,
    /// Added by the solver.
    UserAdded,
}

/// One relay's connection, as the pool last saw it.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum RelayStatus {
    Connected,
    Disconnected,
    Connecting,
    Error,
}

/// The pool as a whole: Online with one relay connected, Reconnecting while
/// one is trying, Offline otherwise.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum ConnectionState {
    Online,
    Offline,
    Reconnecting,
}

/// A relay of the list. Same shape as ../app's `RelayInfo`, plus
/// `announced_by`.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct RelayInfo {
    pub url: String,
    pub is_active: bool,
    pub is_default: bool,
    pub source: RelaySource,
    /// A node-announced relay the solver removed: kept as a row so the node's
    /// list does not bring it back, never connected.
    pub is_blacklisted: bool,
    pub status: RelayStatus,
    pub last_connected_at: Option<i64>,
    pub last_error: Option<String>,
    /// The node (hex pubkey) whose kind 10002 list announced this relay;
    /// `None` for defaults and the solver's own.
    #[serde(default)]
    pub announced_by: Option<String>,
}

/// Global relay pool singleton, initialised once by [`initialize_relays`].
static POOL: OnceCell<Arc<RelayPool>> = OnceCell::const_new();

pub(crate) fn pool() -> Result<&'static Arc<RelayPool>> {
    POOL.get().ok_or_else(|| anyhow::anyhow!("NotInitialized"))
}

/// Start the relay pool with the persisted relay list — every active relay
/// the solver or a node added, with the removed announced relays restored as
/// the blacklist — or, on first launch, with the compiled-in defaults, which
/// are then seeded so later runs read them back.
///
/// Call after `init_db` and `rehydrate_active_node`. A second call in the
/// same process re-attaches to the pool it already has and returns `Ok`:
/// Android can destroy the Flutter engine while the process lives on, and the
/// next launch runs `main()` again against the same Rust statics (../app).
pub async fn initialize_relays() -> Result<()> {
    if POOL.get().is_some() {
        log::info!("[relay] pool already running — re-attaching");
        return Ok(());
    }

    let persisted = load_persisted_relays().await;
    let active: Vec<String> = persisted
        .iter()
        .filter(|r| r.is_active && !r.is_blacklisted)
        .map(|r| r.url.clone())
        .collect();
    let urls = if active.is_empty() {
        crate::config::DEFAULT_RELAYS
            .iter()
            .map(|s| s.to_string())
            .collect()
    } else {
        active
    };

    // get_or_try_init is atomic: only one caller creates the pool even if
    // two race past the check above.
    let pool = POOL
        .get_or_try_init(|| async { RelayPool::new(urls).await })
        .await?;
    pool.restore_persisted(&persisted).await;
    if persisted.is_empty() {
        if let Some(db) = crate::db::app_db::db() {
            if let Err(e) = crate::db::seeds::seed_default_relays(db).await {
                log::warn!("[relay] default relays not seeded: {e}");
            }
        }
    }

    // Each time the pool comes online, the active node's relay list and
    // instance info are read again. Subscribed before the state is read, so
    // an `Online` sent in between is not lost (../app).
    let rx = pool.subscribe_connection_state();
    let current = pool.connection_state().await;
    crate::rt::spawn(watch_online(rx, current));
    Ok(())
}

/// Run [`crate::api::nodes::refresh_active_node`] for every `Online` on
/// `rx`, and once up front when the pool was already online. Ends when the
/// channel closes.
async fn watch_online(
    mut rx: tokio::sync::broadcast::Receiver<ConnectionState>,
    current: ConnectionState,
) {
    use tokio::sync::broadcast::error::RecvError;

    if current == ConnectionState::Online {
        crate::api::nodes::refresh_active_node().await;
    }
    loop {
        match rx.recv().await {
            Ok(ConnectionState::Online) => crate::api::nodes::refresh_active_node().await,
            Ok(_) | Err(RecvError::Lagged(_)) => continue,
            Err(RecvError::Closed) => break,
        }
    }
}

/// Add a relay the solver typed and connect to it. The URL is normalised
/// first (scheme and host lower-cased, no trailing slash), so one relay is one
/// row however it was typed.
pub async fn add_relay(url: String) -> Result<RelayInfo> {
    let Some(url) = crate::nostr::relay_list::normalize_relay_url(&url) else {
        anyhow::bail!("InvalidRelayUrl");
    };
    let info = pool()?.add_relay(&url).await?;
    persist_relay(&info).await;
    Ok(info)
}

/// Remove a relay and disconnect. A relay a node announced stays persisted as
/// blacklisted, so the node's list cannot bring it back on the next start.
pub async fn remove_relay(url: String) -> Result<()> {
    let removed = pool()?.remove_relay(&url).await?;
    match removal_effect(removed) {
        Some(row) => persist_relay(&row).await,
        None => unpersist_relay(&url).await,
    }
    Ok(())
}

/// What removing a relay leaves in storage: `Some(row)` to persist, `None` to
/// delete the row outright. Only an announced relay is kept, blacklisted.
fn removal_effect(mut removed: RelayInfo) -> Option<RelayInfo> {
    if !matches!(removed.source, RelaySource::MostroDiscovered) {
        return None;
    }
    removed.is_active = false;
    removed.is_blacklisted = true;
    removed.status = RelayStatus::Disconnected;
    Some(removed)
}

/// Every configured relay with its current status.
pub async fn get_relays() -> Result<Vec<RelayInfo>> {
    Ok(pool()?.get_relays().await)
}

/// The pool's overall state.
pub async fn get_connection_state() -> Result<ConnectionState> {
    Ok(pool()?.connection_state().await)
}

/// Stream of connection state transitions (only real ones).
pub async fn on_connection_state_changed() -> Result<ConnectionStateStream> {
    Ok(ConnectionStateStream {
        rx: pool()?.subscribe_connection_state(),
    })
}

/// Stream of single relays whose status changed, or that were added or
/// removed.
pub async fn on_relay_status_changed() -> Result<RelayStatusStream> {
    Ok(RelayStatusStream {
        rx: pool()?.subscribe_relay_status(),
    })
}

/// Wrapper so flutter_rust_bridge can hand Dart a pull-based stream.
pub struct ConnectionStateStream {
    rx: tokio::sync::broadcast::Receiver<ConnectionState>,
}

impl ConnectionStateStream {
    /// The next state, or `None` once the pool is gone.
    pub async fn next(&mut self) -> Option<ConnectionState> {
        use tokio::sync::broadcast::error::RecvError;
        loop {
            match self.rx.recv().await {
                Ok(state) => return Some(state),
                Err(RecvError::Lagged(_)) => continue,
                Err(RecvError::Closed) => return None,
            }
        }
    }
}

/// Wrapper so flutter_rust_bridge can hand Dart a pull-based stream.
pub struct RelayStatusStream {
    rx: tokio::sync::broadcast::Receiver<RelayInfo>,
}

impl RelayStatusStream {
    /// The next relay that changed, or `None` once the pool is gone.
    pub async fn next(&mut self) -> Option<RelayInfo> {
        use tokio::sync::broadcast::error::RecvError;
        loop {
            match self.rx.recv().await {
                Ok(info) => return Some(info),
                Err(RecvError::Lagged(_)) => continue,
                Err(RecvError::Closed) => return None,
            }
        }
    }
}

/// Add every relay `node` (hex) announces that the list lacks, and persist
/// the additions. Called with the node's newest kind 10002 event, which the
/// caller has checked is authored by `node`.
pub(crate) async fn apply_relay_list(node: &str, announced: &[String]) {
    let Ok(pool) = pool() else {
        return;
    };
    let added = pool.sync_discovered(announced, node).await;
    if added.is_empty() {
        return;
    }
    for info in pool
        .get_relays()
        .await
        .iter()
        .filter(|r| added.contains(&r.url))
    {
        persist_relay(info).await;
    }
    log::info!(
        "[relay] added {} relay(s) from the node's list: {}",
        added.len(),
        added
            .iter()
            .map(|u| display_relay(u))
            .collect::<Vec<_>>()
            .join(", ")
    );
}

// ── Relay persistence (best effort: a failed write is logged and ignored) ───

async fn load_persisted_relays() -> Vec<RelayInfo> {
    let Some(db) = crate::db::app_db::db() else {
        return Vec::new();
    };
    match db.list_relays().await {
        Ok(rows) => rows,
        Err(e) => {
            log::warn!("[relay] relay list not loaded from storage: {e}");
            Vec::new()
        }
    }
}

async fn persist_relay(info: &RelayInfo) {
    if let Some(db) = crate::db::app_db::db() {
        if let Err(e) = db.save_relay(info).await {
            log::warn!("[relay] {} not persisted: {e}", display_relay(&info.url));
        }
    }
}

async fn unpersist_relay(url: &str) {
    if let Some(db) = crate::db::app_db::db() {
        if let Err(e) = db.delete_relay(url).await {
            log::warn!("[relay] {} not removed from storage: {e}", display_relay(url));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn row(source: RelaySource) -> RelayInfo {
        RelayInfo {
            url: "wss://a.example".into(),
            is_active: true,
            is_default: false,
            source,
            is_blacklisted: false,
            status: RelayStatus::Connected,
            last_connected_at: Some(1),
            last_error: None,
            announced_by: Some("aa".into()),
        }
    }

    #[test]
    fn only_a_removed_announced_relay_stays_stored_blacklisted() {
        let kept = removal_effect(row(RelaySource::MostroDiscovered)).unwrap();
        assert!(kept.is_blacklisted);
        assert!(!kept.is_active);
        assert_eq!(kept.status, RelayStatus::Disconnected);
        assert_eq!(kept.announced_by.as_deref(), Some("aa"));
        assert_eq!(removal_effect(row(RelaySource::UserAdded)), None);
        assert_eq!(removal_effect(row(RelaySource::Default)), None);
    }

    /// A row stored before `announced_by` existed still loads.
    #[test]
    fn a_row_without_announced_by_still_parses() {
        let json = r#"{"url":"wss://a","is_active":true,"is_default":true,
            "source":"Default","is_blacklisted":false,"status":"Disconnected",
            "last_connected_at":null,"last_error":null}"#;
        let info: RelayInfo = serde_json::from_str(json).unwrap();
        assert_eq!(info.announced_by, None);
    }
}
