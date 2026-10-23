//! Eviction for the attachment cache, from ../app's `db/blob_cache.rs`.
//!
//! SQLite trims its `attachment_blobs` table in one statement. IndexedDB has
//! no such query, so the web backend keeps a small index entry per blob and
//! asks this module which ones to drop. Kept apart from `indexeddb.rs`, which
//! compiles only for wasm, so the rule is tested with the native suite.

use serde::{Deserialize, Serialize};

/// Most bytes of encrypted attachments a device keeps, as ../app: a few
/// dozen full-size files, far more photos.
#[cfg_attr(target_arch = "wasm32", allow(dead_code))]
pub(crate) const ATTACHMENT_CACHE_BYTES: u64 = 300 * 1024 * 1024;

/// Most bytes a browser keeps, as ../app. Smaller than native's: the origin's
/// quota is shared with everything else the app stores, and a write over
/// quota fails the cache, never the download.
#[cfg_attr(not(target_arch = "wasm32"), allow(dead_code))]
pub(crate) const WEB_ATTACHMENT_CACHE_BYTES: u64 = 100 * 1024 * 1024;

/// What the index remembers of one cached blob.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub(crate) struct BlobEntry {
    pub sha256: String,
    pub size: u64,
    pub created_at: i64,
}

/// The blobs to evict so the rest fit in `cap` bytes: the newest stay, the
/// oldest go, as SQLite's trim. A miss only costs a download, so eviction is
/// always safe.
#[cfg_attr(not(any(test, target_arch = "wasm32")), allow(dead_code))]
pub(crate) fn blobs_to_evict(mut entries: Vec<BlobEntry>, cap: u64) -> Vec<String> {
    // Newest first; the hash breaks ties so the choice is deterministic.
    entries.sort_by(|a, b| {
        b.created_at
            .cmp(&a.created_at)
            .then_with(|| b.sha256.cmp(&a.sha256))
    });
    let mut running = 0u64;
    entries
        .into_iter()
        .filter_map(|entry| {
            running = running.saturating_add(entry.size);
            (running > cap).then_some(entry.sha256)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(sha256: &str, size: u64, created_at: i64) -> BlobEntry {
        BlobEntry {
            sha256: sha256.to_string(),
            size,
            created_at,
        }
    }

    #[test]
    fn the_oldest_blobs_go_once_the_cache_is_over_its_cap() {
        let entries = vec![
            entry("old", 10, 1),
            entry("mid", 10, 2),
            entry("new", 10, 3),
        ];
        assert_eq!(blobs_to_evict(entries, 25), vec!["old".to_string()]);
    }

    #[test]
    fn nothing_goes_while_the_cache_fits() {
        let entries = vec![entry("a", 10, 1), entry("b", 10, 2)];
        assert!(blobs_to_evict(entries, 20).is_empty());
    }

    #[test]
    fn a_blob_larger_than_the_cap_is_not_kept() {
        assert_eq!(
            blobs_to_evict(vec![entry("huge", 30, 5)], 25),
            vec!["huge".to_string()]
        );
    }
}
