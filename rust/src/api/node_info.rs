//! A node's instance info: its kind 38385 event, as Mostrix's Mostro Info tab
//! reads and shows it (`src/util/mostro_info.rs`, `src/ui/tabs/mostro_info_tab.rs`).
//!
//! The event is addressable and authored by the node; relays are not trusted
//! (Mostrix MOSTRO-075), so a copy is used only when its author is the node,
//! its `d` tag is the node's pubkey and its signature verifies. The newest
//! authentic copy is cached per node in the settings store (D6) and served
//! until a newer one arrives: a fetch that finds nothing, or only forgeries,
//! keeps the cache, as Mostrix does.
use anyhow::Result;
use nostr_sdk::prelude::*;

use crate::db::{settings_keys, Storage};

/// Nostr kind of Mostro instance status events.
pub(crate) const MOSTRO_INSTANCE_INFO_KIND: u16 = 38385;

/// Age after which the info is called stale: 7 days, as Mostrix.
const STALE_AFTER_SECS: i64 = 604_800;

/// How long a fetch waits for relays, and how long it keeps listening after
/// the first copy in case that relay held a stale one (../app).
const FETCH_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);
const FETCH_GRACE: std::time::Duration = std::time::Duration::from_millis(750);

/// Which wire protocol the node speaks, against Bosstro's (transport v2 only).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ProtocolSupport {
    /// `protocol_version` 2: what Bosstro speaks.
    Supported,
    /// `protocol_version` 1 (GiftWrap) or anything else: Bosstro cannot
    /// talk to this node.
    Unsupported,
    /// The node does not say.
    #[default]
    Unknown,
}

/// The fields of a node's kind 38385 event, as Mostrix's `MostroInstanceInfo`.
/// Every tag is optional: a field is `None` (or empty) when the node omits it.
/// Values are as the node publishes them; Dart formats them.
#[derive(Debug, Clone, PartialEq, Default)]
pub struct NodeInfo {
    /// The node (hex).
    pub pubkey: String,
    /// `created_at` of the event (unix seconds).
    pub last_updated: i64,
    /// Older than 7 days (Mostrix shows a warning).
    pub is_stale: bool,
    /// `y` tag's third element, the instance name.
    pub name: Option<String>,
    pub mostro_version: Option<String>,
    pub mostro_commit_hash: Option<String>,
    pub max_order_amount: Option<i64>,
    pub min_order_amount: Option<i64>,
    pub expiration_hours: Option<i64>,
    pub expiration_seconds: Option<i64>,
    /// Empty when every currency is accepted.
    pub fiat_currencies_accepted: Vec<String>,
    pub max_orders_per_response: Option<u32>,
    /// The fee as the node writes it: a fraction (`0.006` = 0.6 %).
    pub fee: Option<f64>,
    pub pow: Option<u32>,
    pub pow_first_contact: Option<u32>,
    pub protocol_version: Option<u32>,
    /// Bosstro's verdict on `protocol_version` (transport v2 only).
    pub protocol_support: ProtocolSupport,
    pub bond_enabled: Option<bool>,
    pub hold_invoice_expiration_window: Option<i64>,
    pub hold_invoice_cltv_delta: Option<u32>,
    pub invoice_expiration_window: Option<i64>,
    pub lnd_version: Option<String>,
    pub lnd_node_pubkey: Option<String>,
    pub lnd_commit_hash: Option<String>,
    pub lnd_node_alias: Option<String>,
    pub lnd_chains: Vec<String>,
    pub lnd_networks: Vec<String>,
    pub lnd_uris: Vec<String>,
}

/// Bosstro's verdict on a `protocol_version` tag.
fn protocol_support_of(version: Option<u32>) -> ProtocolSupport {
    match version {
        Some(2) => ProtocolSupport::Supported,
        Some(_) => ProtocolSupport::Unsupported,
        None => ProtocolSupport::Unknown,
    }
}

/// What is cached of one node's event: its `created_at` and raw tags, so the
/// info is re-parsed with whatever this version knows.
#[flutter_rust_bridge::frb(ignore)]
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub(crate) struct CachedNodeInfo {
    pub created_at: i64,
    pub tags: Vec<Vec<String>>,
}

// ── Pure helpers ─────────────────────────────────────────────────────────────

/// Whether a relay-returned event may be taken as `node`'s instance info:
/// kind 38385, authored by `node`, `d` tag equal to `node`'s hex, valid id
/// and signature (Mostrix `instance_info_event_is_authentic`).
pub(crate) fn is_authentic(event: &Event, node: &PublicKey) -> bool {
    event.kind == Kind::Custom(MOSTRO_INSTANCE_INFO_KIND)
        && event.pubkey == *node
        && event.tags.identifier().map(|d| d.to_string()) == Some(node.to_hex())
        && event.verify().is_ok()
}

fn split_csv(value: &str) -> Vec<String> {
    value
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .collect()
}

fn parse_bool(value: &str) -> Option<bool> {
    match value.trim().to_ascii_lowercase().as_str() {
        "true" | "1" | "yes" => Some(true),
        "false" | "0" | "no" => Some(false),
        _ => None,
    }
}

/// Parse the tags of a kind 38385 event, as Mostrix's `mostro_info_from_tags`.
/// Unknown tags are ignored; a value that does not parse leaves its field
/// `None`.
pub(crate) fn info_from_tags(
    pubkey: &str,
    created_at: i64,
    now: i64,
    tags: &[Vec<String>],
) -> NodeInfo {
    let mut info = NodeInfo {
        pubkey: pubkey.to_string(),
        last_updated: created_at,
        is_stale: now.saturating_sub(created_at) > STALE_AFTER_SECS,
        ..Default::default()
    };
    for tag in tags {
        let Some(key) = tag.first() else {
            continue;
        };
        let value = tag.get(1).map(String::as_str).unwrap_or_default();
        let text = || Some(value.to_string());
        match key.as_str() {
            "mostro_version" => info.mostro_version = text(),
            // ["y", "<platform>", "<instance name>"]: the name is the third.
            "y" => info.name = tag.get(2).cloned(),
            "mostro_commit_hash" => info.mostro_commit_hash = text(),
            "max_order_amount" => info.max_order_amount = value.parse().ok(),
            "min_order_amount" => info.min_order_amount = value.parse().ok(),
            "expiration_hours" => info.expiration_hours = value.parse().ok(),
            "expiration_seconds" => info.expiration_seconds = value.parse().ok(),
            "fiat_currencies_accepted" => info.fiat_currencies_accepted = split_csv(value),
            "max_orders_per_response" => info.max_orders_per_response = value.parse().ok(),
            "fee" => info.fee = value.parse().ok(),
            "pow" => info.pow = value.parse().ok(),
            "pow_first_contact" => info.pow_first_contact = value.parse().ok(),
            "protocol_version" => info.protocol_version = value.parse().ok(),
            "bond_enabled" => info.bond_enabled = parse_bool(value),
            "hold_invoice_expiration_window" => {
                info.hold_invoice_expiration_window = value.parse().ok()
            }
            "hold_invoice_cltv_delta" => info.hold_invoice_cltv_delta = value.parse().ok(),
            "invoice_expiration_window" => info.invoice_expiration_window = value.parse().ok(),
            "lnd_version" => info.lnd_version = text(),
            "lnd_node_pubkey" => info.lnd_node_pubkey = text(),
            "lnd_commit_hash" => info.lnd_commit_hash = text(),
            "lnd_node_alias" => info.lnd_node_alias = text(),
            "lnd_chains" => info.lnd_chains = split_csv(value),
            "lnd_networks" => info.lnd_networks = split_csv(value),
            "lnd_uris" => info.lnd_uris = split_csv(value),
            _ => {}
        }
    }
    info.protocol_support = protocol_support_of(info.protocol_version);
    info
}

fn cached_of(event: &Event) -> CachedNodeInfo {
    CachedNodeInfo {
        created_at: event.created_at.as_secs() as i64,
        tags: event.tags.iter().map(|t| t.as_slice().to_vec()).collect(),
    }
}

/// The newer of what is cached and what was fetched (`created_at`; a tie
/// keeps the cache).
fn newest(cached: Option<CachedNodeInfo>, fetched: Option<CachedNodeInfo>) -> Option<CachedNodeInfo> {
    match (cached, fetched) {
        (Some(c), Some(f)) if f.created_at > c.created_at => Some(f),
        (Some(c), _) => Some(c),
        (None, f) => f,
    }
}

fn parse_node(pubkey: &str) -> Result<PublicKey> {
    PublicKey::from_hex(pubkey).map_err(|_| anyhow::anyhow!("InvalidPubkey"))
}

/// The cached info of `pubkey`. A blob that no longer parses is dropped, so
/// the next fetch stores a fresh one instead of losing to it.
async fn load_cached(db: &impl Storage, pubkey: &str) -> Option<CachedNodeInfo> {
    let key = settings_keys::node_info(pubkey);
    let json = db.get_setting(&key).await.ok()??;
    match serde_json::from_str(&json) {
        Ok(cached) => Some(cached),
        Err(e) => {
            log::warn!("[node] dropping unreadable cached instance info: {e}");
            let _ = db.delete_setting(&key).await;
            None
        }
    }
}

// ── Public API ───────────────────────────────────────────────────────────────

/// `pubkey`'s info as last seen on this device, without asking any relay;
/// `None` when it was never fetched (or there is no storage).
pub async fn cached_node_info(pubkey: String) -> Result<Option<NodeInfo>> {
    let pubkey = parse_node(&pubkey.to_lowercase())?.to_hex();
    let Some(db) = crate::db::app_db::db() else {
        return Ok(None);
    };
    Ok(load_cached(db, &pubkey)
        .await
        .map(|c| info_from_tags(&pubkey, c.created_at, crate::rt::unix_now(), &c.tags)))
}

/// Ask the relays for `pubkey`'s newest instance info, cache it if it is
/// newer than the cached one, and return the newest known (fetched or
/// cached). `None` only when there is none at all.
///
/// **Errors**: `InvalidPubkey`, `NotInitialized` (no relay pool), or the
/// relay query failing outright (the cache is then untouched).
pub async fn fetch_node_info(pubkey: String) -> Result<Option<NodeInfo>> {
    let client = crate::api::relays::pool()?.client();
    fetch_node_info_on(&client, &pubkey).await
}

/// [`fetch_node_info`] on `client` (the take reads the info through it when
/// none is cached, `crate::mostro::take`).
#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn fetch_node_info_on(client: &Client, pubkey: &str) -> Result<Option<NodeInfo>> {
    use futures_util::StreamExt;

    let node = parse_node(&pubkey.to_lowercase())?;
    let hex = node.to_hex();

    // A small window, so a forged "newest" event cannot wholly hide an
    // authentic revision when a relay returns a mixed set (Mostrix).
    let filter = Filter::new()
        .kind(Kind::Custom(MOSTRO_INSTANCE_INFO_KIND))
        .author(node)
        .identifier(hex.clone())
        .limit(10);
    let stream = client
        .stream_events(filter)
        .timeout(FETCH_TIMEOUT)
        .await
        .map_err(|e| anyhow::anyhow!("stream_events failed: {e}"))?;
    let authentic = stream.filter_map(move |(_, item)| async move {
        item.ok().filter(|event| is_authentic(event, &node))
    });
    let fetched = crate::nostr::first_answer::newest_answer(
        Box::pin(authentic),
        FETCH_GRACE,
        crate::nostr::first_answer::replaceable_rank,
    )
    .await
    .map(|event| cached_of(&event));

    let cached = match crate::db::app_db::db() {
        Some(db) => load_cached(db, &hex).await,
        None => None,
    };
    let fresh = fetched
        .as_ref()
        .is_some_and(|f| cached.as_ref().is_none_or(|c| f.created_at > c.created_at));
    let best = newest(cached, fetched);
    if fresh {
        if let (Some(db), Some(best)) = (crate::db::app_db::db(), &best) {
            if let Err(e) = db
                .set_setting(&settings_keys::node_info(&hex), &serde_json::to_string(best)?)
                .await
            {
                log::warn!("[node] instance info not cached: {e}");
            }
        }
    }
    Ok(best.map(|c| info_from_tags(&hex, c.created_at, crate::rt::unix_now(), &c.tags)))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tags(pairs: &[&[&str]]) -> Vec<Vec<String>> {
        pairs
            .iter()
            .map(|t| t.iter().map(|s| s.to_string()).collect())
            .collect()
    }

    #[test]
    fn every_mostrix_tag_is_read() {
        let info = info_from_tags(
            "aa",
            100,
            100,
            &tags(&[
                &["d", "aa"],
                &["mostro_version", "0.20.1"],
                &["y", "mostro", "Mostro Cuba"],
                &["mostro_commit_hash", "abc"],
                &["max_order_amount", "1000000"],
                &["min_order_amount", "100"],
                &["expiration_hours", "24"],
                &["expiration_seconds", "900"],
                &["fiat_currencies_accepted", "CUP, USD ,,VES"],
                &["max_orders_per_response", "10"],
                &["fee", "0.006"],
                &["pow", "0"],
                &["pow_first_contact", "8"],
                &["protocol_version", "2"],
                &["bond_enabled", "true"],
                &["hold_invoice_expiration_window", "300"],
                &["hold_invoice_cltv_delta", "144"],
                &["invoice_expiration_window", "300"],
                &["lnd_version", "0.18"],
                &["lnd_node_pubkey", "02ab"],
                &["lnd_commit_hash", "def"],
                &["lnd_node_alias", "mostro-lnd"],
                &["lnd_chains", "bitcoin"],
                &["lnd_networks", "mainnet"],
                &["lnd_uris", "02ab@1.2.3.4:9735,02ab@x.onion:9735"],
                &["unknown_tag", "x"],
            ]),
        );
        assert_eq!(info.name.as_deref(), Some("Mostro Cuba"));
        assert_eq!(info.mostro_version.as_deref(), Some("0.20.1"));
        assert_eq!(info.max_order_amount, Some(1_000_000));
        assert_eq!(info.min_order_amount, Some(100));
        assert_eq!(info.expiration_hours, Some(24));
        assert_eq!(info.expiration_seconds, Some(900));
        assert_eq!(info.fiat_currencies_accepted, vec!["CUP", "USD", "VES"]);
        assert_eq!(info.max_orders_per_response, Some(10));
        assert_eq!(info.fee, Some(0.006));
        assert_eq!(info.pow, Some(0));
        assert_eq!(info.pow_first_contact, Some(8));
        assert_eq!(info.protocol_support, ProtocolSupport::Supported);
        assert_eq!(info.bond_enabled, Some(true));
        assert_eq!(info.hold_invoice_expiration_window, Some(300));
        assert_eq!(info.hold_invoice_cltv_delta, Some(144));
        assert_eq!(info.invoice_expiration_window, Some(300));
        assert_eq!(info.lnd_node_alias.as_deref(), Some("mostro-lnd"));
        assert_eq!(info.lnd_chains, vec!["bitcoin"]);
        assert_eq!(info.lnd_networks, vec!["mainnet"]);
        assert_eq!(info.lnd_uris.len(), 2);
        assert!(!info.is_stale);
    }

    #[test]
    fn missing_or_garbled_tags_leave_fields_empty() {
        let info = info_from_tags(
            "aa",
            0,
            0,
            &tags(&[&["fee", "lots"], &["pow"], &[], &["bond_enabled", "maybe"]]),
        );
        assert_eq!(info.fee, None);
        assert_eq!(info.pow, None);
        assert_eq!(info.bond_enabled, None);
        assert!(info.fiat_currencies_accepted.is_empty());
        assert_eq!(info.protocol_support, ProtocolSupport::Unknown);
    }

    #[test]
    fn protocol_v1_is_unsupported() {
        let info = info_from_tags("aa", 0, 0, &tags(&[&["protocol_version", "1"]]));
        assert_eq!(info.protocol_support, ProtocolSupport::Unsupported);
    }

    #[test]
    fn info_older_than_seven_days_is_stale() {
        let now = 1_000_000_000;
        assert!(!info_from_tags("aa", now - STALE_AFTER_SECS, now, &[]).is_stale);
        assert!(info_from_tags("aa", now - STALE_AFTER_SECS - 1, now, &[]).is_stale);
    }

    fn info_event(keys: &Keys, d: &str, at: u64) -> Event {
        EventBuilder::new(Kind::Custom(MOSTRO_INSTANCE_INFO_KIND), "")
            .tags([Tag::identifier(d)])
            .custom_created_at(Timestamp::from_secs(at))
            .finalize(keys)
            .unwrap()
    }

    #[test]
    fn only_the_nodes_own_signed_event_with_its_d_tag_is_authentic() {
        let node = Keys::generate();
        let other = Keys::generate();
        let hex = node.public_key().to_hex();

        assert!(is_authentic(&info_event(&node, &hex, 1), &node.public_key()));
        // Another author, even one that copies the node's d tag.
        assert!(!is_authentic(&info_event(&other, &hex, 1), &node.public_key()));
        // The node's own key with a wrong coordinate.
        assert!(!is_authentic(&info_event(&node, "x", 1), &node.public_key()));
        // Another kind.
        let kind0 = EventBuilder::new(Kind::Metadata, "{}")
            .tags([Tag::identifier(&hex)])
            .finalize(&node)
            .unwrap();
        assert!(!is_authentic(&kind0, &node.public_key()));
    }

    #[test]
    fn a_fetch_never_replaces_newer_cached_info() {
        let at = |t| CachedNodeInfo {
            created_at: t,
            tags: vec![],
        };
        assert_eq!(newest(Some(at(5)), Some(at(9))), Some(at(9)));
        assert_eq!(newest(Some(at(9)), Some(at(5))), Some(at(9)));
        assert_eq!(newest(Some(at(9)), None), Some(at(9)));
        assert_eq!(newest(None, Some(at(5))), Some(at(5)));
        assert_eq!(newest(None, None), None);
    }
}
