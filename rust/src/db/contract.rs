//! What every [`Storage`] backend must do, written once over the trait and
//! run against each: SQLite natively (`db/sqlite.rs`), IndexedDB in a
//! browser (`db/indexeddb.rs`, `scripts/test-web-storage.sh`).
//!
//! Each check takes a fresh, empty store.

use crate::api::disputes::{DisputeInitiator, DisputeStatus};
use crate::api::relays::{RelayInfo, RelaySource, RelayStatus};
use crate::db::{settings_keys, Storage};
use crate::disputes::{DisputeRecord, TakenDispute};

pub(crate) fn relay(url: &str) -> RelayInfo {
    RelayInfo {
        url: url.to_string(),
        is_active: true,
        is_default: false,
        source: RelaySource::UserAdded,
        is_blacklisted: false,
        status: RelayStatus::Disconnected,
        last_connected_at: None,
        last_error: None,
        announced_by: None,
    }
}

pub(crate) async fn settings_round_trip(storage: &impl Storage) {
    assert_eq!(storage.get_setting("k").await.unwrap(), None);
    storage.set_setting("k", "one").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap().as_deref(), Some("one"));
    storage.set_setting("k", "two").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap().as_deref(), Some("two"));
    storage.delete_setting("k").await.unwrap();
    assert_eq!(storage.get_setting("k").await.unwrap(), None);
    // Deleting what is not there is not an error.
    storage.delete_setting("k").await.unwrap();
}

pub(crate) async fn active_node_is_absent_until_saved(storage: &impl Storage) {
    assert_eq!(storage.get_active_mostro_pubkey().await.unwrap(), None);
    storage.save_active_mostro_pubkey("aa").await.unwrap();
    storage.save_active_mostro_pubkey("bb").await.unwrap();
    assert_eq!(
        storage.get_active_mostro_pubkey().await.unwrap().as_deref(),
        Some("bb")
    );
    // It is an ordinary setting under its documented key.
    assert_eq!(
        storage
            .get_setting(settings_keys::ACTIVE_MOSTRO_PUBKEY)
            .await
            .unwrap()
            .as_deref(),
        Some("bb")
    );
}

pub(crate) async fn relays_round_trip(storage: &impl Storage) {
    assert!(storage.list_relays().await.unwrap().is_empty());
    let mut announced = relay("wss://a.example");
    announced.source = RelaySource::MostroDiscovered;
    announced.announced_by = Some("aa".into());
    storage.save_relay(&announced).await.unwrap();
    storage.save_relay(&relay("wss://b.example")).await.unwrap();

    // A save on the same URL replaces the row.
    announced.is_blacklisted = true;
    storage.save_relay(&announced).await.unwrap();

    let mut rows = storage.list_relays().await.unwrap();
    rows.sort_by(|a, b| a.url.cmp(&b.url));
    assert_eq!(rows.len(), 2);
    assert_eq!(rows[0], announced);
    assert_eq!(rows[1], relay("wss://b.example"));

}

pub(crate) async fn node_pictures_round_trip(storage: &impl Storage) {
    assert_eq!(storage.get_node_picture("a").await.unwrap(), None);
    assert!(storage.list_node_picture_urls().await.unwrap().is_empty());

    storage
        .save_node_picture("a", "https://a.example/1.png", &[1u8; 4])
        .await
        .unwrap();
    storage
        .save_node_picture("b", "https://b.example/b.png", &[2u8; 4])
        .await
        .unwrap();
    storage
        .save_node_picture("a", "https://a.example/2.png", &[3u8; 4])
        .await
        .unwrap();

    let a = storage.get_node_picture("a").await.unwrap().unwrap();
    assert_eq!(a.url, "https://a.example/2.png");
    assert_eq!(a.bytes, vec![3u8; 4]);
    let urls = storage.list_node_picture_urls().await.unwrap();
    assert_eq!(urls.len(), 2);
    assert_eq!(urls["b"], "https://b.example/b.png");

    storage.delete_node_picture("b").await.unwrap();
    storage.delete_node_picture("b").await.unwrap();
    assert_eq!(storage.get_node_picture("b").await.unwrap(), None);
    assert!(storage.get_node_picture("a").await.unwrap().is_some());
}

pub(crate) const DISPUTE_A: &str = "8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c";
pub(crate) const DISPUTE_B: &str = "1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9";

/// An untaken `initiated` dispute of `node`.
pub(crate) fn dispute(node: &str, id: &str) -> DisputeRecord {
    DisputeRecord {
        mostro_pubkey: node.to_string(),
        dispute_id: id.to_string(),
        status: DisputeStatus::Initiated,
        initiator: DisputeInitiator::Seller,
        opened_at: Some(1_700_000_000),
        expires_at: Some(1_900_000_000),
        event_id: "e".repeat(64),
        event_created_at: 1_700_000_100,
        taken: None,
    }
}

pub(crate) async fn disputes_round_trip(storage: &impl Storage) {
    assert!(storage.list_disputes("aa").await.unwrap().is_empty());
    assert_eq!(storage.get_dispute("aa", DISPUTE_A).await.unwrap(), None);

    // Every field survives, the optional ones absent too.
    let mut bare = dispute("aa", DISPUTE_B);
    bare.opened_at = None;
    bare.expires_at = None;
    bare.initiator = DisputeInitiator::Unknown;
    storage.save_dispute(&bare).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_B).await.unwrap(),
        Some(bare.clone())
    );

    // A save on the same (node, id) replaces the row, phase 4's fields
    // included.
    let mut row = dispute("aa", DISPUTE_A);
    storage.save_dispute(&row).await.unwrap();
    row.status = DisputeStatus::InProgress;
    row.event_created_at += 1;
    row.taken = Some(TakenDispute {
        taken_at: 1_700_000_200,
        order_id: Some("5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d".into()),
        order_kind: Some("sell".into()),
        amount: Some(50_000),
        fiat_amount: Some(30),
        fiat_code: Some("USD".into()),
        payment_method: Some("bank transfer".into()),
        premium: Some(-1),
        fee: Some(150),
        initiator_pubkey: Some("11".into()),
        buyer_pubkey: Some("22".into()),
        seller_pubkey: None,
    });
    storage.save_dispute(&row).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(row.clone())
    );

    // And back to untaken (a reopen).
    row.status = DisputeStatus::Initiated;
    row.taken = None;
    storage.save_dispute(&row).await.unwrap();
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(row.clone())
    );

    let mut all = storage.list_disputes("aa").await.unwrap();
    all.sort_by(|a, b| a.dispute_id.cmp(&b.dispute_id));
    assert_eq!(all, vec![bare, row]);
}

/// D6: the same dispute id under two nodes is two rows, and a node's list
/// holds only its own.
pub(crate) async fn disputes_never_mix_nodes(storage: &impl Storage) {
    let mine = dispute("aa", DISPUTE_A);
    let mut theirs = dispute("bb", DISPUTE_A);
    theirs.status = DisputeStatus::Settled;
    storage.save_dispute(&mine).await.unwrap();
    storage.save_dispute(&theirs).await.unwrap();
    storage
        .save_dispute(&dispute("bb", DISPUTE_B))
        .await
        .unwrap();

    assert_eq!(
        storage.list_disputes("aa").await.unwrap(),
        vec![mine.clone()]
    );
    assert_eq!(storage.list_disputes("bb").await.unwrap().len(), 2);
    assert_eq!(
        storage.get_dispute("aa", DISPUTE_A).await.unwrap(),
        Some(mine)
    );
    assert_eq!(
        storage.get_dispute("bb", DISPUTE_A).await.unwrap(),
        Some(theirs)
    );
    assert!(storage.list_disputes("cc").await.unwrap().is_empty());
}
