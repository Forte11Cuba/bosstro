//! Parsing the solver's secret key.
//!
//! The solver key is an nsec, never derived from words (D9, D10 in AGENTS.md):
//! Mostrix loads `admin_privkey` only as a secret key. Like Mostrix's
//! Settings → Change Admin Key (`validate_nsec` / `normalize_to_nsec` in
//! `ui/key_handler/validation.rs`), a bech32 `nsec1…` and a 64-character hex
//! secret are both accepted. A 64-character hex string cannot be told from a
//! public key by its shape; the npub confirmation on Log in is what catches a
//! public key pasted by mistake.

use nostr_sdk::prelude::{Keys, PublicKey, ToBech32};
use zeroize::Zeroizing;

/// Why a secret was refused. Stable markers: Dart maps each to its own copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NsecError {
    /// Nothing but whitespace.
    Empty,
    /// An `npub1…`: the public key where the secret key was expected.
    PublicKeyGiven,
    /// Not an nsec and not a 64-character hex secret.
    Invalid,
}

/// The scheme a `nostr:` URI puts in front of a key (NIP-21), as a QR code
/// of a key may carry it.
const NOSTR_URI_SCHEME: &str = "nostr:";

/// The bech32 prefix of a public key (NIP-19).
const NPUB_PREFIX: &str = "npub1";

/// Parses the secret in [input] — UTF-8 bytes as they crossed the bridge —
/// into `Keys`.
///
/// [input] is taken by value and wiped when this returns, whatever the
/// outcome: the only copy of the secret that outlives the call is the
/// `SecretKey` inside the returned `Keys`, which wipes itself on drop.
pub fn parse_secret(input: Vec<u8>) -> Result<Keys, NsecError> {
    let input = Zeroizing::new(input);
    // Not UTF-8 cannot be an nsec or hex; no lossy copy is made of it.
    let text = std::str::from_utf8(&input).map_err(|_| NsecError::Invalid)?;
    let mut key = text.trim();
    if key.is_empty() {
        return Err(NsecError::Empty);
    }
    // `get`, not indexing: a slice that ends inside a multi-byte character
    // (anything pasted) would panic.
    if let Some(scheme) = key.get(..NOSTR_URI_SCHEME.len()) {
        if scheme.eq_ignore_ascii_case(NOSTR_URI_SCHEME) {
            key = &key[NOSTR_URI_SCHEME.len()..];
        }
    }
    if key
        .get(..NPUB_PREFIX.len())
        .is_some_and(|prefix| prefix.eq_ignore_ascii_case(NPUB_PREFIX))
    {
        return Err(NsecError::PublicKeyGiven);
    }
    Keys::parse(key).map_err(|_| NsecError::Invalid)
}

/// The bech32 `npub1…` of [public_key].
pub fn npub_of(public_key: &PublicKey) -> String {
    public_key
        .to_bech32()
        .expect("a valid public key always encodes as bech32")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// NIP-19's own example pair.
    const NIP19_NSEC: &str = "nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5";
    const NIP19_HEX: &str = "67dea2ed018072d675f5415ecfaed7d2597555e202d85b3d65ea4e58d2d92ffa";
    const NIP19_PUBKEY_HEX: &str =
        "7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e";
    const NIP19_NPUB: &str = "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg";

    fn parse(text: &str) -> Result<Keys, NsecError> {
        parse_secret(text.as_bytes().to_vec())
    }

    #[test]
    fn parses_a_bech32_nsec() {
        let keys = parse(NIP19_NSEC).unwrap();
        assert_eq!(keys.public_key().to_hex(), NIP19_PUBKEY_HEX);
        assert_eq!(npub_of(&keys.public_key()), NIP19_NPUB);
    }

    /// As Mostrix's Change Admin Key does.
    #[test]
    fn parses_a_hex_secret() {
        assert_eq!(
            parse(NIP19_HEX).unwrap().public_key().to_hex(),
            NIP19_PUBKEY_HEX
        );
    }

    #[test]
    fn ignores_surrounding_whitespace() {
        let keys = parse(&format!("  {NIP19_NSEC}\n")).unwrap();
        assert_eq!(keys.public_key().to_hex(), NIP19_PUBKEY_HEX);
    }

    /// A QR code of a key may carry it as a NIP-21 URI.
    #[test]
    fn accepts_a_nostr_uri() {
        let keys = parse(&format!("nostr:{NIP19_NSEC}")).unwrap();
        assert_eq!(keys.public_key().to_hex(), NIP19_PUBKEY_HEX);
    }

    #[test]
    fn refuses_empty_input() {
        assert_eq!(parse("").unwrap_err(), NsecError::Empty);
        assert_eq!(parse(" \n\t").unwrap_err(), NsecError::Empty);
    }

    /// The wrong prefix: the public key where the secret was expected.
    #[test]
    fn names_an_npub_as_the_wrong_key() {
        assert_eq!(parse(NIP19_NPUB).unwrap_err(), NsecError::PublicKeyGiven);
        assert_eq!(
            parse(&format!("nostr:{NIP19_NPUB}")).unwrap_err(),
            NsecError::PublicKeyGiven
        );
    }

    #[test]
    fn refuses_what_is_not_a_secret_key() {
        for bad in [
            "nsec1",
            "nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe6", // bad checksum
            "note1fntxtkcy9pjwucqwa9mddn7v03wwwsu9j330jj350nvhpky2tuaspk6nqc", // another bech32
            &NIP19_HEX[..63],
            "not a key",
        ] {
            assert_eq!(parse(bad).unwrap_err(), NsecError::Invalid, "{bad}");
        }
    }

    /// Pasted text with a multi-byte character where a prefix is looked for
    /// is refused, not a panic.
    #[test]
    fn refuses_non_ascii_text_without_panicking() {
        for text in ["npub1…", "nost…", "ñ", "clave secreta: ñandú"] {
            assert!(parse(text).is_err(), "{text}");
        }
    }

    #[test]
    fn refuses_bytes_that_are_not_utf8() {
        assert_eq!(
            parse_secret(vec![0xff, 0xfe, 0xfd]).unwrap_err(),
            NsecError::Invalid
        );
    }
}
