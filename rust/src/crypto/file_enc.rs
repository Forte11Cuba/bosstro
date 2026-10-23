//! Chat attachment encryption: ChaCha20-Poly1305, from ../app's
//! `crypto/file_enc.rs`.
//!
//! A blob is `[12-byte nonce][ciphertext + 16-byte tag]`, no associated data,
//! a random nonce per file: byte for byte what ../app uploads to Blossom, so
//! either app opens the other's files. A reader takes the nonce from the blob.
//!
//! The key is [`attachment_key`]: the raw ECDH x-coordinate between the
//! solver key and the party's trade key. It is derived in memory when a file
//! is sent or opened and never stored, as the chat's `K_conv` / `K_sign`.
use anyhow::{anyhow, Result};
use chacha20poly1305::{
    aead::{Aead, KeyInit},
    ChaCha20Poly1305, Nonce,
};
use mostro_core::chat::SharedKey;
use nostr_sdk::prelude::{Keys, PublicKey};
use rand::RngCore;
use zeroize::Zeroizing;

/// Nonce bytes at the head of a blob.
pub const NONCE_BYTES: usize = 12;
/// The AEAD tag at its tail.
pub const TAG_BYTES: usize = 16;

/// The ChaCha20-Poly1305 key for the attachments between `own` and
/// `counterpart`: the raw x-coordinate of their ECDH, **not** hashed (../app
/// `attachment_key` → `ecdh::raw_shared_x`; the hashed form would make every
/// file unreadable across the apps). Symmetric: the party derives the same
/// key from its trade key and the solver's pubkey.
///
/// Read from mostro-core's ECDH (`SharedKey`, the same x the chat keys start
/// from) rather than ../app's own k256 code: the vector test below proves
/// they agree.
pub fn attachment_key(own: &Keys, counterpart: &PublicKey) -> Result<Zeroizing<[u8; 32]>> {
    let shared = SharedKey::derive(own.secret_key(), counterpart)
        .map_err(|e| anyhow!("attachment key not derived: {e}"))?;
    Ok(Zeroizing::new(shared.keys().secret_key().to_secret_bytes()))
}

/// Encrypt `bytes` under `key` with a fresh random nonce.
pub fn encrypt_file(bytes: &[u8], key: &[u8; 32]) -> Result<Vec<u8>> {
    let mut nonce = [0u8; NONCE_BYTES];
    rand::rngs::OsRng.fill_bytes(&mut nonce);
    encrypt_file_with_nonce(bytes, key, &nonce)
}

/// [`encrypt_file`] with a caller-chosen nonce. Only for test vectors: a
/// nonce must never repeat under one key.
fn encrypt_file_with_nonce(
    bytes: &[u8],
    key: &[u8; 32],
    nonce: &[u8; NONCE_BYTES],
) -> Result<Vec<u8>> {
    let ciphertext = ChaCha20Poly1305::new(key.into())
        .encrypt(Nonce::from_slice(nonce), bytes)
        .map_err(|e| anyhow!("file encryption failed: {e}"))?;
    let mut out = Vec::with_capacity(NONCE_BYTES + ciphertext.len());
    out.extend_from_slice(nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

/// Decrypt a blob made by [`encrypt_file`] (or by ../app). A blob altered in
/// any byte, or sealed under another key, fails the tag.
pub fn decrypt_file(blob: &[u8], key: &[u8; 32]) -> Result<Vec<u8>> {
    if blob.len() < NONCE_BYTES + TAG_BYTES {
        return Err(anyhow!("encrypted data too short: {} bytes", blob.len()));
    }
    let (nonce, ciphertext) = blob.split_at(NONCE_BYTES);
    ChaCha20Poly1305::new(key.into())
        .decrypt(Nonce::from_slice(nonce), ciphertext)
        .map_err(|e| anyhow!("file decryption failed: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_key() -> [u8; 32] {
        core::array::from_fn(|i| (i * 7 + 13) as u8)
    }

    #[test]
    fn a_file_round_trips() {
        let key = test_key();
        let blob = encrypt_file(b"hello, world!", &key).unwrap();
        assert_eq!(blob.len(), NONCE_BYTES + 13 + TAG_BYTES);
        assert_eq!(decrypt_file(&blob, &key).unwrap(), b"hello, world!");
        let empty = encrypt_file(b"", &key).unwrap();
        assert!(decrypt_file(&empty, &key).unwrap().is_empty());
    }

    #[test]
    fn an_altered_blob_or_another_key_is_refused() {
        let key = test_key();
        let blob = encrypt_file(b"tamper test", &key).unwrap();
        for at in [0, NONCE_BYTES + 2, blob.len() - 1] {
            let mut altered = blob.clone();
            altered[at] ^= 0x01;
            assert!(decrypt_file(&altered, &key).is_err(), "byte {at}");
        }
        let mut other = key;
        other[0] ^= 0xFF;
        assert!(decrypt_file(&blob, &other).is_err());
        assert!(decrypt_file(&blob[..NONCE_BYTES + TAG_BYTES - 1], &key).is_err());
    }

    #[test]
    fn every_file_gets_its_own_nonce() {
        let key = test_key();
        let a = encrypt_file(b"same", &key).unwrap();
        let b = encrypt_file(b"same", &key).unwrap();
        assert_ne!(a[..NONCE_BYTES], b[..NONCE_BYTES]);
    }

    // ../app's cross-client vector (`crypto/file_enc.rs`, #589): the chat
    // spec's test-vector keys, plaintext "Mostro v1 attachment vector" and
    // nonce 01..0c. The same key and blob ../app derives and writes.
    const ALICE_SK: &str = "548f68890c49fa42f104c60352395e60ff030b0b407e955f1eed1400d6c0347a";
    const BOB_SK: &str = "f258e73f07386d37133718b6127f873dd7c391b8f43b331ff8254034a13d2943";
    const APP_FILE_KEY: &str = "def6633a53d07d1e829484c4d4bdbbeed2f4b14c21743e63871c174338e39475";
    const APP_BLOB: &str = "0102030405060708090a0b0cd56fcf60b9ccf71bd15877dc98c919bf9be866f8629872d02b1d4ef15dff60106750e95b4098ea21a1fc98";
    const APP_PLAINTEXT: &[u8] = b"Mostro v1 attachment vector";

    fn parties() -> (Keys, Keys) {
        (Keys::parse(ALICE_SK).unwrap(), Keys::parse(BOB_SK).unwrap())
    }

    #[test]
    fn the_key_is_the_one_app_derives_from_both_sides() {
        let (solver, party) = parties();
        let ours = attachment_key(&solver, &party.public_key()).unwrap();
        let theirs = attachment_key(&party, &solver.public_key()).unwrap();
        assert_eq!(hex::encode(*ours), APP_FILE_KEY);
        assert_eq!(*ours, *theirs);
    }

    #[test]
    fn a_blob_app_encrypted_opens_here() {
        let (solver, party) = parties();
        let key = attachment_key(&solver, &party.public_key()).unwrap();
        let blob = hex::decode(APP_BLOB).unwrap();
        assert_eq!(decrypt_file(&blob, &key).unwrap(), APP_PLAINTEXT);
    }

    #[test]
    fn a_blob_made_here_is_byte_for_byte_the_one_app_opens() {
        let (solver, party) = parties();
        let key = attachment_key(&party, &solver.public_key()).unwrap();
        let nonce: [u8; NONCE_BYTES] = core::array::from_fn(|i| i as u8 + 1);
        let blob = encrypt_file_with_nonce(APP_PLAINTEXT, &key, &nonce).unwrap();
        assert_eq!(hex::encode(blob), APP_BLOB);
    }
}
