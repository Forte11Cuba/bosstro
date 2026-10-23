//! IndexedDB storage backend — wasm only. From ../app's `db/indexeddb.rs`,
//! trimmed to phase 2's stores.
//!
//! Each record is keyed the way the SQLite table keys its row: settings by
//! key, relays by URL (a JSON document), node pictures by node pubkey (the
//! bytes as a `Uint8Array`, with a small JSON index naming the URL, so a sync
//! compares URLs without loading a picture). Every write here is a single
//! `put` or `delete`, never a read-modify-write of a stored document, so
//! ../app's `web_lock` (origin-wide locks for document patches) is not needed.
use anyhow::{anyhow, Result};
use indexed_db_futures::prelude::*;
use web_sys::wasm_bindgen::{JsCast, JsValue};

use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;
use crate::db::Storage;

/// Bumped when a store is added; `open_db` creates whatever is missing.
const DB_VERSION: u32 = 1;
const SETTINGS_STORE: &str = "settings";
const RELAYS_STORE: &str = "relays";
const NODE_PICTURES_STORE: &str = "node_pictures";
const NODE_PICTURE_INDEX_STORE: &str = "node_picture_index";
const ALL_STORES: [&str; 4] = [
    SETTINGS_STORE,
    RELAYS_STORE,
    NODE_PICTURES_STORE,
    NODE_PICTURE_INDEX_STORE,
];

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
}
