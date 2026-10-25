//! A dispute party for the end-to-end chat tests (`integration_test/`): plays
//! the buyer or the seller with their trade key, as a party's client does,
//! through `mostro_core::chat`. Never against a real node or a real party.
//!
//! ```text
//! cargo run --example chat_party -- <relay> <party secret hex> <solver pubkey hex> \
//!     [--say <text>] [--expect <text>] \
//!     [--blossom <url>] [--send-file <path>] [--expect-file <out path>] \
//!     [--peer <other party pubkey hex>] [--share-key] [--print-key] [--print-pubkey]
//! ```
//!
//! `--say` writes `text` to the solver. `--expect` waits (up to 60 s) until a
//! message with exactly `text`, signed by the solver key, is on the relay,
//! and fails otherwise. Prints what it reads as `solver: …` / `party: …`.
//!
//! Attachments, as MostroP2P/app sends and opens them, written here from the
//! format rather than from Bosstro's code, so the run checks one against the
//! other: `--send-file` encrypts the file (JPEG, PNG or PDF) with
//! ChaCha20-Poly1305 under the raw ECDH x of the party's trade key and the
//! solver's pubkey, uploads it to `--blossom` (a local test server,
//! `blossom_server`) with a kind 24242 authorisation signed by a throwaway key,
//! and writes MostroP2P/app's JSON in the chat. `--expect-file` waits for the
//! solver's newest attachment, downloads it, checks its hash against the URL,
//! decrypts it and writes it to the path, printing its type.
//!
//! The parties' own chat (phase 5c), as MostroP2P/app writes it: with `--peer`,
//! the other party's trade pubkey, `--say` and `--send-file` go to the chat
//! between the two parties instead (the envelope keyed between the two trade
//! keys, the inner event signed by this party; a file encrypted under the raw
//! ECDH x of the two trade keys, MostroP2P/app's `send_file`). `--share-key`
//! sends the solver, in this party's dispute chat, `Shared key: ` + the secret
//! of that chat's `K_conv`, as MostroP2P/app's `share_chat_key_with_solver`.
//! `--print-key` prints that secret (`key: …`) for a test to paste, and
//! `--print-pubkey` this party's trade pubkey (`pubkey: …`), the other's peer.

use std::time::Duration;

use base64::Engine;
use chacha20poly1305::aead::{Aead, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use mostro_core::chat::{
    chat_filter, derive_chat_keys, unwrap_chat_message, wrap_chat_message, SharedKey,
};
use nostr_sdk::prelude::*;
use rand::RngCore;
use sha2::{Digest, Sha256};

type Failure = Box<dyn std::error::Error>;

#[tokio::main]
async fn main() -> Result<(), Failure> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let usage = "chat_party <relay> <party secret hex> <solver pubkey hex> [--say T] \
                 [--expect T] [--blossom URL] [--send-file PATH] [--expect-file PATH] \
                 [--peer PUBKEY] [--share-key] [--print-key] [--print-pubkey]";
    let [relay, secret, solver, rest @ ..] = args.as_slice() else {
        return Err(usage.into());
    };
    let (mut say, mut expect, mut blossom, mut send_file, mut expect_file) =
        (None, None, None, None, None);
    let (mut peer, mut share_key, mut print_key, mut print_pubkey) = (None, false, false, false);
    let mut rest = rest.iter();
    while let Some(flag) = rest.next() {
        match flag.as_str() {
            "--share-key" => {
                share_key = true;
                continue;
            }
            "--print-key" => {
                print_key = true;
                continue;
            }
            "--print-pubkey" => {
                print_pubkey = true;
                continue;
            }
            _ => {}
        }
        let value = rest.next().cloned();
        match flag.as_str() {
            "--peer" => peer = value,
            "--say" => say = value,
            "--expect" => expect = value,
            "--blossom" => blossom = value,
            "--send-file" => send_file = value,
            "--expect-file" => expect_file = value,
            _ => return Err(usage.into()),
        }
    }

    let party = Keys::parse(secret)?;
    if print_pubkey {
        println!("pubkey: {}", party.public_key().to_hex());
        return Ok(());
    }
    let solver = PublicKey::parse(solver)?;
    let (conv, sign) = derive_chat_keys(&party, &solver)?;
    let peer = peer.map(|p| PublicKey::parse(&p)).transpose()?;
    // Where `--say` and `--send-file` go: the solver, or the other party.
    let (to, (to_conv, to_sign)) = match peer {
        Some(peer) => (peer, derive_chat_keys(&party, &peer)?),
        None => (solver, (conv.clone(), sign.clone())),
    };
    if print_key {
        let peer = peer.ok_or("--print-key needs --peer")?;
        let (p2p, _) = derive_chat_keys(&party, &peer)?;
        println!("key: {}", p2p.secret_key().to_secret_hex());
        return Ok(());
    }
    let client = Client::new();
    client.add_relay(relay.as_str()).await?;
    client.connect().and_wait(Duration::from_secs(5)).await;

    if let Some(path) = send_file {
        let server = blossom.as_deref().ok_or("--send-file needs --blossom")?;
        say = Some(upload_file(&party, &to, &path, server).await?);
    }

    if let Some(text) = say {
        let event = wrap_chat_message(&party, &to_conv, &to_sign, &text).await?;
        let output = client.send_event(&event).await?;
        if output.success.is_empty() {
            return Err("no relay took the message".into());
        }
        println!("sent: {text}");
    }

    if share_key {
        let peer = peer.ok_or("--share-key needs --peer")?;
        let (p2p, _) = derive_chat_keys(&party, &peer)?;
        let text = format!("Shared key: {}", p2p.secret_key().to_secret_hex());
        let event = wrap_chat_message(&party, &conv, &sign, &text).await?;
        let output = client.send_event(&event).await?;
        if output.success.is_empty() {
            return Err("no relay took the key".into());
        }
        println!("shared the chat key with the solver");
    }

    let allowed = [party.public_key(), solver];
    if let Some(out) = expect_file {
        for _ in 0..30 {
            let events = client
                .fetch_events(chat_filter(sign.public_key()))
                .timeout(Duration::from_secs(5))
                .await?;
            // The solver's newest attachment.
            let newest = events
                .iter()
                .filter_map(|e| {
                    unwrap_chat_message(&conv, &sign.public_key(), &allowed, e, Timestamp::now())
                        .ok()
                })
                .filter(|m| m.sender == solver)
                .filter_map(|m| {
                    let json: serde_json::Value = serde_json::from_str(&m.content).ok()?;
                    let kind = json["type"].as_str()?;
                    matches!(kind, "image_encrypted" | "file_encrypted")
                        .then_some((m.created_at, json))
                })
                .max_by_key(|(at, _)| *at);
            if let Some((_, json)) = newest {
                let bytes = download_file(&party, &solver, &json).await?;
                std::fs::write(&out, &bytes)?;
                println!(
                    "received {} ({} bytes, {}) to {out}",
                    json["filename"],
                    bytes.len(),
                    sniff(&bytes).unwrap_or("unknown type")
                );
                return Ok(());
            }
            tokio::time::sleep(Duration::from_secs(2)).await;
        }
        return Err("the solver's file never arrived".into());
    }

    let Some(expected) = expect else {
        return Ok(());
    };
    for _ in 0..30 {
        let events = client
            .fetch_events(chat_filter(sign.public_key()))
            .timeout(Duration::from_secs(5))
            .await?;
        let mut found = false;
        for event in events.iter() {
            let Ok(message) =
                unwrap_chat_message(&conv, &sign.public_key(), &allowed, event, Timestamp::now())
            else {
                continue;
            };
            let who = if message.sender == solver {
                "solver"
            } else {
                "party"
            };
            println!("{who}: {}", message.content);
            found |= message.sender == solver && message.content == expected;
        }
        if found {
            println!("expected message received");
            return Ok(());
        }
        tokio::time::sleep(Duration::from_secs(2)).await;
    }
    Err(format!("the solver's message {expected:?} never arrived").into())
}

/// The file key: the raw ECDH x-coordinate, unhashed, as MostroP2P/app, with
/// the solver or (in the parties' own chat) the other party.
fn file_key(party: &Keys, counterpart: &PublicKey) -> Result<[u8; 32], Failure> {
    let shared = SharedKey::derive(party.secret_key(), counterpart)?;
    Ok(shared.keys().secret_key().to_secret_bytes())
}

fn sniff(bytes: &[u8]) -> Option<&'static str> {
    if bytes.starts_with(&[0xFF, 0xD8, 0xFF]) {
        Some("image/jpeg")
    } else if bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        Some("image/png")
    } else if bytes.starts_with(b"%PDF-") {
        Some("application/pdf")
    } else {
        None
    }
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

/// Encrypt and upload the file at `path` for `counterpart`; the JSON message
/// MostroP2P/app writes.
async fn upload_file(
    party: &Keys,
    counterpart: &PublicKey,
    path: &str,
    server: &str,
) -> Result<String, Failure> {
    let file = std::fs::read(path)?;
    let mime = sniff(&file).ok_or("not a JPEG, PNG or PDF")?;
    let mut nonce = [0u8; 12];
    rand::rngs::OsRng.fill_bytes(&mut nonce);
    let cipher = ChaCha20Poly1305::new(&file_key(party, counterpart)?.into());
    let sealed = cipher
        .encrypt(Nonce::from_slice(&nonce), file.as_slice())
        .map_err(|e| format!("encryption failed: {e}"))?;
    let blob = [nonce.as_slice(), &sealed].concat();
    let sha = hex(&Sha256::digest(&blob));

    let auth = EventBuilder::new(Kind::Custom(24242), "Upload attachment")
        .tag(Tag::parse(["t", "upload"])?)
        .tag(Tag::parse(["x", &sha])?)
        .tag(Tag::parse([
            "expiration",
            &(Timestamp::now().as_secs() + 3600).to_string(),
        ])?)
        .finalize(&Keys::generate())?;
    let server = server.trim_end_matches('/');
    let response = reqwest::Client::new()
        .put(format!("{server}/upload"))
        .header("Content-Type", "application/octet-stream")
        .header(
            "Authorization",
            format!(
                "Nostr {}",
                base64::engine::general_purpose::STANDARD.encode(auth.as_json())
            ),
        )
        .body(blob.clone())
        .send()
        .await?;
    if !response.status().is_success() {
        return Err(format!("upload refused: {}", response.status()).into());
    }

    let name = std::path::Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("attachment");
    let url = format!("{server}/{sha}");
    let json = if mime == "application/pdf" {
        serde_json::json!({
            "type": "file_encrypted", "file_type": "document", "blossom_url": url,
            "nonce": hex(&nonce), "mime_type": mime, "original_size": file.len(),
            "filename": name, "encrypted_size": blob.len(),
        })
    } else {
        let (width, height) = image::ImageReader::new(std::io::Cursor::new(&file))
            .with_guessed_format()?
            .into_dimensions()?;
        serde_json::json!({
            "type": "image_encrypted", "blossom_url": url, "nonce": hex(&nonce),
            "mime_type": mime, "original_size": file.len(), "width": width,
            "height": height, "filename": name, "encrypted_size": blob.len(),
        })
    };
    println!("uploaded {name} ({} bytes) as {sha}", file.len());
    Ok(json.to_string())
}

/// Download, verify and decrypt the file a JSON message names.
async fn download_file(
    party: &Keys,
    solver: &PublicKey,
    json: &serde_json::Value,
) -> Result<Vec<u8>, Failure> {
    let url = json["blossom_url"].as_str().ok_or("no blossom_url")?;
    let named = url
        .rsplit('/')
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase();
    let blob = reqwest::get(url).await?.error_for_status()?.bytes().await?;
    if hex(&Sha256::digest(&blob)) != named {
        return Err("the blob does not match its hash".into());
    }
    if blob.len() < 28 {
        return Err("the blob is too short".into());
    }
    let (nonce, sealed) = blob.split_at(12);
    let cipher = ChaCha20Poly1305::new(&file_key(party, solver)?.into());
    cipher
        .decrypt(Nonce::from_slice(nonce), sealed)
        .map_err(|e| format!("the file does not open with this key: {e}").into())
}
