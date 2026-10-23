//! First-launch seed data, from ../app's `db/seeds.rs`: the default relays.
//! Idempotent: nothing is written once any relay is stored.
use anyhow::Result;

use crate::api::relays::{RelayInfo, RelaySource, RelayStatus};
use crate::config;
use crate::db::Storage;

/// Seed `DEFAULT_RELAYS` into the relay table if no relays exist yet.
pub async fn seed_default_relays<S: Storage>(storage: &S) -> Result<()> {
    if !storage.list_relays().await?.is_empty() {
        return Ok(());
    }
    for url in config::DEFAULT_RELAYS {
        storage
            .save_relay(&RelayInfo {
                url: url.to_string(),
                is_active: true,
                is_default: true,
                source: RelaySource::Default,
                is_blacklisted: false,
                status: RelayStatus::Disconnected,
                last_connected_at: None,
                last_error: None,
                announced_by: None,
            })
            .await?;
    }
    Ok(())
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::db::sqlite::tests::store;

    #[tokio::test]
    async fn seeds_the_defaults_once_and_never_over_a_stored_list() {
        let storage = store().await;
        seed_default_relays(&storage).await.unwrap();
        let mut urls: Vec<String> = storage
            .list_relays()
            .await
            .unwrap()
            .into_iter()
            .map(|r| r.url)
            .collect();
        urls.sort();
        let mut expected: Vec<String> =
            config::DEFAULT_RELAYS.iter().map(|s| s.to_string()).collect();
        expected.sort();
        assert_eq!(urls, expected);

        // The user removed every default but one: a second launch keeps that.
        for url in &config::DEFAULT_RELAYS[1..] {
            storage.delete_relay(url).await.unwrap();
        }
        seed_default_relays(&storage).await.unwrap();
        assert_eq!(storage.list_relays().await.unwrap().len(), 1);
    }
}
