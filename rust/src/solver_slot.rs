//! The solver slot: crate-internal, so it lives outside `crate::api`, where
//! the bridge codegen would scan it. The transitions that use it are in
//! `api::solver`. Same shape as MostroP2P/app's `IdentitySlot`.

use nostr_sdk::prelude::Keys;
use tokio::sync::{Mutex, RwLock};

use crate::crypto::nsec::{self, NsecError};

/// Why a transition of the slot was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SlotError {
    /// The secret did not parse.
    Key(NsecError),
    /// A key is already loaded: a replacement unloads it first, so a second
    /// load never silently swaps the key that signs.
    AlreadyLoaded,
}

/// The loaded solver key and the generation that tells it from the next.
///
/// The process has one (`api::solver`); the transitions take it as a
/// parameter so each test drives a slot of its own.
pub(crate) struct SolverSlot {
    keys: RwLock<Option<Keys>>,
    /// Bumped by every unload, under the write lock: work that started under
    /// one key (a subscription, a take) can tell it was retired, even when
    /// the same nsec is loaded again, which a pubkey comparison would not.
    generation: std::sync::atomic::AtomicU64,
    /// Held by every transition — load, unload — from its first read to its
    /// last write, so none interleaves with another. Readers of the key take
    /// only `keys`.
    lifecycle: Mutex<()>,
}

impl SolverSlot {
    pub(crate) const fn new() -> Self {
        Self {
            keys: RwLock::const_new(None),
            generation: std::sync::atomic::AtomicU64::new(0),
            lifecycle: Mutex::const_new(()),
        }
    }

    /// Parses [secret] and installs it. The bytes are wiped whatever happens
    /// ([`nsec::parse_secret`]).
    pub(crate) async fn load(&self, secret: Vec<u8>) -> Result<Keys, SlotError> {
        let _transition = self.lifecycle.lock().await;
        if self.keys.read().await.is_some() {
            // Parsed anyway, so the bytes are wiped on this path too.
            let _ = nsec::parse_secret(secret);
            return Err(SlotError::AlreadyLoaded);
        }
        let keys = nsec::parse_secret(secret).map_err(SlotError::Key)?;
        *self.keys.write().await = Some(keys.clone());
        Ok(keys)
    }

    /// Drops the loaded key, if there is one, and bumps the generation.
    /// Returns whether a key was unloaded; an empty slot is not an error, so
    /// a replacement or a log out never has to tell the two apart.
    pub(crate) async fn unload(&self) -> bool {
        let _transition = self.lifecycle.lock().await;
        let mut keys = self.keys.write().await;
        let had = keys.take().is_some();
        if had {
            self.generation
                .fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        }
        had
    }

    /// The loaded key, if any.
    pub(crate) async fn keys(&self) -> Option<Keys> {
        self.keys.read().await.clone()
    }

    /// How many keys this slot has retired. Read from phase 3 on, by the
    /// work that must not outlive the key it started under.
    #[cfg_attr(not(test), allow(dead_code))]
    pub(crate) fn generation(&self) -> u64 {
        self.generation.load(std::sync::atomic::Ordering::SeqCst)
    }
}

/// The process's slot: the one key the app signs with.
pub(crate) static SOLVER_SLOT: SolverSlot = SolverSlot::new();

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    const NSEC: &str = "nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5";
    const PUBKEY_HEX: &str = "7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e";

    fn bytes(text: &str) -> Vec<u8> {
        text.as_bytes().to_vec()
    }

    #[tokio::test]
    async fn starts_empty() {
        let slot = SolverSlot::new();
        assert!(slot.keys().await.is_none());
        assert_eq!(slot.generation(), 0);
    }

    #[tokio::test]
    async fn load_installs_the_key() {
        let slot = SolverSlot::new();
        let keys = slot.load(bytes(NSEC)).await.unwrap();
        assert_eq!(keys.public_key().to_hex(), PUBKEY_HEX);
        assert_eq!(slot.keys().await.unwrap().public_key(), keys.public_key());
    }

    #[tokio::test]
    async fn a_refused_secret_leaves_the_slot_empty() {
        let slot = SolverSlot::new();
        let err = slot.load(bytes("npub1…")).await.unwrap_err();
        assert_eq!(err, SlotError::Key(NsecError::PublicKeyGiven));
        assert!(slot.keys().await.is_none());
    }

    /// A replacement unloads first; a second load never swaps the key.
    #[tokio::test]
    async fn refuses_to_load_over_a_loaded_key() {
        let slot = SolverSlot::new();
        slot.load(bytes(NSEC)).await.unwrap();
        let other = Keys::generate();
        let other_hex = other.secret_key().to_secret_hex();
        assert_eq!(
            slot.load(bytes(&other_hex)).await.unwrap_err(),
            SlotError::AlreadyLoaded
        );
        assert_eq!(slot.keys().await.unwrap().public_key().to_hex(), PUBKEY_HEX);
    }

    #[tokio::test]
    async fn unload_empties_the_slot_and_bumps_the_generation() {
        let slot = SolverSlot::new();
        slot.load(bytes(NSEC)).await.unwrap();
        assert!(slot.unload().await);
        assert!(slot.keys().await.is_none());
        assert_eq!(slot.generation(), 1);
    }

    #[tokio::test]
    async fn unloading_an_empty_slot_is_not_an_error() {
        let slot = SolverSlot::new();
        assert!(!slot.unload().await);
        assert_eq!(slot.generation(), 0);
    }

    /// The safe replace, as Dart drives it: unload, load the new key.
    #[tokio::test]
    async fn replace_is_unload_then_load() {
        let slot = SolverSlot::new();
        slot.load(bytes(NSEC)).await.unwrap();
        let next = Keys::generate();
        slot.unload().await;
        let loaded = slot
            .load(bytes(&next.secret_key().to_secret_hex()))
            .await
            .unwrap();
        assert_eq!(loaded.public_key(), next.public_key());
        assert_eq!(slot.generation(), 1);
    }

    /// The same key loaded again after an unload is a new generation.
    #[tokio::test]
    async fn reloading_the_same_key_is_a_new_generation() {
        let slot = SolverSlot::new();
        slot.load(bytes(NSEC)).await.unwrap();
        slot.unload().await;
        slot.load(bytes(NSEC)).await.unwrap();
        assert_eq!(slot.generation(), 1);
        assert_eq!(slot.keys().await.unwrap().public_key().to_hex(), PUBKEY_HEX);
    }
}
