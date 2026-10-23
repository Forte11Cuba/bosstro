//! Global persistent-storage singleton, as in ../app.
//!
//! Dart calls [`init_db`] once on startup with the platform's location. Every
//! Rust function that needs persistence calls [`db()`]; before [`init_db`]
//! succeeded (unit tests, early startup, a failed open) it returns `None` and
//! the caller works from memory.
use anyhow::Result;
use tokio::sync::OnceCell;

#[cfg(target_arch = "wasm32")]
use crate::db::indexeddb::IndexedDbStorage as AppStorage;
#[cfg(not(target_arch = "wasm32"))]
use crate::db::sqlite::SqliteStorage as AppStorage;

static APP_DB: OnceCell<AppStorage> = OnceCell::const_new();

/// Open the persistent store at `path`.
///
/// On native platforms `path` is the absolute path to the SQLite file; on the
/// web it names the IndexedDB database. Later calls are no-ops.
pub async fn init_db(path: &str) -> Result<()> {
    APP_DB
        .get_or_try_init(|| async { AppStorage::open(path).await })
        .await?;
    log::info!("[db] persistent store ready");
    Ok(())
}

/// The opened store, or `None` before [`init_db`] succeeded.
pub(crate) fn db() -> Option<&'static AppStorage> {
    APP_DB.get()
}
