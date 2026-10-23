//! What every [`Storage`] backend must do, written once over the trait and
//! run against each: SQLite natively (`db/sqlite.rs`), IndexedDB in a
//! browser (`db/indexeddb.rs`, `scripts/test-web-storage.sh`).
//!
//! Each check takes a fresh, empty store.

use crate::api::relays::{RelayInfo, RelaySource, RelayStatus};
use crate::db::{settings_keys, Storage};

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
