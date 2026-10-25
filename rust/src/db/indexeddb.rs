//! IndexedDB storage backend — wasm only. From MostroP2P/app's
//! `db/indexeddb.rs`, trimmed to Bosstro's stores.
//!
//! Each record is keyed the way the SQLite table keys its row: settings by
//! key, relays by URL (a JSON document), node pictures by node pubkey (the
//! bytes as a `Uint8Array`, with a small JSON index naming the URL, so a sync
//! compares URLs without loading a picture), disputes by `node:dispute id` (a
//! JSON document), chat messages by `node:dispute:party:solver:message id`
//! (a JSON document), observed chat messages by `node:dispute:solver:message
//! id` (a JSON document), attachment blobs by their SHA-256 (the encrypted bytes
//! as a `Uint8Array`, with a JSON index entry for the trim, as MostroP2P/app).
//! This backend has no compound writes: each method is one `put` or `delete` (a
//! picture's or a blob's bytes and index in one transaction), so it needs
//! none of MostroP2P/app's `web_lock`.
//!
//! Its callers can still read, modify and write back: `api::nodes` does so
//! with the registry's settings blobs (`CUSTOM_MOSTRO_NODES`,
//! `MOSTRO_NODE_METADATA`), under `REGISTRY_LOCK`, which serialises only
//! within one process — one browser tab. Two tabs of the app open at once
//! can each read a blob and write it back, and one tab's change is lost.
//! `crate::disputes::feed` does the same with a dispute row (read, merge,
//! save); two tabs merge the same relay events, so at worst one tab writes a
//! revision the other already replaced, and the next event corrects it.
//! Accepted for the web (A2; AGENTS.md → "Accepted limits"); MostroP2P/app's
//! `web_lock` is the fix if it ever matters.
use anyhow::{anyhow, Result};
use indexed_db_futures::prelude::*;
use web_sys::wasm_bindgen::{JsCast, JsValue};

use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;
use crate::db::blob_cache::{blobs_to_evict, BlobEntry, WEB_ATTACHMENT_CACHE_BYTES};
use crate::db::Storage;
use crate::api::chat::ChatDelivery;
use crate::api::disputes::DisputeStatus;
use crate::chat::observer::{ObservedRecord, ObservedRef};
use crate::chat::{ChannelRef, ChatRecord};
use crate::disputes::DisputeRecord;

/// Bumped when a store is added; `open_db` creates whatever is missing.
/// 2: disputes (phase 3). 3: dispute_messages (phase 5). 4: the attachment
/// cache (phase 5, part 2). 5: observed_messages (phase 5c).
const DB_VERSION: u32 = 5;
const SETTINGS_STORE: &str = "settings";
const RELAYS_STORE: &str = "relays";
const NODE_PICTURES_STORE: &str = "node_pictures";
const NODE_PICTURE_INDEX_STORE: &str = "node_picture_index";
const DISPUTES_STORE: &str = "disputes";
const CHAT_STORE: &str = "dispute_messages";
const ATTACHMENT_BLOBS_STORE: &str = "attachment_blobs";
const ATTACHMENT_INDEX_STORE: &str = "attachment_blob_index";
const OBSERVED_STORE: &str = "observed_messages";
const ALL_STORES: [&str; 9] = [
    SETTINGS_STORE,
    RELAYS_STORE,
    NODE_PICTURES_STORE,
    NODE_PICTURE_INDEX_STORE,
    DISPUTES_STORE,
    CHAT_STORE,
    ATTACHMENT_BLOBS_STORE,
    ATTACHMENT_INDEX_STORE,
    OBSERVED_STORE,
];

/// The key of a dispute's record: one per node and dispute (D6).
fn dispute_key(mostro_pubkey: &str, dispute_id: &str) -> String {
    format!("{mostro_pubkey}:{dispute_id}")
}

/// The key prefix of one chat channel's records: node, dispute, party and
/// solver key. A message's key is the prefix and its id; the channel's
/// records are the range `prefix:` ..< `prefix;`.
fn channel_prefix(channel: &ChannelRef) -> String {
    format!(
        "{}:{}:{}:{}",
        channel.mostro_pubkey,
        channel.dispute_id,
        channel.party.as_wire(),
        channel.solver_pubkey
    )
}

fn chat_key(channel: &ChannelRef, message_id: &str) -> String {
    format!("{}:{message_id}", channel_prefix(channel))
}

/// The key prefix of one observed chat's records: node, dispute and solver
/// key. A message's key is the prefix and its id; the chat's records are the
/// range `prefix:` ..< `prefix;`.
fn observed_prefix(observed: &ObservedRef) -> String {
    format!(
        "{}:{}:{}",
        observed.mostro_pubkey, observed.dispute_id, observed.solver_pubkey
    )
}

/// What [`NODE_PICTURE_INDEX_STORE`] keeps of one node's picture.
#[derive(serde::Serialize, serde::Deserialize)]
struct NodePictureEntry {
    pubkey: String,
    url: String,
}

/// Map an opaque JS-side error into an `anyhow` error the trait can carry.
fn js_err(context: &str, e: impl std::fmt::Debug) -> anyhow::Error {
    anyhow!("{context}: {e:?}")
}

pub struct IndexedDbStorage {
    /// IndexedDB database name, from `init_db`'s path argument.
    db_name: String,
}

impl IndexedDbStorage {
    pub async fn open(db_name: &str) -> Result<Self> {
        let storage = Self {
            db_name: db_name.to_string(),
        };
        // Open once eagerly so schema creation (and any quota or permission
        // failure) surfaces at init time, not on the first write.
        storage.open_db().await?;
        Ok(storage)
    }

    /// Open the database, creating the object stores on first use.
    ///
    /// `IdbDatabase` wraps JS values and is not `Send`, so it cannot be cached
    /// in this struct (the storage singleton must be `Send + Sync`). Opening
    /// per operation is cheap: the browser keeps the connection warm.
    async fn open_db(&self) -> Result<IdbDatabase> {
        let mut req = IdbDatabase::open_u32(&self.db_name, DB_VERSION)
            .map_err(|e| js_err("indexeddb open", e))?;
        req.set_on_upgrade_needed(Some(|evt: &IdbVersionChangeEvent| -> Result<(), JsValue> {
            let db = evt.db();
            for store in ALL_STORES {
                if !db.object_store_names().any(|n| n == store) {
                    db.create_object_store(store)?;
                }
            }
            Ok(())
        }));
        req.await.map_err(|e| js_err("indexeddb open await", e))
    }

    /// Write one string value under a string key in `store_name`.
    async fn put_string(&self, store_name: &str, key: &str, value: &str) -> Result<()> {
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(store_name, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(store_name)
            .map_err(|e| js_err("store open", e))?;
        store
            .put_key_val_owned(key, &JsValue::from_str(value))
            .map_err(|e| js_err("put", e))?;
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        Ok(())
    }

    /// The string value under `key` in `store_name`, if present.
    async fn get_string(&self, store_name: &str, key: &str) -> Result<Option<String>> {
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(store_name, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(store_name)
            .map_err(|e| js_err("store open", e))?;
        let value = store
            .get_owned(key)
            .map_err(|e| js_err("get", e))?
            .await
            .map_err(|e| js_err("get await", e))?;
        Ok(value.and_then(|v| v.as_string()))
    }

    /// All string values stored in `store_name`.
    async fn get_all_strings(&self, store_name: &str) -> Result<Vec<String>> {
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(store_name, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(store_name)
            .map_err(|e| js_err("store open", e))?;
        let array = store
            .get_all()
            .map_err(|e| js_err("get_all", e))?
            .await
            .map_err(|e| js_err("get_all await", e))?;
        Ok(array.iter().filter_map(|v| v.as_string()).collect())
    }

    /// Removes `key` from `store_name`; an absent key is not an error.
    async fn delete_key(&self, store_name: &str, key: &str) -> Result<()> {
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(store_name, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(store_name)
            .map_err(|e| js_err("store open", e))?;
        store.delete_owned(key).map_err(|e| js_err("delete", e))?;
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        Ok(())
    }
}

impl Storage for IndexedDbStorage {
    async fn get_setting(&self, key: &str) -> Result<Option<String>> {
        self.get_string(SETTINGS_STORE, key).await
    }

    async fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        self.put_string(SETTINGS_STORE, key, value).await
    }

    async fn delete_setting(&self, key: &str) -> Result<()> {
        self.delete_key(SETTINGS_STORE, key).await
    }

    async fn save_relay(&self, relay: &RelayInfo) -> Result<()> {
        let json = serde_json::to_string(relay)?;
        self.put_string(RELAYS_STORE, &relay.url, &json).await
    }

    async fn list_relays(&self) -> Result<Vec<RelayInfo>> {
        Ok(self
            .get_all_strings(RELAYS_STORE)
            .await?
            .iter()
            .filter_map(|json| serde_json::from_str(json).ok())
            .collect())
    }

    // ── Node pictures — bytes and URL, written and removed together ─────────

    async fn save_node_picture(&self, pubkey: &str, url: &str, bytes: &[u8]) -> Result<()> {
        let entry = serde_json::to_string(&NodePictureEntry {
            pubkey: pubkey.to_string(),
            url: url.to_string(),
        })?;
        let data = web_sys::js_sys::Uint8Array::from(bytes);
        // Both requests are queued before the first await, in one
        // transaction, so the URL never names other bytes.
        let db = self.open_db().await?;
        let stores = [NODE_PICTURES_STORE, NODE_PICTURE_INDEX_STORE];
        let tx = db
            .transaction_on_multi_with_mode(&stores, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        tx.object_store(NODE_PICTURES_STORE)
            .map_err(|e| js_err("store open", e))?
            .put_key_val_owned(pubkey, &data)
            .map_err(|e| js_err("put", e))?;
        tx.object_store(NODE_PICTURE_INDEX_STORE)
            .map_err(|e| js_err("store open", e))?
            .put_key_val_owned(pubkey, &JsValue::from_str(&entry))
            .map_err(|e| js_err("put", e))?;
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        Ok(())
    }

    async fn get_node_picture(&self, pubkey: &str) -> Result<Option<MostroNodePicture>> {
        let db = self.open_db().await?;
        let stores = [NODE_PICTURES_STORE, NODE_PICTURE_INDEX_STORE];
        let tx = db
            .transaction_on_multi_with_mode(&stores, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        // Both requests queued before either is awaited, as in the save.
        let bytes = tx
            .object_store(NODE_PICTURES_STORE)
            .map_err(|e| js_err("store open", e))?
            .get_owned(pubkey)
            .map_err(|e| js_err("get", e))?;
        let entry = tx
            .object_store(NODE_PICTURE_INDEX_STORE)
            .map_err(|e| js_err("store open", e))?
            .get_owned(pubkey)
            .map_err(|e| js_err("get", e))?;
        let bytes = bytes
            .await
            .map_err(|e| js_err("get await", e))?
            .filter(JsCast::is_instance_of::<web_sys::js_sys::Uint8Array>)
            .map(|v| web_sys::js_sys::Uint8Array::from(v).to_vec());
        let url = entry
            .await
            .map_err(|e| js_err("get await", e))?
            .and_then(|v| v.as_string())
            .and_then(|json| serde_json::from_str::<NodePictureEntry>(&json).ok())
            .map(|entry| entry.url);
        Ok(url
            .zip(bytes)
            .map(|(url, bytes)| MostroNodePicture { url, bytes }))
    }

    async fn list_node_picture_urls(&self) -> Result<std::collections::HashMap<String, String>> {
        Ok(self
            .get_all_strings(NODE_PICTURE_INDEX_STORE)
            .await?
            .into_iter()
            .filter_map(|json| serde_json::from_str::<NodePictureEntry>(&json).ok())
            .map(|entry| (entry.pubkey, entry.url))
            .collect())
    }

    async fn delete_node_picture(&self, pubkey: &str) -> Result<()> {
        let db = self.open_db().await?;
        let stores = [NODE_PICTURES_STORE, NODE_PICTURE_INDEX_STORE];
        let tx = db
            .transaction_on_multi_with_mode(&stores, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        for name in stores {
            tx.object_store(name)
                .map_err(|e| js_err("store open", e))?
                .delete_owned(pubkey)
                .map_err(|e| js_err("delete", e))?;
        }
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        Ok(())
    }

    // ── Disputes ─────────────────────────────────────────────────────────────

    async fn save_dispute(&self, dispute: &DisputeRecord) -> Result<()> {
        let json = serde_json::to_string(dispute)?;
        let key = dispute_key(&dispute.mostro_pubkey, &dispute.dispute_id);
        self.put_string(DISPUTES_STORE, &key, &json).await
    }

    async fn get_dispute(
        &self,
        mostro_pubkey: &str,
        dispute_id: &str,
    ) -> Result<Option<DisputeRecord>> {
        let key = dispute_key(mostro_pubkey, dispute_id);
        Ok(self
            .get_string(DISPUTES_STORE, &key)
            .await?
            .and_then(|json| serde_json::from_str(&json).ok()))
    }

    async fn list_disputes(&self, mostro_pubkey: &str) -> Result<Vec<DisputeRecord>> {
        // Every node's rows are read and the others dropped: a few hundred
        // small documents, not worth a key range.
        Ok(self
            .get_all_strings(DISPUTES_STORE)
            .await?
            .iter()
            .filter_map(|json| serde_json::from_str::<DisputeRecord>(json).ok())
            .filter(|row| row.mostro_pubkey == mostro_pubkey)
            .collect())
    }

    async fn list_disputes_with_status(
        &self,
        mostro_pubkey: &str,
        status: DisputeStatus,
    ) -> Result<Vec<DisputeRecord>> {
        // Only this node's records are read: its keys are the range
        // `node:` ..< `node;` (`;` follows `:`). The status is checked here:
        // an IndexedDB index needs object values with a key path, and these
        // records are JSON strings (a schema change not worth a few hundred
        // rows).
        let range = web_sys::IdbKeyRange::bound(
            &JsValue::from_str(&format!("{mostro_pubkey}:")),
            &JsValue::from_str(&format!("{mostro_pubkey};")),
        )
        .map_err(|e| js_err("key range", e))?;
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(DISPUTES_STORE, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(DISPUTES_STORE)
            .map_err(|e| js_err("store open", e))?;
        let array = store
            .get_all_with_key(&range)
            .map_err(|e| js_err("get_all", e))?
            .await
            .map_err(|e| js_err("get_all await", e))?;
        Ok(array
            .iter()
            .filter_map(|v| v.as_string())
            .filter_map(|json| serde_json::from_str::<DisputeRecord>(&json).ok())
            .filter(|row| row.mostro_pubkey == mostro_pubkey && row.status == status)
            .collect())
    }

    // ── Dispute chat ─────────────────────────────────────────────────────────

    async fn insert_chat_message(&self, message: &ChatRecord) -> Result<bool> {
        // Read, then write: the router serialises its writes (one tab). Two
        // tabs storing the same message write the same record.
        let key = chat_key(&message.channel, &message.message_id);
        if self.get_string(CHAT_STORE, &key).await?.is_some() {
            return Ok(false);
        }
        let stored = ChatRecord {
            seq: crate::chat::next_seq(),
            ..message.clone()
        };
        let json = serde_json::to_string(&stored)?;
        self.put_string(CHAT_STORE, &key, &json).await?;
        Ok(true)
    }

    async fn get_chat_message(
        &self,
        channel: &ChannelRef,
        message_id: &str,
    ) -> Result<Option<ChatRecord>> {
        Ok(self
            .get_string(CHAT_STORE, &chat_key(channel, message_id))
            .await?
            .and_then(|json| serde_json::from_str(&json).ok()))
    }

    async fn list_chat_messages(&self, channel: &ChannelRef) -> Result<Vec<ChatRecord>> {
        let prefix = channel_prefix(channel);
        let range = web_sys::IdbKeyRange::bound(
            &JsValue::from_str(&format!("{prefix}:")),
            &JsValue::from_str(&format!("{prefix};")),
        )
        .map_err(|e| js_err("key range", e))?;
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(CHAT_STORE, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(CHAT_STORE)
            .map_err(|e| js_err("store open", e))?;
        let array = store
            .get_all_with_key(&range)
            .map_err(|e| js_err("get_all", e))?
            .await
            .map_err(|e| js_err("get_all await", e))?;
        Ok(array
            .iter()
            .filter_map(|v| v.as_string())
            .filter_map(|json| serde_json::from_str::<ChatRecord>(&json).ok())
            .filter(|row| &row.channel == channel)
            .collect())
    }

    async fn set_chat_delivery(
        &self,
        channel: &ChannelRef,
        message_id: &str,
        delivery: ChatDelivery,
    ) -> Result<()> {
        let Some(mut row) = self.get_chat_message(channel, message_id).await? else {
            return Ok(());
        };
        row.delivery = delivery;
        let json = serde_json::to_string(&row)?;
        self.put_string(CHAT_STORE, &chat_key(channel, message_id), &json)
            .await
    }

    async fn delete_chat_message(&self, channel: &ChannelRef, message_id: &str) -> Result<()> {
        self.delete_key(CHAT_STORE, &chat_key(channel, message_id))
            .await
    }

    // ── Observed chats ───────────────────────────────────────────────────────

    async fn insert_observed_message(&self, message: &ObservedRecord) -> Result<bool> {
        // Read, then write, as the chat: one read at a time per tab, and two
        // tabs storing the same message write the same record.
        let key = format!(
            "{}:{}",
            observed_prefix(&message.conversation),
            message.message_id
        );
        if self.get_string(OBSERVED_STORE, &key).await?.is_some() {
            return Ok(false);
        }
        let json = serde_json::to_string(message)?;
        self.put_string(OBSERVED_STORE, &key, &json).await?;
        Ok(true)
    }

    async fn list_observed_messages(&self, observed: &ObservedRef) -> Result<Vec<ObservedRecord>> {
        let prefix = observed_prefix(observed);
        let range = web_sys::IdbKeyRange::bound(
            &JsValue::from_str(&format!("{prefix}:")),
            &JsValue::from_str(&format!("{prefix};")),
        )
        .map_err(|e| js_err("key range", e))?;
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(OBSERVED_STORE, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let store = tx
            .object_store(OBSERVED_STORE)
            .map_err(|e| js_err("store open", e))?;
        let array = store
            .get_all_with_key(&range)
            .map_err(|e| js_err("get_all", e))?
            .await
            .map_err(|e| js_err("get_all await", e))?;
        Ok(array
            .iter()
            .filter_map(|v| v.as_string())
            .filter_map(|json| serde_json::from_str::<ObservedRecord>(&json).ok())
            .filter(|row| &row.conversation == observed)
            .collect())
    }

    // ── Attachment cache — encrypted blobs only, with their index entry ─────

    async fn save_attachment_blob(&self, sha256: &str, blob: &[u8]) -> Result<()> {
        let index = serde_json::to_string(&BlobEntry {
            sha256: sha256.to_string(),
            size: blob.len() as u64,
            created_at: crate::rt::unix_now(),
        })?;
        let data = web_sys::js_sys::Uint8Array::from(blob);
        // The blob and its index entry commit together, so the trim never
        // misses a blob nor deletes one it has no entry for.
        let db = self.open_db().await?;
        let stores = [ATTACHMENT_BLOBS_STORE, ATTACHMENT_INDEX_STORE];
        let tx = db
            .transaction_on_multi_with_mode(&stores, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        tx.object_store(ATTACHMENT_BLOBS_STORE)
            .map_err(|e| js_err("store open", e))?
            .put_key_val_owned(sha256, &data)
            .map_err(|e| js_err("put", e))?;
        tx.object_store(ATTACHMENT_INDEX_STORE)
            .map_err(|e| js_err("store open", e))?
            .put_key_val_owned(sha256, &JsValue::from_str(&index))
            .map_err(|e| js_err("put", e))?;
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        self.trim_attachment_blobs(WEB_ATTACHMENT_CACHE_BYTES).await
    }

    async fn get_attachment_blob(&self, sha256: &str) -> Result<Option<Vec<u8>>> {
        let db = self.open_db().await?;
        let tx = db
            .transaction_on_one_with_mode(ATTACHMENT_BLOBS_STORE, IdbTransactionMode::Readonly)
            .map_err(|e| js_err("tx open", e))?;
        let value = tx
            .object_store(ATTACHMENT_BLOBS_STORE)
            .map_err(|e| js_err("store open", e))?
            .get_owned(sha256)
            .map_err(|e| js_err("get", e))?
            .await
            .map_err(|e| js_err("get await", e))?;
        Ok(value
            .filter(JsCast::is_instance_of::<web_sys::js_sys::Uint8Array>)
            .map(|v| web_sys::js_sys::Uint8Array::from(v).to_vec()))
    }

    /// Reads only the index; each evicted blob goes with its entry.
    async fn trim_attachment_blobs(&self, cap: u64) -> Result<()> {
        let entries = self
            .get_all_strings(ATTACHMENT_INDEX_STORE)
            .await?
            .into_iter()
            .filter_map(|json| serde_json::from_str::<BlobEntry>(&json).ok())
            .collect();
        let evicted = blobs_to_evict(entries, cap);
        if evicted.is_empty() {
            return Ok(());
        }
        let db = self.open_db().await?;
        let stores = [ATTACHMENT_BLOBS_STORE, ATTACHMENT_INDEX_STORE];
        let tx = db
            .transaction_on_multi_with_mode(&stores, IdbTransactionMode::Readwrite)
            .map_err(|e| js_err("tx open", e))?;
        for name in stores {
            let store = tx.object_store(name).map_err(|e| js_err("store open", e))?;
            for sha256 in &evicted {
                store
                    .delete_owned(sha256.as_str())
                    .map_err(|e| js_err("delete", e))?;
            }
        }
        tx.await.into_result().map_err(|e| js_err("tx commit", e))?;
        Ok(())
    }
}

/// The same checks as the SQLite backend's, in a browser
/// (`scripts/test-web-storage.sh`). Each test opens a database of its own.
#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::contract;
    use wasm_bindgen_test::*;

    wasm_bindgen_test_configure!(run_in_browser);

    async fn store(name: &str) -> IndexedDbStorage {
        let name = format!("bosstro_test_{name}_{}", crate::rt::unix_now());
        IndexedDbStorage::open(&name).await.unwrap()
    }

    #[wasm_bindgen_test]
    async fn settings_round_trip() {
        contract::settings_round_trip(&store("settings").await).await;
    }

    #[wasm_bindgen_test]
    async fn active_node_is_absent_until_saved() {
        contract::active_node_is_absent_until_saved(&store("active").await).await;
    }

    #[wasm_bindgen_test]
    async fn relays_round_trip() {
        contract::relays_round_trip(&store("relays").await).await;
    }

    #[wasm_bindgen_test]
    async fn node_pictures_round_trip() {
        contract::node_pictures_round_trip(&store("pictures").await).await;
    }

    #[wasm_bindgen_test]
    async fn disputes_round_trip() {
        contract::disputes_round_trip(&store("disputes").await).await;
    }

    #[wasm_bindgen_test]
    async fn a_resolution_round_trips() {
        contract::a_resolution_round_trips(&store("resolutions").await).await;
    }

    #[wasm_bindgen_test]
    async fn disputes_never_mix_nodes() {
        contract::disputes_never_mix_nodes(&store("disputes_nodes").await).await;
    }

    #[wasm_bindgen_test]
    async fn disputes_by_status() {
        contract::disputes_by_status(&store("disputes_status").await).await;
    }

    #[wasm_bindgen_test]
    async fn takes_keep_their_solver() {
        contract::takes_keep_their_solver(&store("disputes_takes").await).await;
    }

    #[wasm_bindgen_test]
    async fn chat_messages_round_trip() {
        contract::chat_messages_round_trip(&store("chat").await).await;
    }

    #[wasm_bindgen_test]
    async fn chat_messages_keep_their_arrival_order() {
        contract::chat_messages_keep_their_arrival_order(&store("chat_order").await).await;
    }

    #[wasm_bindgen_test]
    async fn chat_channels_never_mix() {
        contract::chat_channels_never_mix(&store("chat_mix").await).await;
    }

    #[wasm_bindgen_test]
    async fn the_chat_cursor_never_passes_the_clock_of_acceptance() {
        contract::the_chat_cursor_never_passes_the_clock_of_acceptance(&store("chat_cursor").await)
            .await;
    }

    #[wasm_bindgen_test]
    async fn observed_messages_round_trip() {
        contract::observed_messages_round_trip(&store("observed").await).await;
    }

    #[wasm_bindgen_test]
    async fn observed_chats_never_mix_with_each_other_or_the_chat() {
        contract::observed_chats_never_mix_with_each_other_or_the_chat(
            &store("observed_mix").await,
        )
        .await;
    }

    #[wasm_bindgen_test]
    async fn attachment_blobs_are_cached_and_bounded() {
        contract::attachment_blobs_are_cached_and_bounded(&store("blobs").await).await;
    }

    /// A take written before phase 4 named its solver (none was, but a row
    /// is JSON here) still reads, with no solver: it is no key's.
    #[wasm_bindgen_test]
    async fn a_take_without_its_solver_still_reads() {
        let mut row = contract::dispute("aa", contract::DISPUTE_A);
        row.taken = Some(crate::disputes::tests::taken());
        let mut json: serde_json::Value = serde_json::to_value(&row).unwrap();
        json["taken"]
            .as_object_mut()
            .unwrap()
            .remove("solver_pubkey");
        let storage = store("disputes_legacy").await;
        storage
            .put_string(
                DISPUTES_STORE,
                &dispute_key("aa", contract::DISPUTE_A),
                &json.to_string(),
            )
            .await
            .unwrap();
        let read = storage
            .get_dispute("aa", contract::DISPUTE_A)
            .await
            .unwrap()
            .unwrap();
        assert_eq!(read.taken.unwrap().solver_pubkey, "");
    }
}
