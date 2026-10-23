//! SQLite storage backend — native platforms only. From ../app's
//! `db/sqlite.rs`, trimmed to Bosstro's tables.
//!
//! The schema is versioned with `sqlx` migrations (`rust/migrations/`,
//! embedded at compile time): each file runs once, in order, and a later
//! phase adds a file instead of editing one.
use anyhow::Result;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions, SqliteSynchronous};
use sqlx::{Row, SqlitePool};

use crate::api::chat::ChatDelivery;
use crate::api::disputes::{DisputeInitiator, DisputeStatus};
use crate::api::nodes::MostroNodePicture;
use crate::api::relays::RelayInfo;
use crate::db::Storage;
use crate::chat::observer::{ObservedRecord, ObservedRef};
use crate::chat::{ChannelRef, ChatRecord};
use crate::disputes::{DisputeRecord, TakenDispute};

/// Every column of `disputes`, in the order [`dispute_from_row`] reads them.
const DISPUTE_COLUMNS: &str = "mostro_pubkey, dispute_id, status, initiator, opened_at, \
     expires_at, event_id, event_created_at, taken_at, order_id, order_kind, amount, \
     fiat_amount, fiat_code, payment_method, premium, fee, initiator_pubkey, buyer_pubkey, \
     seller_pubkey, solver_pubkey";

/// Every column of `dispute_messages`, in the order [`chat_from_row`] reads them.
const CHAT_COLUMNS: &str = "mostro_pubkey, dispute_id, party, solver_pubkey, message_id, \
     sender, content, created_at, received_at, delivery";

/// Every column of `observed_messages`, in the order [`observed_from_row`]
/// reads them.
const OBSERVED_COLUMNS: &str = "mostro_pubkey, dispute_id, solver_pubkey, message_id, sender, \
     content, created_at, received_at";

/// The condition that picks one channel's rows.
const CHANNEL_WHERE: &str =
    "mostro_pubkey = ? AND dispute_id = ? AND party = ? AND solver_pubkey = ?";

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
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
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
        .bind(t.map(|t| t.solver_pubkey.clone()))
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

    async fn list_disputes_with_status(
        &self,
        mostro_pubkey: &str,
        status: DisputeStatus,
    ) -> Result<Vec<DisputeRecord>> {
        // Served by `disputes_by_node_status`.
        let rows = sqlx::query(&format!(
            "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE mostro_pubkey = ? AND status = ?"
        ))
        .bind(mostro_pubkey)
        .bind(status.as_wire())
        .fetch_all(&self.pool)
        .await?;
        Ok(rows.iter().filter_map(readable_dispute).collect())
    }

    async fn insert_chat_message(&self, m: &ChatRecord) -> Result<bool> {
        let done = sqlx::query(&format!(
            "INSERT OR IGNORE INTO dispute_messages ({CHAT_COLUMNS})
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        ))
        .bind(&m.channel.mostro_pubkey)
        .bind(&m.channel.dispute_id)
        .bind(m.channel.party.as_wire())
        .bind(&m.channel.solver_pubkey)
        .bind(&m.message_id)
        .bind(m.sender.as_wire())
        .bind(&m.content)
        .bind(m.created_at)
        .bind(m.received_at)
        .bind(m.delivery.as_wire())
        .execute(&self.pool)
        .await?;
        Ok(done.rows_affected() > 0)
    }

    async fn get_chat_message(
        &self,
        channel: &ChannelRef,
        message_id: &str,
    ) -> Result<Option<ChatRecord>> {
        let row = bind_channel(
            sqlx::query(&format!(
                "SELECT {CHAT_COLUMNS} FROM dispute_messages WHERE {CHANNEL_WHERE} AND message_id = ?"
            )),
            channel,
        )
        .bind(message_id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row.as_ref().and_then(readable_chat))
    }

    async fn list_chat_messages(&self, channel: &ChannelRef) -> Result<Vec<ChatRecord>> {
        let rows = bind_channel(
            sqlx::query(&format!(
                "SELECT {CHAT_COLUMNS} FROM dispute_messages WHERE {CHANNEL_WHERE}"
            )),
            channel,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(rows.iter().filter_map(readable_chat).collect())
    }

    async fn set_chat_delivery(
        &self,
        channel: &ChannelRef,
        message_id: &str,
        delivery: ChatDelivery,
    ) -> Result<()> {
        sqlx::query(&format!(
            "UPDATE dispute_messages SET delivery = ? WHERE {CHANNEL_WHERE} AND message_id = ?"
        ))
        .bind(delivery.as_wire())
        .bind(&channel.mostro_pubkey)
        .bind(&channel.dispute_id)
        .bind(channel.party.as_wire())
        .bind(&channel.solver_pubkey)
        .bind(message_id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn delete_chat_message(&self, channel: &ChannelRef, message_id: &str) -> Result<()> {
        bind_channel(
            sqlx::query(&format!(
                "DELETE FROM dispute_messages WHERE {CHANNEL_WHERE} AND message_id = ?"
            )),
            channel,
        )
        .bind(message_id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn chat_cursor(&self, channel: &ChannelRef) -> Result<Option<i64>> {
        // Served by the primary key's prefix.
        let row: (Option<i64>,) = bind_channel_as(
            sqlx::query_as(&format!(
                "SELECT MAX(MIN(created_at, received_at)) FROM dispute_messages
                 WHERE {CHANNEL_WHERE}"
            )),
            channel,
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(row.0)
    }

    async fn insert_observed_message(&self, m: &ObservedRecord) -> Result<bool> {
        let done = sqlx::query(&format!(
            "INSERT OR IGNORE INTO observed_messages ({OBSERVED_COLUMNS})
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        ))
        .bind(&m.conversation.mostro_pubkey)
        .bind(&m.conversation.dispute_id)
        .bind(&m.conversation.solver_pubkey)
        .bind(&m.message_id)
        .bind(m.sender.as_wire())
        .bind(&m.content)
        .bind(m.created_at)
        .bind(m.received_at)
        .execute(&self.pool)
        .await?;
        Ok(done.rows_affected() > 0)
    }

    async fn list_observed_messages(&self, observed: &ObservedRef) -> Result<Vec<ObservedRecord>> {
        let rows = sqlx::query(&format!(
            "SELECT {OBSERVED_COLUMNS} FROM observed_messages
             WHERE mostro_pubkey = ? AND dispute_id = ? AND solver_pubkey = ?"
        ))
        .bind(&observed.mostro_pubkey)
        .bind(&observed.dispute_id)
        .bind(&observed.solver_pubkey)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows
            .iter()
            .filter_map(|row| match observed_from_row(row) {
                Ok(record) => Some(record),
                Err(e) => {
                    log::warn!("[db] skipping unreadable observed row: {e}");
                    None
                }
            })
            .collect())
    }

    async fn save_attachment_blob(&self, sha256: &str, blob: &[u8]) -> Result<()> {
        sqlx::query(
            "INSERT OR REPLACE INTO attachment_blobs (sha256, data, size, created_at)
             VALUES (?, ?, ?, ?)",
        )
        .bind(sha256)
        .bind(blob)
        .bind(blob.len() as i64)
        .bind(crate::rt::unix_now())
        .execute(&self.pool)
        .await?;
        self.trim_attachment_blobs(crate::db::blob_cache::ATTACHMENT_CACHE_BYTES)
            .await
    }

    async fn get_attachment_blob(&self, sha256: &str) -> Result<Option<Vec<u8>>> {
        let row: Option<(Vec<u8>,)> =
            sqlx::query_as("SELECT data FROM attachment_blobs WHERE sha256 = ?")
                .bind(sha256)
                .fetch_optional(&self.pool)
                .await?;
        Ok(row.map(|r| r.0))
    }

    /// The newest blobs stay, the oldest go (the row id breaks ties within
    /// a second), in one statement, as ../app.
    async fn trim_attachment_blobs(&self, cap: u64) -> Result<()> {
        sqlx::query(
            "DELETE FROM attachment_blobs WHERE sha256 IN (
                 SELECT sha256 FROM (
                     SELECT sha256,
                            SUM(size) OVER (ORDER BY created_at DESC, rowid DESC) AS running
                     FROM attachment_blobs
                 ) WHERE running > ?
             )",
        )
        .bind(i64::try_from(cap).unwrap_or(i64::MAX))
        .execute(&self.pool)
        .await?;
        Ok(())
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
            solver_pubkey: row
                .try_get::<Option<String>, _>("solver_pubkey")?
                .unwrap_or_default(),
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

type SqliteQuery<'q> = sqlx::query::Query<'q, sqlx::Sqlite, sqlx::sqlite::SqliteArguments<'q>>;
type SqliteQueryAs<'q, O> =
    sqlx::query::QueryAs<'q, sqlx::Sqlite, O, sqlx::sqlite::SqliteArguments<'q>>;

/// Bind [`CHANNEL_WHERE`]'s four values.
fn bind_channel<'q>(query: SqliteQuery<'q>, channel: &'q ChannelRef) -> SqliteQuery<'q> {
    query
        .bind(&channel.mostro_pubkey)
        .bind(&channel.dispute_id)
        .bind(channel.party.as_wire())
        .bind(&channel.solver_pubkey)
}

fn bind_channel_as<'q, O>(
    query: SqliteQueryAs<'q, O>,
    channel: &'q ChannelRef,
) -> SqliteQueryAs<'q, O> {
    query
        .bind(&channel.mostro_pubkey)
        .bind(&channel.dispute_id)
        .bind(channel.party.as_wire())
        .bind(&channel.solver_pubkey)
}

/// A message row as a record, or `None` (logged, without its content) when
/// it no longer reads.
fn readable_chat(row: &sqlx::sqlite::SqliteRow) -> Option<ChatRecord> {
    match chat_from_row(row) {
        Ok(record) => Some(record),
        Err(e) => {
            log::warn!("[db] skipping unreadable chat row: {e}");
            None
        }
    }
}

fn chat_from_row(row: &sqlx::sqlite::SqliteRow) -> Result<ChatRecord> {
    use crate::api::chat::{ChatParty, ChatSender};
    let party: String = row.try_get("party")?;
    let sender: String = row.try_get("sender")?;
    let delivery: String = row.try_get("delivery")?;
    Ok(ChatRecord {
        channel: ChannelRef {
            mostro_pubkey: row.try_get("mostro_pubkey")?,
            dispute_id: row.try_get("dispute_id")?,
            party: ChatParty::from_wire(&party)
                .ok_or_else(|| anyhow::anyhow!("unknown chat party {party:?}"))?,
            solver_pubkey: row.try_get("solver_pubkey")?,
        },
        message_id: row.try_get("message_id")?,
        sender: ChatSender::from_wire(&sender)
            .ok_or_else(|| anyhow::anyhow!("unknown chat sender {sender:?}"))?,
        content: row.try_get("content")?,
        created_at: row.try_get("created_at")?,
        received_at: row.try_get("received_at")?,
        delivery: ChatDelivery::from_wire(&delivery)
            .ok_or_else(|| anyhow::anyhow!("unknown chat delivery {delivery:?}"))?,
    })
}

fn observed_from_row(row: &sqlx::sqlite::SqliteRow) -> Result<ObservedRecord> {
    use crate::api::chat::ChatParty;
    let sender: String = row.try_get("sender")?;
    Ok(ObservedRecord {
        conversation: ObservedRef {
            mostro_pubkey: row.try_get("mostro_pubkey")?,
            dispute_id: row.try_get("dispute_id")?,
            solver_pubkey: row.try_get("solver_pubkey")?,
        },
        message_id: row.try_get("message_id")?,
        sender: ChatParty::from_wire(&sender)
            .ok_or_else(|| anyhow::anyhow!("unknown observed sender {sender:?}"))?,
        content: row.try_get("content")?,
        created_at: row.try_get("created_at")?,
        received_at: row.try_get("received_at")?,
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

    #[tokio::test]
    async fn disputes_by_status() {
        contract::disputes_by_status(&store().await).await;
    }

    #[tokio::test]
    async fn takes_keep_their_solver() {
        contract::takes_keep_their_solver(&store().await).await;
    }

    #[tokio::test]
    async fn chat_messages_round_trip() {
        contract::chat_messages_round_trip(&store().await).await;
    }

    #[tokio::test]
    async fn chat_channels_never_mix() {
        contract::chat_channels_never_mix(&store().await).await;
    }

    #[tokio::test]
    async fn the_chat_cursor_never_passes_the_clock_of_acceptance() {
        contract::the_chat_cursor_never_passes_the_clock_of_acceptance(&store().await).await;
    }

    #[tokio::test]
    async fn observed_messages_round_trip() {
        contract::observed_messages_round_trip(&store().await).await;
    }

    #[tokio::test]
    async fn observed_chats_never_mix_with_each_other_or_the_chat() {
        contract::observed_chats_never_mix_with_each_other_or_the_chat(&store().await).await;
    }

    #[tokio::test]
    async fn attachment_blobs_are_cached_and_bounded() {
        contract::attachment_blobs_are_cached_and_bounded(&store().await).await;
    }

    /// The Pending query uses the index, not a scan of the table.
    #[tokio::test]
    async fn the_pending_query_uses_the_status_index() {
        let storage = store().await;
        let plan: Vec<(i64, i64, i64, String)> = sqlx::query_as(
            "EXPLAIN QUERY PLAN SELECT dispute_id FROM disputes
             WHERE mostro_pubkey = 'aa' AND status = 'initiated'",
        )
        .fetch_all(&storage.pool)
        .await
        .unwrap();
        let detail = plan.iter().map(|r| r.3.as_str()).collect::<Vec<_>>().join(" | ");
        assert!(detail.contains("disputes_by_node_status"), "{detail}");
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
