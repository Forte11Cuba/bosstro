//! A dispute party for the end-to-end chat test (`integration_test/`): plays
//! the buyer or the seller with their trade key, as a party's client does,
//! through `mostro_core::chat`. Never against a real node or a real party.
//!
//! ```text
//! cargo run --example chat_party -- <relay> <party secret hex> <solver pubkey hex> \
//!     [--say <text>] [--expect <text>]
//! ```
//!
//! `--say` writes `text` to the solver. `--expect` waits (up to 60 s) until a
//! message with exactly `text`, signed by the solver key, is on the relay,
//! and fails otherwise. Prints what it reads as `solver: …` / `party: …`.

use std::time::Duration;

use mostro_core::chat::{chat_filter, derive_chat_keys, unwrap_chat_message, wrap_chat_message};
use nostr_sdk::prelude::*;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let usage = "chat_party <relay> <party secret hex> <solver pubkey hex> [--say T] [--expect T]";
    let [relay, secret, solver, rest @ ..] = args.as_slice() else {
        return Err(usage.into());
    };
    let (mut say, mut expect) = (None, None);
    let mut rest = rest.iter();
    while let Some(flag) = rest.next() {
        match flag.as_str() {
            "--say" => say = rest.next().cloned(),
            "--expect" => expect = rest.next().cloned(),
            _ => return Err(usage.into()),
        }
    }

    let party = Keys::parse(secret)?;
    let solver = PublicKey::parse(solver)?;
    let (conv, sign) = derive_chat_keys(&party, &solver)?;
    let client = Client::new();
    client.add_relay(relay.as_str()).await?;
    client.connect().and_wait(Duration::from_secs(5)).await;

    if let Some(text) = say {
        let event = wrap_chat_message(&party, &conv, &sign, &text).await?;
        let output = client.send_event(&event).await?;
        if output.success.is_empty() {
            return Err("no relay took the message".into());
        }
        println!("sent: {text}");
    }

    let Some(expected) = expect else {
        return Ok(());
    };
    let allowed = [party.public_key(), solver];
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
