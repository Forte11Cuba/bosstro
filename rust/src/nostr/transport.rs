//! Mostro message transport, protocol v2 only: a NIP-44 encrypted, signed
//! kind 14 event, delegated to `mostro_core::transport` so every Mostro
//! client shares one implementation. Ported from MostroP2P/app's
//! `rust/src/nostr/transport.rs`, trimmed to the typed daemon traffic: the
//! chat envelope (`mostro_wrap` / `mostro_unwrap`) arrives with phase 5.
//!
//! Nothing here reads or writes a kind 1059 gift wrap.
//!
//! The solver signs with one key, the solver key, as both the trade key and
//! the identity (Mostrix sends admin actions the same way): no identity
//! proof is attached, and mostrod reads the solver from the event's author.
use anyhow::{anyhow, Result};
use mostro_core::message::Message;
use mostro_core::transport::{unwrap_incoming, wrap_message_with, Transport};
use mostro_core::transport::{UnwrappedMessage, WrapOptions};
use nostr_sdk::prelude::*;

/// Wrap `message` for `receiver` (the node) as a signed kind 14, authored and
/// signed by `keys`. `pow` (NIP-13) is mined on the event id; the daemon sets
/// its own NIP-40 expiration on its answers, so none is sent.
pub async fn wrap_mostro_message(
    keys: &Keys,
    receiver: &PublicKey,
    message: &Message,
    pow: u8,
) -> Result<Event> {
    let opts = WrapOptions {
        pow,
        expiration: None,
        signed: true,
    };
    wrap_message_with(Transport::Nip44Direct, message, keys, keys, *receiver, opts)
        .await
        .map_err(|e| anyhow!("wrap_message failed: {e}"))
}

/// Open a kind 14 addressed to `keys`. `Ok(None)` when it does not decrypt
/// with them (not for this key); `Err` for anything malformed or with a
/// signature that does not verify. The event's signature is checked here, so
/// `UnwrappedMessage::sender` is its proven author; whether that author is
/// the node is for the caller to check.
pub async fn unwrap_mostro_message(keys: &Keys, event: &Event) -> Result<Option<UnwrappedMessage>> {
    unwrap_incoming(event, keys)
        .await
        .map_err(|e| anyhow!("unwrap_message failed: {e}"))
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use mostro_core::message::Action;
    use uuid::Uuid;

    fn take(request_id: u64) -> Message {
        Message::new_dispute(
            Some(Uuid::parse_str("8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c").unwrap()),
            Some(request_id),
            None,
            Action::AdminTakeDispute,
            None,
        )
    }

    #[tokio::test]
    async fn a_take_reaches_the_node_signed_by_the_solver() {
        let solver = Keys::generate();
        let node = Keys::generate();
        let event = wrap_mostro_message(&solver, &node.public_key(), &take(42), 0)
            .await
            .unwrap();

        assert_eq!(event.kind, Kind::PrivateDirectMessage, "v2: kind 14");
        assert_eq!(event.pubkey, solver.public_key());
        let opened = unwrap_mostro_message(&node, &event)
            .await
            .unwrap()
            .expect("addressed to the node");
        // mostrod checks the solver on `identity`; with one key it is the
        // author.
        assert_eq!(opened.sender, solver.public_key());
        assert_eq!(opened.identity, solver.public_key());
        assert_eq!(
            opened.message.as_json().unwrap(),
            take(42).as_json().unwrap()
        );
    }

    #[tokio::test]
    async fn an_event_for_another_key_does_not_open() {
        let solver = Keys::generate();
        let node = Keys::generate();
        let event = wrap_mostro_message(&solver, &node.public_key(), &take(1), 0)
            .await
            .unwrap();
        let stranger = Keys::generate();
        assert!(unwrap_mostro_message(&stranger, &event)
            .await
            .unwrap()
            .is_none());
    }

    #[tokio::test]
    async fn the_pow_is_mined() {
        let solver = Keys::generate();
        let node = Keys::generate();
        let event = wrap_mostro_message(&solver, &node.public_key(), &take(7), 6)
            .await
            .unwrap();
        assert!(event.check_pow(6), "{}", event.id.to_hex());
    }
}
