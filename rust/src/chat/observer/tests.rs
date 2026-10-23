//! The observed chat against a relay: the parties of a dispute write to each
//! other as ../app does (the chat envelope keyed between their two trade
//! keys, the inner event signed by the writer's trade key), one of them
//! discloses the key to the solver as ../app's `share_chat_key_with_solver`
//! does, and the solver reads.

use std::sync::Mutex;
use std::time::Duration;

use mostro_core::chat::wrap_chat_message;
use nostr_sdk::prelude::*;
use sha2::Digest;

use super::*;
use crate::api::chat::ChatSender;
use crate::chat::channel_keys;
use crate::chat::router::tests::{bench, bench_with, Bench, Party, DISPUTE_A};
use crate::disputes::feed::Store;

/// The key of the buyer ↔ seller chat, as ../app derives it on either side.
fn p2p_keys(b: &Bench) -> (Keys, Keys) {
    let from_buyer = channel_keys(&b.buyer.keys, &b.seller.keys.public_key()).unwrap();
    let from_seller = channel_keys(&b.seller.keys, &b.buyer.keys.public_key()).unwrap();
    assert_eq!(from_buyer.0.public_key(), from_seller.0.public_key());
    from_buyer
}

/// What ../app's `chat_key_disclosure` writes.
fn disclosure_text(conv: &Keys) -> String {
    format!("Shared key: {}", conv.secret_key().to_secret_hex())
}

/// `from` writes `text` to `to` in their own chat, as ../app's `send_message`.
async fn p2p_say(from: &Party, to: &Party, text: &str) -> Event {
    let (conv, sign) = channel_keys(&from.keys, &to.keys.public_key()).unwrap();
    let event = wrap_chat_message(&from.keys, &conv, &sign, text)
        .await
        .unwrap();
    from.publish(&event).await;
    event
}

/// The buyer and the seller talk, then the buyer shares the key.
async fn talk_and_disclose(b: &Bench) {
    p2p_say(&b.buyer, &b.seller, "I sent the transfer").await;
    p2p_say(&b.seller, &b.buyer, "Nothing arrived").await;
    let (conv, _) = p2p_keys(b);
    b.buyer
        .say(&b.solver.public_key(), &disclosure_text(&conv))
        .await;
    b.wait_for(DISPUTE_A, ChatParty::Buyer, 1).await;
}

#[test]
fn only_the_exact_disclosure_format_is_a_key() {
    let hex = "a".repeat(64);
    assert!(parse_disclosure(&format!("Shared key: {hex}")).is_some());
    assert!(parse_disclosure(&format!("Shared key: {}", "AbC1".repeat(16))).is_some());
    for text in [
        format!("shared key: {hex}"),
        format!("Shared key:{hex}"),
        format!(" Shared key: {hex}"),
        format!("Shared key: {hex}\n"),
        format!("Shared key: {hex} please"),
        format!("Shared key: {}", "a".repeat(63)),
        format!("Shared key: {}", "a".repeat(65)),
        format!("Shared key: {}g", "a".repeat(63)),
        format!("Shared key: {}é", "a".repeat(62)),
        hex.clone(),
        String::new(),
    ] {
        assert!(parse_disclosure(&text).is_none(), "{text:?}");
    }
    // A paste takes the bare key (as Mostrix) or the whole line, spaces aside.
    assert!(parse_pasted(hex.as_bytes()).is_some());
    assert!(parse_pasted(format!("  Shared key: {hex}\n").as_bytes()).is_some());
    assert!(parse_pasted(format!("nsec1{hex}").as_bytes()).is_none());
    assert!(parse_pasted(&[0xff, 0xfe]).is_none());
    // A value that is not a secret key (zero) is refused too.
    let zero = parse_pasted("0".repeat(64).as_bytes()).unwrap();
    assert!(conv_keys(&zero).is_none());
}

#[test]
fn a_declared_file_type_is_shown_only_when_it_is_one() {
    assert_eq!(label_mime(" Application/PDF "), "application/pdf");
    assert_eq!(label_mime("image/svg+xml"), "image/svg+xml");
    for bad in [
        "",
        "pdf",
        "text/",
        "/x",
        "text/html\u{202e}",
        "a/b c",
        "a/b/c",
    ] {
        assert_eq!(label_mime(bad), "", "{bad:?}");
    }
    assert_eq!(label_mime(&format!("a/{}", "b".repeat(100))), "");
}

/// A disclosure counts only as the message of the party whose conversation
/// it is in: never this key's own, never the other party's, and only in the
/// exact format.
#[tokio::test]
async fn a_disclosure_is_taken_only_from_its_party() {
    let b = bench().await;
    let solver = b.solver.public_key();
    let (conv, _) = p2p_keys(&b);
    let text = disclosure_text(&conv);

    // This key writes it itself: its own message is not a disclosure.
    b.router
        .send(DISPUTE_A, ChatParty::Buyer, &text)
        .await
        .unwrap();
    // The seller signs it on the buyer's conversation: a stranger there,
    // dropped, so there is nothing to take.
    let (buyer_conv, buyer_sign) = channel_keys(&b.buyer.keys, &solver).unwrap();
    let forged = wrap_chat_message(&b.seller.keys, &buyer_conv, &buyer_sign, &text)
        .await
        .unwrap();
    b.buyer.publish(&forged).await;
    // The buyer writes it, but not in the format.
    b.buyer.say(&solver, &format!("{text} thanks")).await;
    b.wait_for(DISPUTE_A, ChatParty::Buyer, 2).await;
    tokio::time::sleep(Duration::from_millis(300)).await;
    assert_eq!(b.messages(DISPUTE_A, ChatParty::Buyer).await.len(), 2);
    let state = b.router.observed(DISPUTE_A).await.unwrap();
    assert!(state.disclosures.is_empty());
    assert_eq!(
        b.router.read_observed(DISPUTE_A).await,
        Err(ObserverError::NoSharedKey)
    );

    // Now the buyer shares it as ../app does, and then the seller too.
    b.buyer.say(&solver, &text).await;
    b.wait_for(DISPUTE_A, ChatParty::Buyer, 3).await;
    let state = b.router.observed(DISPUTE_A).await.unwrap();
    assert_eq!(state.disclosures.len(), 1);
    assert_eq!(state.disclosures[0].party, ChatParty::Buyer);
    let shared = b
        .messages(DISPUTE_A, ChatParty::Buyer)
        .await
        .into_iter()
        .find(|m| m.sender == ChatSender::Buyer && m.content == text)
        .unwrap();
    assert_eq!(state.disclosures[0].shared_at, shared.created_at);

    let from_seller = channel_keys(&b.seller.keys, &b.buyer.keys.public_key()).unwrap();
    b.seller
        .say(&solver, &disclosure_text(&from_seller.0))
        .await;
    b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;
    let parties: Vec<ChatParty> = b
        .router
        .observed(DISPUTE_A)
        .await
        .unwrap()
        .disclosures
        .iter()
        .map(|d| d.party)
        .collect();
    assert_eq!(parties.len(), 2);
    assert!(parties.contains(&ChatParty::Seller));
}

/// The parties' own chat, built as ../app builds it, reads with the key one
/// of them shared: both sides, oldest first, each named by its signer, kept
/// once however many times it is read.
#[tokio::test]
async fn a_conversation_built_as_app_reads_with_the_shared_key() {
    let b = bench().await;
    talk_and_disclose(&b).await;
    let state = b.router.read_observed(DISPUTE_A).await.unwrap();
    let got: Vec<(ChatParty, &str)> = state
        .messages
        .iter()
        .map(|m| (m.sender, m.content.as_str()))
        .collect();
    assert_eq!(got.len(), 2, "{got:?}");
    assert!(got.contains(&(ChatParty::Buyer, "I sent the transfer")));
    assert!(got.contains(&(ChatParty::Seller, "Nothing arrived")));
    assert!(state.messages[0].created_at <= state.messages[1].created_at);
    assert_eq!(state.disclosures.len(), 1);
    assert!(!state.has_pasted_key);

    // Read again: one more, none twice, and the stored state is the same.
    p2p_say(&b.buyer, &b.seller, "Check again").await;
    let again = b.router.read_observed(DISPUTE_A).await.unwrap();
    assert_eq!(again.messages.len(), 3);
    assert_eq!(
        b.router.observed(DISPUTE_A).await.unwrap().messages,
        again.messages
    );
    // None of it reached the solver's own conversations.
    assert_eq!(b.messages(DISPUTE_A, ChatParty::Buyer).await.len(), 1);
    assert!(b.messages(DISPUTE_A, ChatParty::Seller).await.is_empty());
}

/// Inside a valid envelope of the parties' chat (whoever holds `K_conv` and
/// `K_sign` can build one), an inner event signed by anyone but the buyer or
/// the seller is dropped — this solver key included.
#[tokio::test]
async fn an_unknown_inner_signer_is_dropped() {
    let b = bench().await;
    let (conv, sign) = p2p_keys(&b);
    for impostor in [Keys::generate(), b.solver.clone()] {
        let forged = wrap_chat_message(&impostor, &conv, &sign, "release it now")
            .await
            .unwrap();
        b.buyer.publish(&forged).await;
    }
    talk_and_disclose(&b).await;
    let state = b.router.read_observed(DISPUTE_A).await.unwrap();
    assert_eq!(state.messages.len(), 2);
    assert!(state.messages.iter().all(|m| m.content != "release it now"));
}

/// A key that opens nothing of this dispute says so, pasted or disclosed,
/// and a pasted one is then not kept.
#[tokio::test]
async fn a_key_that_opens_nothing_says_so() {
    let b = bench().await;
    p2p_say(&b.buyer, &b.seller, "hello").await;

    // Not a key at all.
    assert_eq!(
        b.router.paste_observer_key(DISPUTE_A, b"npub1nope").await,
        Err(ObserverError::InvalidKey)
    );
    // A key of nothing.
    let random = Keys::generate().secret_key().to_secret_hex();
    assert_eq!(
        b.router
            .paste_observer_key(DISPUTE_A, random.as_bytes())
            .await,
        Err(ObserverError::KeyOpensNothing)
    );
    // The key of another trade's chat, whose messages are on the relay too:
    // its signers are not this dispute's parties.
    let (other_buyer, other_seller) = (Keys::generate(), Keys::generate());
    let (other_conv, other_sign) = channel_keys(&other_buyer, &other_seller.public_key()).unwrap();
    let elsewhere = wrap_chat_message(&other_buyer, &other_conv, &other_sign, "other trade")
        .await
        .unwrap();
    b.buyer.publish(&elsewhere).await;
    let other_hex = other_conv.secret_key().to_secret_hex();
    assert_eq!(
        b.router
            .paste_observer_key(DISPUTE_A, other_hex.as_bytes())
            .await,
        Err(ObserverError::KeyOpensNothing)
    );
    let state = b.router.observed(DISPUTE_A).await.unwrap();
    assert!(!state.has_pasted_key);
    assert!(state.messages.is_empty());

    // Disclosed by the seller, it says the same.
    b.seller
        .say(&b.solver.public_key(), &format!("Shared key: {other_hex}"))
        .await;
    b.wait_for(DISPUTE_A, ChatParty::Seller, 1).await;
    assert_eq!(
        b.router
            .observed(DISPUTE_A)
            .await
            .unwrap()
            .disclosures
            .len(),
        1
    );
    assert_eq!(
        b.router.read_observed(DISPUTE_A).await,
        Err(ObserverError::KeyOpensNothing)
    );
}

/// A pasted key reads, is held in memory for its dispute, and goes with a
/// log out or another key, while what it read stays.
#[tokio::test]
async fn a_pasted_key_reads_and_goes_with_the_solver_key() {
    let b = bench().await;
    p2p_say(&b.seller, &b.buyer, "the bank says pending").await;
    let (conv, _) = p2p_keys(&b);
    let pasted = format!("  {}\n", conv.secret_key().to_secret_hex());
    let state = b
        .router
        .paste_observer_key(DISPUTE_A, pasted.as_bytes())
        .await
        .unwrap();
    assert!(state.has_pasted_key);
    assert!(state.disclosures.is_empty());
    assert_eq!(state.messages.len(), 1);
    assert_eq!(state.messages[0].sender, ChatParty::Seller);
    // A refresh reads with it.
    p2p_say(&b.buyer, &b.seller, "now?").await;
    assert_eq!(
        b.router
            .read_observed(DISPUTE_A)
            .await
            .unwrap()
            .messages
            .len(),
        2
    );

    let node = b.node.public_key().to_hex();
    b.router.sync(Some(node.clone()), None).await;
    b.router.sync(Some(node), Some(b.solver.clone())).await;
    let state = b.router.observed(DISPUTE_A).await.unwrap();
    assert!(!state.has_pasted_key, "forgotten with the log out");
    assert_eq!(state.messages.len(), 2, "what it read stays");
    assert_eq!(
        b.router.read_observed(DISPUTE_A).await,
        Err(ObserverError::NoSharedKey)
    );
}

/// A file of the parties' chat, encrypted as ../app encrypts it (the raw
/// ECDH of the two trade keys), shows as an attachment with its sanitized
/// name and type, and does not open with `K_conv`.
#[tokio::test]
async fn an_attachment_of_the_parties_does_not_open_with_the_shared_key() {
    use crate::crypto::file_enc::{attachment_key, decrypt_file, encrypt_file};
    let b = bench().await;
    let file = b"%PDF-1.4 the bank statement";
    let key = attachment_key(&b.buyer.keys, &b.seller.keys.public_key()).unwrap();
    let blob = encrypt_file(file, &key).unwrap();
    let hash = hex::encode(sha2::Sha256::digest(&blob));
    let json = format!(
        r#"{{"type":"file_encrypted","file_type":"document","blossom_url":"https://blossom.example/{hash}","nonce":"{}","mime_type":"application/pdf","original_size":{},"filename":"../statement.pdf","encrypted_size":{}}}"#,
        hex::encode(&blob[..12]),
        file.len(),
        blob.len()
    );
    p2p_say(&b.buyer, &b.seller, &json).await;
    talk_and_disclose(&b).await;

    let state = b.router.read_observed(DISPUTE_A).await.unwrap();
    let attachment = state
        .messages
        .iter()
        .find_map(|m| m.attachment.clone())
        .expect("the attachment message");
    assert_eq!(attachment.file_name, "statement.pdf", "sanitized");
    assert_eq!(attachment.mime_type, "application/pdf");
    // The seller opens it; the shared key does not.
    let seller_key = attachment_key(&b.seller.keys, &b.buyer.keys.public_key()).unwrap();
    assert_eq!(decrypt_file(&blob, &seller_key).unwrap(), file);
    let (conv, _) = p2p_keys(&b);
    assert!(decrypt_file(&blob, &conv.secret_key().to_secret_bytes()).is_err());
}

/// The observer has no way to write: none of its code builds or publishes
/// an event, and reading leaves the relay as it was.
#[tokio::test]
async fn nothing_is_ever_sent() {
    for source in [
        include_str!("../observer.rs"),
        include_str!("../../api/observer.rs"),
    ] {
        let code: String = source
            .lines()
            .filter(|line| !line.trim_start().starts_with("//"))
            .collect::<Vec<_>>()
            .join("\n")
            // Opening is reading: only the writing half counts.
            .replace("unwrap_chat_message", "");
        for call in [
            "send_event",
            "send_chat",
            "wrap_chat_message",
            "EventBuilder",
            "publish",
            "finalize",
        ] {
            assert!(!code.contains(call), "the observer calls {call}");
        }
    }
    let b = bench().await;
    talk_and_disclose(&b).await;
    let count = || async {
        b.buyer
            .client
            .fetch_events(Filter::new().kind(Kind::PrivateDirectMessage))
            .timeout(Duration::from_secs(3))
            .await
            .unwrap()
            .len()
    };
    let before = count().await;
    b.router.read_observed(DISPUTE_A).await.unwrap();
    let (conv, _) = p2p_keys(&b);
    b.router
        .paste_observer_key(DISPUTE_A, conv.secret_key().to_secret_hex().as_bytes())
        .await
        .unwrap();
    tokio::time::sleep(Duration::from_millis(300)).await;
    assert_eq!(count().await, before);
}

/// The query: `#p` of every key, no `authors` (`pub(K_sign)` is not known),
/// from a week before the dispute, capped.
#[test]
fn the_read_asks_from_a_week_before_the_dispute() {
    let conv = Keys::generate();
    let json = serde_json::to_value(observer_filter(std::slice::from_ref(&conv), 1_000)).unwrap();
    assert_eq!(json["#p"][0], conv.public_key().to_hex());
    assert!(json.get("authors").is_none());
    assert_eq!(json["kinds"][0], 14);
    assert_eq!(json["since"], 1_000);
    assert_eq!(json["limit"], MAX_EVENTS);

    let solver = Keys::generate().public_key().to_hex();
    let mut row = crate::db::contract::dispute("aa", DISPUTE_A);
    let mut taken = crate::disputes::tests::taken();
    taken.solver_pubkey = solver.clone();
    taken.taken_at = 2_000_000;
    row.taken = Some(taken);
    row.opened_at = Some(1_900_000);
    assert_eq!(
        Scope::of(&row, &solver).unwrap().since,
        1_900_000 - LOOKBACK_SECS
    );
    row.opened_at = None;
    assert_eq!(
        Scope::of(&row, &solver).unwrap().since,
        2_000_000 - LOOKBACK_SECS
    );
    // Another key's dispute has no observed chat here.
    assert!(Scope::of(&row, "someone else").is_none());
}

/// Every line logged, for the test below (no other test installs a logger).
struct Capture;

static LOGGED: Mutex<Vec<String>> = Mutex::new(Vec::new());
static CAPTURE: Capture = Capture;

impl log::Log for Capture {
    fn enabled(&self, _: &log::Metadata) -> bool {
        true
    }

    fn log(&self, record: &log::Record) {
        LOGGED
            .lock()
            .unwrap()
            .push(format!("{} {}", record.target(), record.args()));
    }

    fn flush(&self) {}
}

/// A pasted key is not written to storage (a disclosed one is a chat
/// message, stored as the chat is), and neither the key nor what it reads is
/// ever logged.
#[tokio::test]
async fn no_key_or_content_reaches_storage_or_the_logs() {
    if log::set_logger(&CAPTURE).is_ok() {
        log::set_max_level(log::LevelFilter::Trace);
    }
    let path = crate::db::sqlite::tests::temp_db_path();
    let storage: &'static crate::db::sqlite::SqliteStorage = Box::leak(Box::new(
        crate::db::sqlite::SqliteStorage::open(path.to_str().unwrap())
            .await
            .unwrap(),
    ));
    let b = bench_with(Store::Db(storage), ChatStore::Db(storage)).await;
    let secret_text = "the receipt number is 7731";
    p2p_say(&b.buyer, &b.seller, secret_text).await;
    let (conv, sign) = p2p_keys(&b);
    let hex = conv.secret_key().to_secret_hex();
    let state = b
        .router
        .paste_observer_key(DISPUTE_A, hex.as_bytes())
        .await
        .unwrap();
    assert_eq!(state.messages[0].content, secret_text);
    b.router.read_observed(DISPUTE_A).await.unwrap();

    let mut written = Vec::new();
    for suffix in ["", "-wal", "-shm"] {
        if let Ok(bytes) = std::fs::read(format!("{}{suffix}", path.to_str().unwrap())) {
            written.extend(bytes);
        }
    }
    assert!(
        written
            .windows(secret_text.len())
            .any(|w| w == secret_text.as_bytes()),
        "the message is stored, so the scan sees what is written"
    );
    let text = String::from_utf8_lossy(&written).to_lowercase();
    for secret in [
        conv.secret_key().to_secret_bytes(),
        sign.secret_key().to_secret_bytes(),
    ] {
        assert!(
            !text.contains(&hex::encode(secret)),
            "a key was written as hex"
        );
        assert!(
            !written.windows(32).any(|w| w == secret),
            "a key was written as bytes"
        );
    }

    // This crate's lines (its target is `rust::…`); the SDK's own trace
    // lines carry encrypted frames, whose hex can hold any digits.
    let logged = LOGGED
        .lock()
        .unwrap()
        .iter()
        .filter(|line| line.starts_with("rust"))
        .cloned()
        .collect::<Vec<_>>()
        .join("\n");
    assert!(
        logged.contains("[observer]"),
        "the capture sees the observer"
    );
    assert!(!logged.to_lowercase().contains(&hex));
    assert!(!logged.contains("7731"));
}
