//! Persistent storage (A4), from ../app's `rust/src/db/`, trimmed to what
//! phase 2 uses: the settings key-value store, the relays and the node
//! pictures. Phase 3 adds the dispute tables.
//!
//! One [`Storage`] trait, two backends picked at compile time
//! (`app_db.rs`): SQLite through `sqlx` on native (Android, Linux),
//! IndexedDB on the web. Neither is encrypted (SQLCipher is post-MVP).

pub mod app_db;
#[cfg(target_arch = "wasm32")]
pub mod indexeddb;
pub mod seeds;
#[cfg(not(target_arch = "wasm32"))]
pub mod sqlite;

#[cfg(test)]
pub(crate) mod contract;

use anyhow::Result;

use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;

/// Keys used in the generic key-value settings store.
///
/// Collected here so the namespace is greppable in one place: the store has no
/// schema, so a typo in a key string is a silently-lost setting rather than a
/// compile error.
pub mod settings_keys {
    /// Active Mostro node pubkey (hex). Written through the dedicated
    /// [`super::Storage::save_active_mostro_pubkey`] accessor. Absent until
    /// the solver chooses a node.
    pub const ACTIVE_MOSTRO_PUBKEY: &str = "active_mostro_pubkey";

    /// User-added Mostro nodes, JSON array of `crate::api::nodes::CustomNode`.
    /// The trusted registry is compiled in (`crate::config`); only user
    /// additions are persisted.
    pub const CUSTOM_MOSTRO_NODES: &str = "custom_mostro_nodes";

    /// Cached kind 0 display metadata of known nodes, JSON map of pubkey
    /// (hex) → `crate::api::nodes::NodeMetadata`. Stale entries are fine.
    pub const MOSTRO_NODE_METADATA: &str = "mostro_node_metadata";

    /// The newest kind 38385 instance event seen from one node, as JSON
    /// (`crate::api::node_info::CachedNodeInfo`): one key per node, so a
    /// switch never mixes two nodes' info (D6).
    pub const NODE_INFO_PREFIX: &str = "node_info:";

    /// [`NODE_INFO_PREFIX`] for `pubkey` (hex).
    pub fn node_info(pubkey: &str) -> String {
        format!("{NODE_INFO_PREFIX}{pubkey}")
    }
}

/// Storage trait — implemented by SQLite (native) and IndexedDB (wasm).
///
/// `#[allow(async_fn_in_trait)]` instead of `async-trait`, as in ../app: the
/// futures are not required to be `Send`. Callers reach a concrete backend
/// through `app_db::db()`, whose futures are `Send` on native (`sqlx`).
#[allow(async_fn_in_trait)]
pub trait Storage: Send + Sync {
    // ── Settings ─────────────────────────────────────────────────────────────

    /// A value from the key-value settings store, or `None` when the key was
    /// never written. See [`settings_keys`] for the keys in use.
    async fn get_setting(&self, key: &str) -> Result<Option<String>>;

    /// Write `value` under `key`, replacing any previous value.
    async fn set_setting(&self, key: &str, value: &str) -> Result<()>;

    /// Remove `key`. Absent keys are not an error.
    async fn delete_setting(&self, key: &str) -> Result<()>;

    /// Persist the active node's pubkey (hex).
    async fn save_active_mostro_pubkey(&self, pubkey: &str) -> Result<()> {
        self.set_setting(settings_keys::ACTIVE_MOSTRO_PUBKEY, pubkey)
            .await
    }

    /// The persisted active node, or `None` when the solver has not chosen one.
    async fn get_active_mostro_pubkey(&self) -> Result<Option<String>> {
        self.get_setting(settings_keys::ACTIVE_MOSTRO_PUBKEY).await
    }

    // ── Relays ───────────────────────────────────────────────────────────────

    /// Insert or replace the row of `relay.url`.
    async fn save_relay(&self, relay: &RelayInfo) -> Result<()>;
    /// Remove the row of `url`. Absent rows are not an error.
    async fn delete_relay(&self, url: &str) -> Result<()>;
    /// Every stored relay. A row that no longer parses is skipped.
    async fn list_relays(&self) -> Result<Vec<RelayInfo>>;

    // ── Node pictures (`crate::node_pictures`) ──────────────────────────────

    /// Insert or replace `pubkey`'s picture.
    async fn save_node_picture(&self, pubkey: &str, url: &str, bytes: &[u8]) -> Result<()>;
    /// `pubkey`'s stored picture, if any.
    async fn get_node_picture(&self, pubkey: &str) -> Result<Option<MostroNodePicture>>;
    /// The URL of every stored picture, by node pubkey, without the bytes.
    async fn list_node_picture_urls(&self) -> Result<std::collections::HashMap<String, String>>;
    /// Remove `pubkey`'s picture. No-op when absent.
    async fn delete_node_picture(&self, pubkey: &str) -> Result<()>;
}
