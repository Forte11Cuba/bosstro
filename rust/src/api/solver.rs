//! The solver's key, across the bridge (AGENTS.md → "Key handling").
//!
//! The secret comes in as bytes (`Vec<u8>`, a `Uint8List` in Dart), never as
//! a `String`, so Dart can overwrite its buffer after the call; here it is
//! wiped as soon as it is parsed ([`crate::crypto::nsec::parse_secret`]).
//! Nothing in this module writes the secret anywhere or logs it: Dart owns
//! storage, Rust only holds the parsed key in memory ([`SOLVER_SLOT`]).

use nostr_sdk::prelude::{Keys, ToBech32};

use crate::crypto::nsec::{self, NsecError};
use crate::solver_slot::{SlotError, SOLVER_SLOT};

/// What the UI shows of the loaded key: never the secret.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SolverKeyInfo {
    /// `npub1…`, what the solver sends to the node operator.
    pub npub: String,
    /// The same key in hex, as mostrod and the protocol write it.
    pub public_key_hex: String,
}

/// A key made by Create new account. It is not loaded yet: Dart loads it with
/// [`load_solver_key`] once the solver has confirmed the backup.
#[derive(Debug, Clone)]
pub struct NewSolverAccount {
    /// Shown once for backup, then stored by Dart in secure storage.
    pub nsec: String,
    pub npub: String,
}

/// Why a key was refused. Dart maps each marker to its own copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SolverKeyError {
    /// Nothing was entered.
    Empty,
    /// An `npub1…`: the public key where the secret key was expected.
    PublicKeyGiven,
    /// Not an nsec and not a 64-character hex secret.
    Invalid,
    /// A key is loaded already; unload it first (the safe replace).
    AlreadyLoaded,
}

impl From<NsecError> for SolverKeyError {
    fn from(error: NsecError) -> Self {
        match error {
            NsecError::Empty => Self::Empty,
            NsecError::PublicKeyGiven => Self::PublicKeyGiven,
            NsecError::Invalid => Self::Invalid,
        }
    }
}

impl From<SlotError> for SolverKeyError {
    fn from(error: SlotError) -> Self {
        match error {
            SlotError::Key(error) => error.into(),
            SlotError::AlreadyLoaded => Self::AlreadyLoaded,
        }
    }
}

fn info_of(keys: &Keys) -> SolverKeyInfo {
    let public_key = keys.public_key();
    SolverKeyInfo {
        npub: nsec::npub_of(&public_key),
        public_key_hex: public_key.to_hex(),
    }
}

/// Generates a new solver key. Nothing is loaded or kept: the nsec is
/// returned once, for Dart to show for backup and then store.
#[flutter_rust_bridge::frb(sync)]
pub fn create_solver_account() -> NewSolverAccount {
    let keys = Keys::generate();
    NewSolverAccount {
        nsec: keys
            .secret_key()
            .to_bech32()
            .expect("a valid secret key always encodes as bech32"),
        npub: info_of(&keys).npub,
    }
}

/// The npub [secret] stands for, without loading it: what Log in shows the
/// solver to confirm before the key is used.
#[flutter_rust_bridge::frb(sync)]
pub fn preview_npub(secret: Vec<u8>) -> Result<String, SolverKeyError> {
    let keys = nsec::parse_secret(secret)?;
    Ok(info_of(&keys).npub)
}

/// Parses [secret] and makes it the key the app signs with. Refused with
/// [`SolverKeyError::AlreadyLoaded`] while another key is loaded.
pub async fn load_solver_key(secret: Vec<u8>) -> Result<SolverKeyInfo, SolverKeyError> {
    let keys = SOLVER_SLOT.load(secret).await?;
    // The node's answers to this key are followed from now on.
    crate::mostro::replies::follow().await;
    Ok(info_of(&keys))
}

/// Drops the loaded key. Returns whether one was loaded.
pub async fn unload_solver_key() -> bool {
    let had = SOLVER_SLOT.unload().await;
    // The answers to the old key are not followed, nor taken, any more.
    crate::mostro::replies::follow().await;
    had
}

/// The loaded key, if any.
pub async fn solver_pubkey() -> Option<SolverKeyInfo> {
    SOLVER_SLOT.keys().await.as_ref().map(info_of)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    #[test]
    fn a_new_account_is_a_valid_key_pair() {
        let account = create_solver_account();
        assert!(account.nsec.starts_with("nsec1"));
        assert!(account.npub.starts_with("npub1"));
        assert_eq!(
            preview_npub(account.nsec.into_bytes()).unwrap(),
            account.npub
        );
    }

    #[test]
    fn two_new_accounts_differ() {
        assert_ne!(create_solver_account().npub, create_solver_account().npub);
    }

    #[test]
    fn preview_maps_each_refusal_to_its_marker() {
        assert_eq!(preview_npub(b"".to_vec()), Err(SolverKeyError::Empty));
        assert_eq!(
            preview_npub(
                b"npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg".to_vec()
            ),
            Err(SolverKeyError::PublicKeyGiven)
        );
        assert_eq!(
            preview_npub(b"nsec1nope".to_vec()),
            Err(SolverKeyError::Invalid)
        );
    }

    /// The global slot is shared by the tests of this module only; this is
    /// the one that touches it.
    #[tokio::test]
    async fn load_unload_and_read_the_global_slot() {
        let account = create_solver_account();
        unload_solver_key().await;
        let info = load_solver_key(account.nsec.clone().into_bytes())
            .await
            .unwrap();
        assert_eq!(info.npub, account.npub);
        assert_eq!(solver_pubkey().await, Some(info));
        assert_eq!(
            load_solver_key(account.nsec.into_bytes()).await,
            Err(SolverKeyError::AlreadyLoaded)
        );
        assert!(unload_solver_key().await);
        assert_eq!(solver_pubkey().await, None);
    }
}
