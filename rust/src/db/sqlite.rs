//! SQLite storage backend — native platforms only. From ../app's
//! `db/sqlite.rs`, trimmed to Bosstro's tables.
//!
//! The schema is versioned with `sqlx` migrations (`rust/migrations/`,
//! embedded at compile time): each file runs once, in order, and a later
//! phase adds a file instead of editing one.
use anyhow::Result;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions, SqliteSynchronous};
use sqlx::{Row, SqlitePool};

use crate::api::disputes::{DisputeInitiator, DisputeStatus};
use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;
use crate::db::Storage;
use crate::disputes::{DisputeRecord, TakenDispute};

/// Every column of `disputes`, in the order [`dispute_from_row`] reads them.
const DISPUTE_COLUMNS: &str = "mostro_pubkey, dispute_id, status, initiator, opened_at, \
     expires_at, event_id, event_created_at, taken_at, order_id, order_kind, amount, \
     fiat_amount, fiat_code, payment_method, premium, fee, initiator_pubkey, buyer_pubkey, \
     seller_pubkey";

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

    async fn save_dispute(&self, d: &DisputeRecord) -> Result<()> {
        let t = d.taken.as_ref();
        sqlx::query(&format!(
            "INSERT OR REPLACE INTO disputes ({DISPUTE_COLUMNS})
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        ))
        .bind(&d.mostro_pubkey)
        .bind(&d.dispute_id)
        .bind(d.status.as_wire())
        .bind(d.initiator.as_wire())
        .bind(d.opened_at)
        .bind(d.expires_at)
        .bind(&d.event_id)
        .bind(d.event_created_at)
        .bind(t.map(|t| t.taken_at))
        .bind(t.and_then(|t| t.order_id.clone()))
        .bind(t.and_then(|t| t.order_kind.clone()))
        .bind(t.and_then(|t| t.amount))
        .bind(t.and_then(|t| t.fiat_amount))
        .bind(t.and_then(|t| t.fiat_code.clone()))
        .bind(t.and_then(|t| t.payment_method.clone()))
        .bind(t.and_then(|t| t.premium))
        .bind(t.and_then(|t| t.fee))
        .bind(t.and_then(|t| t.initiator_pubkey.clone()))
        .bind(t.and_then(|t| t.buyer_pubkey.clone()))
        .bind(t.and_then(|t| t.seller_pubkey.clone()))
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn get_dispute(
        &self,
        mostro_pubkey: &str,
        dispute_id: &str,
    ) -> Result<Option<DisputeRecord>> {
        let row = sqlx::query(&format!(
            "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE mostro_pubkey = ? AND dispute_id = ?"
        ))
        .bind(mostro_pubkey)
        .bind(dispute_id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row.as_ref().and_then(readable_dispute))
    }

    async fn list_disputes(&self, mostro_pubkey: &str) -> Result<Vec<DisputeRecord>> {
        let rows = sqlx::query(&format!(
            "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE mostro_pubkey = ?"
        ))
        .bind(mostro_pubkey)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows.iter().filter_map(readable_dispute).collect())
    }
}

/// A row as a record, or `None` (logged) when it no longer reads — a status a
/// later version wrote, say: the other rows still load.
fn readable_dispute(row: &sqlx::sqlite::SqliteRow) -> Option<DisputeRecord> {
    match dispute_from_row(row) {
        Ok(record) => Some(record),
        Err(e) => {
            log::warn!("[db] skipping unreadable dispute row: {e}");
            None
        }
    }
}

fn dispute_from_row(row: &sqlx::sqlite::SqliteRow) -> Result<DisputeRecord> {
    let status: String = row.try_get("status")?;
    let initiator: String = row.try_get("initiator")?;
    let taken_at: Option<i64> = row.try_get("taken_at")?;
    let taken = match taken_at {
        Some(taken_at) => Some(TakenDispute {
            taken_at,
            order_id: row.try_get("order_id")?,
            order_kind: row.try_get("order_kind")?,
            amount: row.try_get("amount")?,
            fiat_amount: row.try_get("fiat_amount")?,
            fiat_code: row.try_get("fiat_code")?,
            payment_method: row.try_get("payment_method")?,
            premium: row.try_get("premium")?,
            fee: row.try_get("fee")?,
            initiator_pubkey: row.try_get("initiator_pubkey")?,
            buyer_pubkey: row.try_get("buyer_pubkey")?,
            seller_pubkey: row.try_get("seller_pubkey")?,
        }),
        None => None,
    };
    Ok(DisputeRecord {
        mostro_pubkey: row.try_get("mostro_pubkey")?,
        dispute_id: row.try_get("dispute_id")?,
        status: DisputeStatus::from_wire(&status)
            .ok_or_else(|| anyhow::anyhow!("unknown dispute status {status:?}"))?,
        initiator: DisputeInitiator::from_wire(&initiator),
        opened_at: row.try_get("opened_at")?,
        expires_at: row.try_get("expires_at")?,
        event_id: row.try_get("event_id")?,
        event_created_at: row.try_get("event_created_at")?,
        taken,
    })
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

    #[tokio::test]
    async fn disputes_round_trip() {
        contract::disputes_round_trip(&store().await).await;
    }

    #[tokio::test]
    async fn disputes_never_mix_nodes() {
        contract::disputes_never_mix_nodes(&store().await).await;
    }

    /// A dispute row with a status this version does not know (written by a
    /// later one) is skipped; the others still load.
    #[tokio::test]
    async fn an_unreadable_dispute_row_is_skipped() {
        let storage = store().await;
        let good = contract::dispute("aa", contract::DISPUTE_A);
        storage.save_dispute(&good).await.unwrap();
        sqlx::query(
            "INSERT INTO disputes (mostro_pubkey, dispute_id, status, initiator, event_id,
             event_created_at) VALUES ('aa', 'x', 'escalated', 'buyer', 'e', 1)",
        )
        .execute(&storage.pool)
        .await
        .unwrap();
        assert_eq!(storage.list_disputes("aa").await.unwrap(), vec![good]);
        assert_eq!(storage.get_dispute("aa", "x").await.unwrap(), None);
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
