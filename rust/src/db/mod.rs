//! Persistent storage (A4), from ../app's `rust/src/db/`, trimmed to what
//! Bosstro uses: the settings key-value store, the relays, the node pictures
//! (phase 2), the disputes (phase 3), the dispute chat and its attachment
//! cache (phase 5), the observed chats (phase 5c).
//!
//! One [`Storage`] trait, two backends picked at compile time
//! (`app_db.rs`): SQLite through `sqlx` on native (Android, Linux),
//! IndexedDB on the web. Neither is encrypted (SQLCipher is post-MVP).
//! No key is ever written here: the chat's channel keys and the attachment
//! keys live in memory (`crate::chat`, `crate::crypto::file_enc`), and the
//! attachment cache holds encrypted blobs only.

pub mod app_db;
pub(crate) mod blob_cache;
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
use crate::api::disputes::DisputeStatus;
use crate::api::chat::ChatDelivery;
use crate::chat::observer::{ObservedRecord, ObservedRef};
use crate::chat::{ChannelRef, ChatRecord};
use crate::disputes::DisputeRecord;

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

    /// What one solver key has learned about itself on one node, as JSON
    /// (`crate::mostro::standing`): whether it is a solver there, and its
    /// permission (D12). Keyed by node and key, so neither a node switch nor
    /// another nsec inherits it.
    pub const SOLVER_STANDING_PREFIX: &str = "solver_standing:";

    /// [`SOLVER_STANDING_PREFIX`] for `node` and `solver` (both hex).
    pub fn solver_standing(node: &str, solver: &str) -> String {
        format!("{SOLVER_STANDING_PREFIX}{node}:{solver}")
    }

    /// The language the solver chose for the app (a code such as `es`).
    /// Absent while the app follows the system's language.
    pub const LANGUAGE: &str = "language";
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

    // ── Disputes (`crate::disputes`), one row per node and dispute (D6) ─────

    /// Insert or replace the row of (`mostro_pubkey`, `dispute_id`), every
    /// field included. Whether a revision should replace the row is decided
    /// before, by `crate::disputes::merge`.
    async fn save_dispute(&self, dispute: &DisputeRecord) -> Result<()>;
    /// One dispute of one node, if stored.
    async fn get_dispute(
        &self,
        mostro_pubkey: &str,
        dispute_id: &str,
    ) -> Result<Option<DisputeRecord>>;
    /// Every stored dispute of `mostro_pubkey`, whatever its status, in no
    /// particular order. Another node's rows never appear. Unused in the app
    /// since Pending reads by status; kept for phase 4, which reconciles this
    /// solver's disputes whatever their status.
    #[cfg_attr(not(test), allow(dead_code))]
    async fn list_disputes(&self, mostro_pubkey: &str) -> Result<Vec<DisputeRecord>>;
    /// The stored disputes of `mostro_pubkey` whose status is `status` (Pending
    /// reads `initiated`), in no particular order.
    async fn list_disputes_with_status(
        &self,
        mostro_pubkey: &str,
        status: DisputeStatus,
    ) -> Result<Vec<DisputeRecord>>;

    // ── Dispute chat (`crate::chat`), one row per channel and message ────────

    /// Store `message` unless its channel already has that message id.
    /// Returns whether it was stored (false: a copy).
    async fn insert_chat_message(&self, message: &ChatRecord) -> Result<bool>;
    /// One message of a channel, if stored.
    async fn get_chat_message(
        &self,
        channel: &ChannelRef,
        message_id: &str,
    ) -> Result<Option<ChatRecord>>;
    /// Every message of `channel`, in no particular order. Another channel's
    /// never appear.
    async fn list_chat_messages(&self, channel: &ChannelRef) -> Result<Vec<ChatRecord>>;
    /// Set the delivery of one message. No-op when absent.
    async fn set_chat_delivery(
        &self,
        channel: &ChannelRef,
        message_id: &str,
        delivery: ChatDelivery,
    ) -> Result<()>;
    /// Remove one message (a failed one replaced by its retry). No-op when
    /// absent.
    async fn delete_chat_message(&self, channel: &ChannelRef, message_id: &str) -> Result<()>;
    /// Where `channel`'s subscription resumes: the newest
    /// `min(created_at, received_at)` of its messages, never past the clock
    /// of the device that accepted them; `None` without messages.
    async fn chat_cursor(&self, channel: &ChannelRef) -> Result<Option<i64>> {
        Ok(self
            .list_chat_messages(channel)
            .await?
            .iter()
            .map(ChatRecord::cursor)
            .max())
    }

    // ── Observed chats (`crate::chat::observer`), apart from the chat ───────

    /// Store `message` unless its observed chat already has that message id.
    /// Returns whether it was stored (false: a copy).
    async fn insert_observed_message(&self, message: &ObservedRecord) -> Result<bool>;
    /// Every message of one observed chat, in no particular order. Another
    /// one's never appear, and neither does any of the solver's own chats.
    async fn list_observed_messages(&self, observed: &ObservedRef) -> Result<Vec<ObservedRecord>>;

    // ── Attachment cache (`crate::attachments`), encrypted blobs only ───────

    /// Keep `blob` (encrypted, as on Blossom) under its hex SHA-256, then trim
    /// the cache to the platform's cap, oldest first.
    async fn save_attachment_blob(&self, sha256: &str, blob: &[u8]) -> Result<()>;
    /// The cached blob of `sha256`, if it was kept and not evicted.
    async fn get_attachment_blob(&self, sha256: &str) -> Result<Option<Vec<u8>>>;
    /// Drop the oldest blobs until the rest fit in `cap` bytes.
    async fn trim_attachment_blobs(&self, cap: u64) -> Result<()>;
}

