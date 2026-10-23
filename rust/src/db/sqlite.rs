//! SQLite storage backend — native platforms only. From ../app's
//! `db/sqlite.rs`, trimmed to phase 2's tables.
//!
//! The schema is versioned with `sqlx` migrations (`rust/migrations/`,
//! embedded at compile time): each file runs once, in order, and a later
//! phase adds a file instead of editing one.
use anyhow::Result;
use sqlx::sqlite::{
    SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions, SqliteSynchronous,
};
use sqlx::SqlitePool;

use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;
use crate::db::Storage;

/// Size of the connection pool, as in ../app.
const MAX_CONNECTIONS: u32 = 4;

pub struct SqliteStorage {
    pool: SqlitePool,
}

impl SqliteStorage {
    /// Open (or create) the database at `path` and bring its schema up to
    /// date.
    pub async fn open(path: &str) -> Result<Self> {
        // Pragmas are applied per connection as the pool opens it.
        // `synchronous = NORMAL` is the documented companion to WAL: durable
        // across process crashes, without an fsync on every write.
        let options = SqliteConnectOptions::new()
            .filename(path)
            .create_if_missing(true)
            .journal_mode(SqliteJournalMode::Wal)
            .synchronous(SqliteSynchronous::Normal)
            .foreign_keys(true);
        let pool = SqlitePoolOptions::new()
            .max_connections(MAX_CONNECTIONS)
            .connect_with(options)
            .await?;
        sqlx::migrate!("./migrations").run(&pool).await?;
        Ok(Self { pool })
    }
}

impl Storage for SqliteStorage {
    async fn get_setting(&self, key: &str) -> Result<Option<String>> {
        let row: Option<(String,)> = sqlx::query_as("SELECT value FROM settings WHERE key = ?")
            .bind(key)
            .fetch_optional(&self.pool)
            .await?;
        Ok(row.map(|(v,)| v))
    }

    async fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        sqlx::query("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)")
            .bind(key)
            .bind(value)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn delete_setting(&self, key: &str) -> Result<()> {
        sqlx::query("DELETE FROM settings WHERE key = ?")
            .bind(key)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn save_relay(&self, relay: &RelayInfo) -> Result<()> {
        let data = serde_json::to_string(relay)?;
        sqlx::query("INSERT OR REPLACE INTO relays (url, data) VALUES (?, ?)")
            .bind(&relay.url)
            .bind(&data)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn delete_relay(&self, url: &str) -> Result<()> {
        sqlx::query("DELETE FROM relays WHERE url = ?")
            .bind(url)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn list_relays(&self) -> Result<Vec<RelayInfo>> {
        let rows: Vec<(String,)> = sqlx::query_as("SELECT data FROM relays")
            .fetch_all(&self.pool)
            .await?;
        Ok(rows
            .into_iter()
            .filter_map(|(data,)| match serde_json::from_str(&data) {
                Ok(relay) => Some(relay),
                Err(e) => {
                    log::warn!("[db] skipping unreadable relay row: {e}");
                    None
                }
            })
            .collect())
    }

    async fn save_node_picture(&self, pubkey: &str, url: &str, bytes: &[u8]) -> Result<()> {
        sqlx::query(
            "INSERT OR REPLACE INTO node_pictures (pubkey, url, data, fetched_at)
             VALUES (?, ?, ?, ?)",
        )
        .bind(pubkey)
        .bind(url)
        .bind(bytes)
        .bind(crate::rt::unix_now())
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn get_node_picture(&self, pubkey: &str) -> Result<Option<MostroNodePicture>> {
        let row: Option<(String, Vec<u8>)> =
            sqlx::query_as("SELECT url, data FROM node_pictures WHERE pubkey = ?")
                .bind(pubkey)
                .fetch_optional(&self.pool)
                .await?;
        Ok(row.map(|(url, bytes)| MostroNodePicture { url, bytes }))
    }

    async fn list_node_picture_urls(&self) -> Result<std::collections::HashMap<String, String>> {
        let rows: Vec<(String, String)> = sqlx::query_as("SELECT pubkey, url FROM node_pictures")
            .fetch_all(&self.pool)
            .await?;
        Ok(rows.into_iter().collect())
    }

    async fn delete_node_picture(&self, pubkey: &str) -> Result<()> {
        sqlx::query("DELETE FROM node_pictures WHERE pubkey = ?")
            .bind(pubkey)
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::db::contract;
    use std::sync::atomic::{AtomicU32, Ordering};

    /// A unique temp database path, so parallel tests never collide.
    pub(crate) fn temp_db_path() -> std::path::PathBuf {
        static COUNTER: AtomicU32 = AtomicU32::new(0);
        let n = COUNTER.fetch_add(1, Ordering::Relaxed);
        std::env::temp_dir().join(format!("bosstro_test_{}_{n}.db", std::process::id()))
    }

    pub(crate) async fn store() -> SqliteStorage {
        SqliteStorage::open(temp_db_path().to_str().unwrap())
            .await
            .unwrap()
    }

    #[tokio::test]
    async fn settings_round_trip() {
        contract::settings_round_trip(&store().await).await;
    }

    #[tokio::test]
    async fn active_node_is_absent_until_saved() {
        contract::active_node_is_absent_until_saved(&store().await).await;
    }

    #[tokio::test]
    async fn relays_round_trip() {
        contract::relays_round_trip(&store().await).await;
    }

    #[tokio::test]
    async fn node_pictures_round_trip() {
        contract::node_pictures_round_trip(&store().await).await;
    }

    /// What a restart sees: a second open of the same file finds the rows,
    /// and running the migrations again over an up-to-date schema is a no-op.
    #[tokio::test]
    async fn data_survives_a_reopen() {
        let path = temp_db_path();
        let path = path.to_str().unwrap();
        {
            let first = SqliteStorage::open(path).await.unwrap();
            first.save_active_mostro_pubkey("aa").await.unwrap();
            first.pool.close().await;
        }
        let second = SqliteStorage::open(path).await.unwrap();
        assert_eq!(
            second.get_active_mostro_pubkey().await.unwrap().as_deref(),
            Some("aa")
        );
    }

    /// A relay row written by a later version that this one cannot read is
    /// skipped, not fatal: the other relays still load.
    #[tokio::test]
    async fn an_unreadable_relay_row_is_skipped() {
        let storage = store().await;
        sqlx::query("INSERT INTO relays (url, data) VALUES ('wss://bad', '{not json')")
            .execute(&storage.pool)
            .await
            .unwrap();
        storage
            .save_relay(&contract::relay("wss://good.example"))
            .await
            .unwrap();
        let urls: Vec<String> = storage
            .list_relays()
            .await
            .unwrap()
            .into_iter()
            .map(|r| r.url)
            .collect();
        assert_eq!(urls, vec!["wss://good.example".to_string()]);
    }
}
