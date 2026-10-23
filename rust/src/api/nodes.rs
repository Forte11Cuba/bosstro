//! The Mostro node registry and the active node (D5), from ../app's
//! `api/nodes.rs` and `api/settings.rs` (`set_active_mostro_node`).
//!
//! The registry merges three sources into [`MostroNodeEntry`] rows:
//!
//! 1. the compiled-in trusted registry (`crate::config::TRUSTED_MOSTRO_NODES`),
//! 2. nodes the solver added, persisted in the settings store,
//! 3. cached kind 0 display metadata (name, picture, about, website).
//!
//! Unlike ../app there is no default node: until the solver picks one,
//! [`active_node`] is `None` and nothing node-specific runs.
//!
//! Errors are stable markers (`PrivateKeyNotAllowed`, `InvalidPubkey`,
//! `NodeAlreadyExists`, `NodeIsTrusted`, `CannotRemoveActiveNode`,
//! `NotInitialized`), translated on the Dart side.
use anyhow::{bail, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::OnceLock;
use tokio::sync::Mutex;

use crate::db::{settings_keys, Storage};

/// A node as the selector shows it.
#[derive(Debug, Clone, PartialEq)]
pub struct MostroNodeEntry {
    /// Node pubkey, 64-char lowercase hex.
    pub pubkey: String,
    /// Region label (flag emoji + place name) for trusted nodes, `None` for
    /// the solver's own.
    pub region: Option<String>,
    /// From the compiled-in trusted registry.
    pub is_trusted: bool,
    /// The active node.
    pub is_active: bool,
    /// Display name: the solver's (custom nodes) or from kind 0.
    pub name: Option<String>,
    /// Avatar URL from kind 0 (https only; anything else is dropped).
    pub picture: Option<String>,
    /// Operator description from kind 0.
    pub about: Option<String>,
    /// Website URL from kind 0 (https only).
    pub website: Option<String>,
}

/// A node's kind 0 picture as the device keeps it (`crate::node_pictures`):
/// the bytes as downloaded and the URL they came from, so the UI shows them
/// only while the profile still names that URL.
#[derive(Debug, Clone, PartialEq)]
pub struct MostroNodePicture {
    pub url: String,
    pub bytes: Vec<u8>,
}

/// Serializes every load-modify-save cycle on the registry's settings blobs
/// and the active-node write, as in ../app: the blobs are written whole, so
/// two concurrent cycles would drop one side's update, and a removal must
/// not interleave with a selection of the same node. Never held across a
/// relay round trip.
static REGISTRY_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn registry_lock() -> &'static Mutex<()> {
    REGISTRY_LOCK.get_or_init(|| Mutex::new(()))
}

// ── Persisted shapes ─────────────────────────────────────────────────────────

/// A node the solver added, as persisted under
/// [`settings_keys::CUSTOM_MOSTRO_NODES`].
#[flutter_rust_bridge::frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct CustomNode {
    /// 64-char lowercase hex.
    pub pubkey: String,
    /// Optional name the solver gave it (wins over kind 0).
    pub name: Option<String>,
    /// Unix seconds when it was added.
    pub added_at: i64,
}

/// Cached kind 0 profile fields, under
/// [`settings_keys::MOSTRO_NODE_METADATA`] as a pubkey → metadata map.
#[flutter_rust_bridge::frb(ignore)]
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub(crate) struct NodeMetadata {
    pub name: Option<String>,
    pub picture: Option<String>,
    pub about: Option<String>,
    pub website: Option<String>,
}

// ── Pure helpers ─────────────────────────────────────────────────────────────

/// Normalize `input` (64-char hex or `npub1…`, optionally `nostr:`-prefixed)
/// to lowercase hex.
fn parse_node_pubkey(input: &str) -> Result<String> {
    let trimmed = input.trim();
    let trimmed = trimmed.strip_prefix("nostr:").unwrap_or(trimmed);
    if trimmed.to_ascii_lowercase().starts_with("nsec") {
        bail!("PrivateKeyNotAllowed: expected a public key, got an nsec");
    }
    let pk = nostr_sdk::prelude::PublicKey::parse(trimmed)
        .map_err(|e| anyhow::anyhow!("InvalidPubkey: {e}"))?;
    Ok(pk.to_hex())
}

/// Keep only https URLs: a kind 0 event is attacker-controlled input, and
/// `picture` is downloaded and shown.
fn sanitize_https_url(url: Option<String>) -> Option<String> {
    url.map(|u| u.trim().to_string())
        .filter(|u| u.starts_with("https://"))
}

/// Trimmed, `None` when blank.
fn normalize_text(text: Option<String>) -> Option<String> {
    text.map(|n| n.trim().to_string()).filter(|n| !n.is_empty())
}

fn is_trusted_pubkey(pubkey: &str) -> bool {
    crate::config::TRUSTED_MOSTRO_NODES
        .iter()
        .any(|n| n.pubkey == pubkey)
}

/// The trusted registry in the order the solver sees it: ../app's default
/// node ("Mostro") first, then the communities in registry order.
fn trusted_in_display_order() -> Vec<&'static crate::config::TrustedNodeConfig> {
    let nodes = crate::config::TRUSTED_MOSTRO_NODES;
    nodes
        .iter()
        .filter(|n| n.pubkey == crate::config::DEFAULT_MOSTRO_PUBKEY)
        .chain(
            nodes
                .iter()
                .filter(|n| n.pubkey != crate::config::DEFAULT_MOSTRO_PUBKEY),
        )
        .collect()
}

/// Drop custom entries whose pubkey has since joined the trusted registry,
/// which would otherwise stay as an undeletable duplicate (../app). Returns
/// whether anything was removed.
fn drop_promoted_customs(custom: &mut Vec<CustomNode>) -> bool {
    let before = custom.len();
    custom.retain(|n| !is_trusted_pubkey(&n.pubkey));
    custom.len() != before
}

/// Whether the active node is in neither list and must be shown as a custom
/// node, so the selector never hides the node in use.
fn needs_auto_import(custom: &[CustomNode], active: Option<&str>) -> bool {
    active.is_some_and(|a| !is_trusted_pubkey(a) && !custom.iter().any(|n| n.pubkey == a))
}

fn entry_from(
    pubkey: &str,
    region: Option<&str>,
    is_trusted: bool,
    custom_name: Option<&str>,
    meta: Option<&NodeMetadata>,
    active: Option<&str>,
) -> MostroNodeEntry {
    MostroNodeEntry {
        pubkey: pubkey.to_string(),
        region: region.map(str::to_string),
        is_trusted,
        is_active: active == Some(pubkey),
        name: custom_name
            .map(str::to_string)
            .or_else(|| meta.and_then(|m| m.name.clone())),
        picture: meta.and_then(|m| m.picture.clone()),
        about: meta.and_then(|m| m.about.clone()),
        website: meta.and_then(|m| m.website.clone()),
    }
}

fn build_entries(
    custom: &[CustomNode],
    cache: &HashMap<String, NodeMetadata>,
    active: Option<&str>,
) -> Vec<MostroNodeEntry> {
    let mut entries: Vec<MostroNodeEntry> = trusted_in_display_order()
        .into_iter()
        .map(|n| entry_from(n.pubkey, Some(n.region), true, None, cache.get(n.pubkey), active))
        .collect();
    entries.extend(custom.iter().map(|n| {
        entry_from(
            &n.pubkey,
            None,
            false,
            n.name.as_deref(),
            cache.get(&n.pubkey),
            active,
        )
    }));
    entries
}

// ── Settings persistence ─────────────────────────────────────────────────────

async fn load_custom_nodes(db: &impl Storage) -> Result<Vec<CustomNode>> {
    match db.get_setting(settings_keys::CUSTOM_MOSTRO_NODES).await? {
        // A corrupt blob loses the custom list, not the whole selector.
        Some(json) => Ok(serde_json::from_str(&json).unwrap_or_default()),
        None => Ok(Vec::new()),
    }
}

async fn save_custom_nodes(db: &impl Storage, nodes: &[CustomNode]) -> Result<()> {
    db.set_setting(
        settings_keys::CUSTOM_MOSTRO_NODES,
        &serde_json::to_string(nodes)?,
    )
    .await
}

async fn load_metadata_cache(db: &impl Storage) -> Result<HashMap<String, NodeMetadata>> {
    match db.get_setting(settings_keys::MOSTRO_NODE_METADATA).await? {
        Some(json) => Ok(serde_json::from_str(&json).unwrap_or_default()),
        None => Ok(HashMap::new()),
    }
}

async fn save_metadata_cache(
    db: &impl Storage,
    cache: &HashMap<String, NodeMetadata>,
) -> Result<()> {
    db.set_setting(
        settings_keys::MOSTRO_NODE_METADATA,
        &serde_json::to_string(cache)?,
    )
    .await
}

/// The registry against `db`, with the cleanups ../app runs on every read.
async fn list_in(db: &impl Storage, active: Option<&str>) -> Result<Vec<MostroNodeEntry>> {
    let custom = {
        let _guard = registry_lock().lock().await;
        let mut custom = load_custom_nodes(db).await?;
        let mut changed = drop_promoted_customs(&mut custom);
        if let Some(active) = active.filter(|_| needs_auto_import(&custom, active)) {
            custom.push(CustomNode {
                pubkey: active.to_string(),
                name: None,
                added_at: crate::rt::unix_now(),
            });
            changed = true;
        }
        if changed {
            save_custom_nodes(db, &custom).await?;
        }
        custom
    };
    let cache = load_metadata_cache(db).await?;
    Ok(build_entries(&custom, &cache, active))
}

async fn add_in(db: &impl Storage, input: &str, name: Option<String>) -> Result<String> {
    let pubkey = parse_node_pubkey(input)?;
    if is_trusted_pubkey(&pubkey) {
        bail!("NodeAlreadyExists: {pubkey} is a trusted node");
    }
    let _guard = registry_lock().lock().await;
    let mut custom = load_custom_nodes(db).await?;
    if custom.iter().any(|n| n.pubkey == pubkey) {
        bail!("NodeAlreadyExists: {pubkey} was already added");
    }
    custom.push(CustomNode {
        pubkey: pubkey.clone(),
        name: normalize_text(name),
        added_at: crate::rt::unix_now(),
    });
    save_custom_nodes(db, &custom).await?;
    Ok(pubkey)
}

async fn remove_in(db: &impl Storage, pubkey: &str) -> Result<()> {
    let pubkey = pubkey.to_lowercase();
    if is_trusted_pubkey(&pubkey) {
        bail!("NodeIsTrusted: compiled-in nodes cannot be removed");
    }
    let _guard = registry_lock().lock().await;
    // Under the lock: selection holds it too, so the key cannot become active
    // between this check and the save below.
    if crate::config::active_mostro_pubkey().as_deref() == Some(pubkey.as_str()) {
        bail!("CannotRemoveActiveNode: select another node first");
    }
    let mut custom = load_custom_nodes(db).await?;
    custom.retain(|n| n.pubkey != pubkey);
    save_custom_nodes(db, &custom).await
}

// ── Public API: the registry ─────────────────────────────────────────────────

/// The registry: "Mostro" (../app's default node) first, the other trusted
/// communities in registry order, then the solver's own nodes in the order
/// they were added, each merged with cached kind 0 metadata.
///
/// An active node in neither list is auto-imported as a custom node, so the
/// selector always shows the node in use.
pub async fn list_mostro_nodes() -> Result<Vec<MostroNodeEntry>> {
    let active = crate::config::active_mostro_pubkey();
    match crate::db::app_db::db() {
        Some(db) => list_in(db, active.as_deref()).await,
        None => {
            let custom: Vec<CustomNode> = active
                .iter()
                .filter(|a| needs_auto_import(&[], Some(a.as_str())))
                .map(|a| CustomNode {
                    pubkey: a.clone(),
                    name: None,
                    added_at: 0,
                })
                .collect();
            Ok(build_entries(&custom, &HashMap::new(), active.as_deref()))
        }
    }
}

/// Add a node by pubkey (64-char hex or `npub1…`) with an optional name, and
/// return its registry entry.
///
/// **Errors**: `PrivateKeyNotAllowed`, `InvalidPubkey`, `NodeAlreadyExists`
/// (already trusted or already added), `NotInitialized` (no storage).
pub async fn add_custom_mostro_node(
    input: String,
    name: Option<String>,
) -> Result<MostroNodeEntry> {
    let Some(db) = crate::db::app_db::db() else {
        parse_node_pubkey(&input)?;
        bail!("NotInitialized: storage is not ready");
    };
    let pubkey = add_in(db, &input, name).await?;
    let entries = list_in(db, crate::config::active_mostro_pubkey().as_deref()).await?;
    entries
        .into_iter()
        .find(|e| e.pubkey == pubkey)
        .ok_or_else(|| anyhow::anyhow!("NotInitialized: the node was not stored"))
}

/// Remove a node the solver added. Removing an absent node is a no-op.
///
/// **Errors**: `CannotRemoveActiveNode`, `NodeIsTrusted`, `NotInitialized`.
pub async fn remove_custom_mostro_node(pubkey: String) -> Result<()> {
    let Some(db) = crate::db::app_db::db() else {
        bail!("NotInitialized: storage is not ready");
    };
    remove_in(db, &pubkey).await
}

/// Fetch the kind 0 profile of every known node in one relay query, update
/// the cached metadata and return the refreshed registry.
///
/// Best effort: whatever arrives within 10 s is cached, nodes without a kind
/// 0 keep what they had, and only an outright query failure is an error
/// (the cache is then untouched).
pub async fn refresh_mostro_node_metadata() -> Result<Vec<MostroNodeEntry>> {
    use nostr_sdk::prelude::*;

    let client = crate::api::relays::pool()?.client();

    let mut pubkeys: Vec<String> = crate::config::TRUSTED_MOSTRO_NODES
        .iter()
        .map(|n| n.pubkey.to_string())
        .collect();
    if let Some(db) = crate::db::app_db::db() {
        pubkeys.extend(load_custom_nodes(db).await?.into_iter().map(|n| n.pubkey));
    }
    pubkeys.extend(crate::config::active_mostro_pubkey());
    pubkeys.sort();
    pubkeys.dedup();
    let authors: Vec<PublicKey> = pubkeys
        .iter()
        .filter_map(|p| PublicKey::from_hex(p).ok())
        .collect();

    let events = client
        .fetch_events(Filter::new().kind(Kind::Metadata).authors(authors))
        .timeout(std::time::Duration::from_secs(10))
        .await
        .map_err(|e| anyhow::anyhow!("fetch_events failed: {e}"))?;

    if let Some(db) = crate::db::app_db::db() {
        let _guard = registry_lock().lock().await;
        let mut cache = load_metadata_cache(db).await?;
        // Newest first; the first per author wins, so profile edits land.
        let mut events: Vec<Event> = events.into_iter().collect();
        events.sort_by_key(|e| std::cmp::Reverse(e.created_at));
        let mut seen = std::collections::HashSet::new();
        for event in events {
            let author = event.pubkey.to_hex();
            if !pubkeys.contains(&author) || !seen.insert(author.clone()) {
                continue;
            }
            let Ok(meta) = Metadata::from_json(&event.content) else {
                continue;
            };
            cache.insert(
                author,
                NodeMetadata {
                    name: normalize_text(meta.name.or(meta.display_name)),
                    picture: sanitize_https_url(meta.picture),
                    about: normalize_text(meta.about),
                    website: sanitize_https_url(meta.website),
                },
            );
        }
        save_metadata_cache(db, &cache).await?;
    }

    list_mostro_nodes().await
}

/// Download the picture of every node whose profile names a new one, and
/// drop the pictures no node names any more. Returns the pubkeys whose
/// stored picture changed, for the UI to read again; empty without storage.
pub async fn sync_mostro_node_pictures() -> Result<Vec<String>> {
    let Some(db) = crate::db::app_db::db() else {
        return Ok(Vec::new());
    };
    let nodes = list_mostro_nodes().await?;
    crate::node_pictures::sync(db, &nodes).await
}

/// `pubkey`'s picture as the device keeps it, or `None`.
pub async fn get_mostro_node_picture(pubkey: String) -> Result<Option<MostroNodePicture>> {
    let Some(db) = crate::db::app_db::db() else {
        return Ok(None);
    };
    db.get_node_picture(&pubkey.to_lowercase()).await
}

/// Drop `pubkey`'s stored picture, for bytes the UI could not decode; the
/// next [`sync_mostro_node_pictures`] downloads it again.
pub async fn forget_mostro_node_picture(pubkey: String) -> Result<()> {
    let Some(db) = crate::db::app_db::db() else {
        return Ok(());
    };
    db.delete_node_picture(&pubkey.to_lowercase()).await
}

// ── Public API: the active node (D5) ─────────────────────────────────────────

/// The active node (hex), or `None` until the solver picks one.
#[flutter_rust_bridge::frb(sync)]
pub fn active_node() -> Option<String> {
    crate::config::active_mostro_pubkey()
}

/// Load the persisted active node into memory and return it. Call once at
/// startup, after `init_db` and before `initialize_relays`. `None` when the
/// solver has not chosen one (or there is no storage).
pub async fn rehydrate_active_node() -> Result<Option<String>> {
    if let Some(db) = crate::db::app_db::db() {
        if let Some(pubkey) = db.get_active_mostro_pubkey().await? {
            crate::config::set_active_mostro_pubkey(Some(pubkey));
        }
    }
    Ok(crate::config::active_mostro_pubkey())
}

/// Make `pubkey` (hex or `npub1…`) the active node: persist it, switch to it
/// in memory, and read its relay list and instance info in the background.
///
/// **Errors**: `PrivateKeyNotAllowed`, `InvalidPubkey`, or a storage
/// failure (the active node is then unchanged).
pub async fn select_active_node(pubkey: String) -> Result<()> {
    let pubkey = parse_node_pubkey(&pubkey)?;
    {
        // Same lock as the registry: a concurrent removal of this node cannot
        // pass its is-active check and then drop it.
        let _guard = registry_lock().lock().await;
        if let Some(db) = crate::db::app_db::db() {
            db.save_active_mostro_pubkey(&pubkey).await?;
        }
        crate::config::set_active_mostro_pubkey(Some(pubkey));
    }
    crate::rt::spawn(refresh_active_node());
    // The disputes feed follows the new node (it reads the active node when
    // it runs, so two quick selections end on the last one).
    crate::rt::spawn(crate::disputes::feed::follow_active_node());
    Ok(())
}

/// Read the active node's kind 10002 relay list (adding the relays it
/// announces) and its kind 38385 instance info (cached). Runs after a
/// selection and whenever the relay pool comes online; a no-op without an
/// active node or a pool. Best effort: failures are logged.
pub(crate) async fn refresh_active_node() {
    let Some(node) = crate::config::active_mostro_pubkey() else {
        return;
    };
    if let Err(e) = sync_node_relay_list(&node).await {
        log::warn!("[node] relay list not read: {e}");
    }
    if let Err(e) = crate::api::node_info::fetch_node_info(node).await {
        log::warn!("[node] instance info not read: {e}");
    }
}

/// Fetch `node`'s newest kind 10002 event and add the relays it announces.
async fn sync_node_relay_list(node: &str) -> Result<()> {
    use futures_util::StreamExt;
    use nostr_sdk::prelude::*;

    let author = PublicKey::from_hex(node)?;
    let client = crate::api::relays::pool()?.client();
    let stream = client
        .stream_events(crate::nostr::relay_list::relay_list_filter(&author))
        .timeout(std::time::Duration::from_secs(10))
        .await
        .map_err(|e| anyhow::anyhow!("stream_events failed: {e}"))?;
    // A relay may answer with anyone's event: only the node's own counts.
    let own = stream.filter_map(move |(_, item)| async move {
        item.ok()
            .filter(|e| e.pubkey == author && e.verify().is_ok())
    });
    let Some(event) = crate::nostr::first_answer::newest_answer(
        Box::pin(own),
        std::time::Duration::from_millis(750),
        crate::nostr::first_answer::replaceable_rank,
    )
    .await
    else {
        return Ok(());
    };
    // The active node may have changed while the relays answered.
    if crate::config::active_mostro_pubkey().as_deref() != Some(node) {
        return Ok(());
    }
    let announced = crate::nostr::relay_list::parse_relay_list(&event);
    crate::api::relays::apply_relay_list(node, &announced).await;
    Ok(())
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::db::sqlite::tests::store;

    const DEFAULT: &str = crate::config::DEFAULT_MOSTRO_PUBKEY;
    /// Valid hex that is no real node.
    const OTHER: &str = "0000000000000000000000000000000000000000000000000000000000000001";

    #[test]
    fn parse_accepts_hex_npub_and_nostr_uri_and_normalizes_case() {
        use nostr_sdk::prelude::ToBech32;
        assert_eq!(parse_node_pubkey(&DEFAULT.to_uppercase()).unwrap(), DEFAULT);
        let npub = nostr_sdk::prelude::PublicKey::from_hex(DEFAULT)
            .unwrap()
            .to_bech32()
            .unwrap();
        assert_eq!(parse_node_pubkey(&npub).unwrap(), DEFAULT);
        assert_eq!(parse_node_pubkey(&format!(" nostr:{npub} ")).unwrap(), DEFAULT);
    }

    #[test]
    fn parse_rejects_an_nsec_and_garbage_with_markers() {
        let err = parse_node_pubkey("nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq").unwrap_err();
        assert!(err.to_string().starts_with("PrivateKeyNotAllowed"));
        let err = parse_node_pubkey("not-a-key").unwrap_err();
        assert!(err.to_string().starts_with("InvalidPubkey"));
        // Text with accents must not crash the parser (phase 1 rule).
        assert!(parse_node_pubkey("nodo de Pérez…").is_err());
    }

    #[test]
    fn sanitize_keeps_https_only() {
        assert_eq!(
            sanitize_https_url(Some(" https://x.com/a.png ".into())).as_deref(),
            Some("https://x.com/a.png")
        );
        assert_eq!(sanitize_https_url(Some("http://x.com/a.png".into())), None);
        assert_eq!(sanitize_https_url(Some("javascript:alert(1)".into())), None);
    }

    #[test]
    fn mostro_comes_first_then_the_communities_then_the_solvers_nodes() {
        let custom = vec![CustomNode {
            pubkey: OTHER.into(),
            name: Some("Mine".into()),
            added_at: 0,
        }];
        let entries = build_entries(&custom, &HashMap::new(), None);
        assert_eq!(entries[0].pubkey, DEFAULT);
        assert_eq!(entries.len(), crate::config::TRUSTED_MOSTRO_NODES.len() + 1);
        assert!(entries[..entries.len() - 1].iter().all(|e| e.is_trusted));
        let last = entries.last().unwrap();
        assert_eq!(last.pubkey, OTHER);
        assert!(!last.is_trusted);
        assert_eq!(last.name.as_deref(), Some("Mine"));
        // No node is active until the solver picks one.
        assert!(entries.iter().all(|e| !e.is_active));
    }

    #[test]
    fn the_solvers_name_wins_over_kind0() {
        let meta = NodeMetadata {
            name: Some("Kind0".into()),
            ..Default::default()
        };
        let e = entry_from(OTHER, None, false, Some("Mine"), Some(&meta), None);
        assert_eq!(e.name.as_deref(), Some("Mine"));
        let e = entry_from(OTHER, None, false, None, Some(&meta), Some(OTHER));
        assert_eq!(e.name.as_deref(), Some("Kind0"));
        assert!(e.is_active);
    }

    #[test]
    fn auto_import_only_for_an_unknown_active_node() {
        assert!(!needs_auto_import(&[], None));
        assert!(!needs_auto_import(&[], Some(DEFAULT)));
        assert!(needs_auto_import(&[], Some(OTHER)));
        let custom = vec![CustomNode {
            pubkey: OTHER.into(),
            name: None,
            added_at: 0,
        }];
        assert!(!needs_auto_import(&custom, Some(OTHER)));
    }

    #[tokio::test]
    async fn add_list_and_remove_a_custom_node_in_storage() {
        let db = store().await;
        let pubkey = add_in(&db, OTHER, Some("  My node ".into())).await.unwrap();
        assert_eq!(pubkey, OTHER);

        let err = add_in(&db, OTHER, None).await.unwrap_err();
        assert!(err.to_string().starts_with("NodeAlreadyExists"));
        let err = add_in(&db, DEFAULT, None).await.unwrap_err();
        assert!(err.to_string().starts_with("NodeAlreadyExists"));

        let entries = list_in(&db, None).await.unwrap();
        let mine = entries.iter().find(|e| e.pubkey == OTHER).unwrap();
        assert_eq!(mine.name.as_deref(), Some("My node"));

        let err = remove_in(&db, DEFAULT).await.unwrap_err();
        assert!(err.to_string().starts_with("NodeIsTrusted"));
        remove_in(&db, OTHER).await.unwrap();
        assert!(list_in(&db, None).await.unwrap().iter().all(|e| e.pubkey != OTHER));
    }

    /// An active node the registry does not hold is imported and persisted,
    /// so it survives the solver switching away from it.
    #[tokio::test]
    async fn an_unknown_active_node_is_imported_into_storage() {
        let db = store().await;
        let entries = list_in(&db, Some(OTHER)).await.unwrap();
        let active: Vec<_> = entries.iter().filter(|e| e.is_active).collect();
        assert_eq!(active.len(), 1);
        assert_eq!(active[0].pubkey, OTHER);
        assert_eq!(load_custom_nodes(&db).await.unwrap().len(), 1);
    }

    /// A corrupt registry blob costs the custom list, not the selector.
    #[tokio::test]
    async fn a_corrupt_custom_list_still_lists_the_trusted_nodes() {
        let db = store().await;
        db.set_setting(settings_keys::CUSTOM_MOSTRO_NODES, "{oops")
            .await
            .unwrap();
        let entries = list_in(&db, None).await.unwrap();
        assert_eq!(entries.len(), crate::config::TRUSTED_MOSTRO_NODES.len());
    }
}
