//! The observed chat (phase 5c): read, never write, what the buyer and the
//! seller of a dispute this key holds wrote to each other.
//!
//! **The key.** The parties' own chat is the chat envelope keyed between
//! their two trade keys: ECDH, then HKDF into `K_conv` and `K_sign`
//! (`mostro_core::chat`). A party of ../app discloses `K_conv`'s secret to
//! the solver by sending, in its dispute chat with this key, exactly
//! `"Shared key: "` + 64 hex characters (`share_chat_key_with_solver`,
//! `CHAT_KEY_PREFIX`). It is taken only from a message whose verified inner
//! signer is that party on its own conversation: never from this key's own
//! messages, never from the other party, never in another format (the same
//! check as ../app's `note_chat_key_share_echo`). The solver can also paste
//! one ([`parse_pasted`]): it is kept only when it opens a message of this
//! dispute, and only in memory (`Router::pasted`), forgotten when the key
//! changes or the app stops. No key is stored: a disclosed one is a stored
//! chat message already (accepted limit, A4).
//!
//! **Read only by construction.** `K_conv` decrypts; the outer events are
//! signed by `K_sign`, which is never disclosed. Nothing here builds or
//! publishes an event.
//!
//! **The read.** One query, not a subscription (each REQ counts against the
//! relays' cap per connection): kind 14 with `#p` = `pub(K_conv)` of every
//! known key. `pub(K_sign)` is not known, so there is no `authors` filter
//! (Mostrix `observer_kind14_filter`): whatever else carries that `p` fails
//! to open and is dropped. From a week before the dispute was opened (or
//! taken), with no end: the trade's chat starts before the dispute, and the
//! parties may go on writing after it (Mostrix looks back a week from now,
//! which loses the start of an old dispute). At most [`MAX_EVENTS`].
//!
//! **Checks.** `mostro_core::chat::unwrap_chat_message` with the event's own
//! author as the expected one: one `p` tag, the future bound, the 64 KiB
//! size, both signatures, inner kind 1, the inner/outer time skew. The inner
//! signers allowed are the buyer's and the seller's trade keys the take
//! named (../app signs the inner event with the sender's trade key); anyone
//! else is dropped, never guessed. The inner id is the message's identity.
//!
//! **Attachments** in this chat cannot be opened: ../app encrypts them with
//! the raw ECDH secret of the two trade keys (`send_file` →
//! `attachment_key`), which `K_conv` does not give (HKDF is one-way). They
//! are shown by their name and type, never tried with `K_conv` (Mostrix
//! does; it fails on ../app's files).
//!
//! Nothing logs a key or a message's content.

use std::collections::{HashMap, HashSet};

use mostro_core::chat::unwrap_chat_message;
use nostr_sdk::prelude::{Client, Event, Filter, Keys, Kind, PublicKey, SecretKey, Timestamp};
use zeroize::Zeroizing;

use super::router::{party_key, ChatStore, Router};
use super::{attachment_of, ChannelRef, ChatRecord};
use crate::api::chat::{ChatError, ChatParty};
use crate::api::observer::{KeyDisclosure, ObservedChat, ObservedMessage, ObserverError};
use crate::db::Storage;
use crate::disputes::DisputeRecord;

/// What a party's disclosure starts with (../app `CHAT_KEY_PREFIX`). Fixed
/// and untranslated: the same in every language the parties write.
pub const KEY_PREFIX: &str = "Shared key: ";

/// How long before the dispute was opened a read starts.
pub const LOOKBACK_SECS: i64 = 7 * 24 * 60 * 60;

/// The most events one read asks for (and opens). strfry answers at most 500
/// per filter anyway.
pub const MAX_EVENTS: usize = 500;

/// How long one read waits for the relays (Mostrix `FETCH_EVENTS_TIMEOUT`).
pub const FETCH_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(15);

/// A `K_conv` secret, wiped when dropped.
pub type SharedKey = Zeroizing<[u8; 32]>;

/// 64 hex characters, nothing else, as a key.
fn hex_key(hex: &str) -> Option<SharedKey> {
    if hex.len() != 64 || !hex.bytes().all(|b| b.is_ascii_hexdigit()) {
        return None;
    }
    let mut key = Zeroizing::new([0u8; 32]);
    hex::decode_to_slice(hex, &mut key[..]).ok()?;
    Some(key)
}

/// The key a disclosure message carries: exactly [`KEY_PREFIX`] and 64 hex
/// characters, as ../app writes it and `note_chat_key_share_echo` reads it.
pub fn parse_disclosure(text: &str) -> Option<SharedKey> {
    hex_key(text.strip_prefix(KEY_PREFIX)?)
}

/// A pasted key: the 64 hex characters alone (as Mostrix's Observer takes
/// them) or the whole disclosure line, surrounding spaces aside.
pub fn parse_pasted(bytes: &[u8]) -> Option<SharedKey> {
    let text = std::str::from_utf8(bytes).ok()?.trim();
    hex_key(text.strip_prefix(KEY_PREFIX).unwrap_or(text))
}

/// `K_conv` from its secret; `None` for a value that is not a secret key.
fn conv_keys(key: &SharedKey) -> Option<Keys> {
    SecretKey::from_slice(&key[..]).ok().map(Keys::new)
}

/// One disclosure found in a stored conversation.
pub struct Disclosure {
    pub party: ChatParty,
    pub at: i64,
    pub key: SharedKey,
}

/// The disclosures among `rows`: a message of the party whose conversation
/// it is (its verified sender), in the exact format. This key's own
/// messages and anything else are not looked at.
pub fn disclosures(rows: &[ChatRecord]) -> Vec<Disclosure> {
    rows.iter()
        .filter(|r| r.sender == r.channel.party.sender())
        .filter_map(|r| {
            Some(Disclosure {
                party: r.channel.party,
                at: r.created_at,
                key: parse_disclosure(&r.content)?,
            })
        })
        .collect()
}

/// The newest disclosure of each party, oldest first.
fn newest_per_party(mut all: Vec<Disclosure>) -> Vec<Disclosure> {
    all.sort_by_key(|d| std::cmp::Reverse(d.at));
    let mut seen = HashSet::new();
    let mut newest: Vec<Disclosure> = all.into_iter().filter(|d| seen.insert(d.party)).collect();
    newest.sort_by_key(|d| d.at);
    newest
}

/// Whose observed chat: a node, a dispute and the solver key that reads it
/// (D6). Never a party: the observed chat is one conversation.
#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct ObservedRef {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub solver_pubkey: String,
}

/// One stored message of the observed chat.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct ObservedRecord {
    pub conversation: ObservedRef,
    /// The verified inner event id (hex).
    pub message_id: String,
    /// The verified inner signer: the buyer's or the seller's trade key.
    pub sender: ChatParty,
    pub content: String,
    /// The inner event's `created_at`, as its writer set it.
    pub created_at: i64,
    /// This device's clock when it was read.
    pub received_at: i64,
}

impl ObservedRecord {
    pub fn view(&self) -> ObservedMessage {
        ObservedMessage {
            id: self.message_id.clone(),
            sender: self.sender,
            content: self.content.clone(),
            created_at: self.created_at,
            // It is never opened, so its declared type is all that is shown
            // of it: sanitized too, as its name already is.
            attachment: attachment_of(&self.content).map(|mut a| {
                a.mime_type = label_mime(&a.mime_type);
                a
            }),
        }
    }
}

/// A declared media type fit to show: `type/subtype` in RFC 6838's
/// characters, lower case, at most 100 bytes; empty otherwise.
pub fn label_mime(mime: &str) -> String {
    let mime = mime.trim().to_ascii_lowercase();
    let token = |part: &str| {
        !part.is_empty()
            && part
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || "!#$&^_.+-".contains(c))
    };
    match mime.split_once('/') {
        Some((kind, sub)) if mime.len() <= 100 && token(kind) && token(sub) => mime,
        _ => String::new(),
    }
}

/// What a read of one dispute needs: where it is stored, the conversations
/// a disclosure arrives in, the trade keys allowed to sign, and the start.
pub(crate) struct Scope {
    pub(crate) observed: ObservedRef,
    channels: [ChannelRef; 2],
    signers: Vec<(PublicKey, ChatParty)>,
    since: i64,
}

impl Scope {
    /// The scope of `row`, a dispute `solver` (hex) took on `node`; `None`
    /// when this key does not hold it.
    pub(crate) fn of(row: &DisputeRecord, solver: &str) -> Option<Self> {
        let taken = row.taken.as_ref().filter(|t| t.solver_pubkey == solver)?;
        let channel = |party| ChannelRef {
            mostro_pubkey: row.mostro_pubkey.clone(),
            dispute_id: row.dispute_id.clone(),
            party,
            solver_pubkey: solver.to_string(),
        };
        let signers = [ChatParty::Buyer, ChatParty::Seller]
            .into_iter()
            .filter_map(|party| Some((party_key(row, party)?, party)))
            .collect();
        let start = row
            .opened_at
            .map_or(taken.taken_at, |opened| opened.min(taken.taken_at));
        Some(Self {
            observed: ObservedRef {
                mostro_pubkey: row.mostro_pubkey.clone(),
                dispute_id: row.dispute_id.clone(),
                solver_pubkey: solver.to_string(),
            },
            channels: [channel(ChatParty::Buyer), channel(ChatParty::Seller)],
            signers,
            since: start.saturating_sub(LOOKBACK_SECS).max(0),
        })
    }

    /// The disclosures stored in this dispute's two conversations.
    async fn disclosures(&self, store: &ChatStore) -> Vec<Disclosure> {
        let mut all = Vec::new();
        for channel in &self.channels {
            match store.list(channel).await {
                Ok(rows) => all.extend(disclosures(&rows)),
                Err(e) => log::warn!("[observer] conversation not read: {e}"),
            }
        }
        newest_per_party(all)
    }

    /// The observed chat as stored.
    async fn state(&self, store: &ChatStore, has_pasted_key: bool) -> anyhow::Result<ObservedChat> {
        let mut messages: Vec<ObservedMessage> = store
            .list_observed(&self.observed)
            .await?
            .iter()
            .map(ObservedRecord::view)
            .collect();
        messages.sort_by(|a, b| {
            a.created_at
                .cmp(&b.created_at)
                .then_with(|| a.id.cmp(&b.id))
        });
        Ok(ObservedChat {
            mostro_pubkey: self.observed.mostro_pubkey.clone(),
            dispute_id: self.observed.dispute_id.clone(),
            disclosures: self
                .disclosures(store)
                .await
                .into_iter()
                .map(|d| KeyDisclosure {
                    party: d.party,
                    shared_at: d.at,
                })
                .collect(),
            has_pasted_key,
            since: self.since,
            messages,
        })
    }
}

/// The query of one read: the chat events addressed to any of `convs`.
pub(crate) fn observer_filter(convs: &[Keys], since: i64) -> Filter {
    Filter::new()
        .kind(Kind::PrivateDirectMessage)
        .pubkeys(convs.iter().map(Keys::public_key))
        .since(Timestamp::from_secs(since.max(0) as u64))
        .limit(MAX_EVENTS)
}

/// `event` opened with one of `convs`, if any does and its inner signer is
/// one of `signers`: the party who wrote it and the message.
pub(crate) fn open_event(
    convs: &[Keys],
    signers: &[(PublicKey, ChatParty)],
    event: &Event,
    now: Timestamp,
) -> Option<(ChatParty, mostro_core::chat::ChatMessage)> {
    let allowed: Vec<PublicKey> = signers.iter().map(|(key, _)| *key).collect();
    // The `p` tag is checked first and cheaply: only the key it names gets
    // as far as a signature or a decryption.
    let message = convs
        .iter()
        .find_map(|conv| unwrap_chat_message(conv, &event.pubkey, &allowed, event, now).ok())?;
    let party = signers
        .iter()
        .find(|(key, _)| *key == message.sender)
        .map(|(_, party)| *party)?;
    Some((party, message))
}

/// Ask the relays once and open what comes back. Returns the records to
/// keep, one per inner id, at most [`MAX_EVENTS`].
async fn fetch(
    client: &Client,
    convs: &[Keys],
    scope: &Scope,
) -> Result<Vec<ObservedRecord>, ObserverError> {
    let events = client
        .fetch_events(observer_filter(convs, scope.since))
        .timeout(FETCH_TIMEOUT)
        .await
        .map_err(|e| {
            log::warn!("[observer] relays not asked: {e}");
            ObserverError::FetchFailed
        })?;
    let now = Timestamp::now();
    let received_at = crate::rt::unix_now();
    let mut seen = HashSet::new();
    let mut records = Vec::new();
    let mut dropped = 0usize;
    for event in events.iter().take(MAX_EVENTS) {
        let Some((party, message)) = open_event(convs, &scope.signers, event, now) else {
            dropped += 1;
            continue;
        };
        if !seen.insert(message.inner_event_id) {
            continue;
        }
        records.push(ObservedRecord {
            conversation: scope.observed.clone(),
            message_id: message.inner_event_id.to_hex(),
            sender: party,
            content: message.content,
            created_at: message.created_at.as_secs() as i64,
            received_at,
        });
    }
    log::info!(
        "[observer] {} message(s) opened, {dropped} event(s) dropped",
        records.len()
    );
    Ok(records)
}

impl From<ChatError> for ObserverError {
    fn from(e: ChatError) -> Self {
        match e {
            ChatError::NoKey => ObserverError::NoKey,
            ChatError::NoNode => ObserverError::NoNode,
            ChatError::NoRelays => ObserverError::NoRelays,
            _ => ObserverError::UnknownDispute,
        }
    }
}

/// The pasted keys held now, by observed chat (in memory only).
pub(crate) type PastedKeys = HashMap<ObservedRef, SharedKey>;

impl Router {
    /// The scope of `dispute_id`, a dispute this key holds (or held) on the
    /// active node.
    async fn observer_scope(&self, dispute_id: &str) -> Result<Scope, ObserverError> {
        let conversation = self.conversation(dispute_id, ChatParty::Buyer).await?;
        Scope::of(&conversation.row, &conversation.channel.solver_pubkey)
            .ok_or(ObserverError::UnknownDispute)
    }

    fn pasted_key(&self, observed: &ObservedRef) -> Option<SharedKey> {
        super::router::lock(&self.pasted).get(observed).cloned()
    }

    /// The observed chat of `dispute_id` as stored.
    pub(crate) async fn observed(&self, dispute_id: &str) -> Result<ObservedChat, ObserverError> {
        let scope = self.observer_scope(dispute_id).await?;
        let pasted = self.pasted_key(&scope.observed).is_some();
        self.observed_state(&scope, pasted).await
    }

    async fn observed_state(
        &self,
        scope: &Scope,
        pasted: bool,
    ) -> Result<ObservedChat, ObserverError> {
        scope.state(&self.store, pasted).await.map_err(|e| {
            log::warn!("[observer] not read from storage: {e}");
            ObserverError::UnknownDispute
        })
    }

    /// Keep `records`; a copy of a stored one is not stored twice.
    async fn keep(&self, records: &[ObservedRecord]) {
        for record in records {
            if let Err(e) = self.store.insert_observed(record).await {
                log::warn!("[observer] message not stored: {e}");
            }
        }
    }

    /// Read with every key known for `dispute_id`.
    pub(crate) async fn read_observed(
        &self,
        dispute_id: &str,
    ) -> Result<ObservedChat, ObserverError> {
        let scope = self.observer_scope(dispute_id).await?;
        if scope.signers.is_empty() {
            return Err(ObserverError::NoPartyKeys);
        }
        let pasted = self.pasted_key(&scope.observed);
        let mut keys: Vec<SharedKey> = scope
            .disclosures(&self.store)
            .await
            .into_iter()
            .map(|d| d.key)
            .collect();
        keys.extend(pasted.clone());
        let mut convs: Vec<Keys> = Vec::new();
        for key in &keys {
            if let Some(conv) = conv_keys(key) {
                if !convs.iter().any(|c| c.public_key() == conv.public_key()) {
                    convs.push(conv);
                }
            }
        }
        if convs.is_empty() {
            return Err(ObserverError::NoSharedKey);
        }
        let records = fetch(&self.client, &convs, &scope).await?;
        self.keep(&records).await;
        let state = self.observed_state(&scope, pasted.is_some()).await?;
        if state.messages.is_empty() {
            return Err(ObserverError::KeyOpensNothing);
        }
        Ok(state)
    }

    /// Check a pasted key against the relays and hold it when it opens a
    /// message of `dispute_id`'s buyer or seller.
    pub(crate) async fn paste_observer_key(
        &self,
        dispute_id: &str,
        pasted: &[u8],
    ) -> Result<ObservedChat, ObserverError> {
        let key = parse_pasted(pasted).ok_or(ObserverError::InvalidKey)?;
        let conv = conv_keys(&key).ok_or(ObserverError::InvalidKey)?;
        let scope = self.observer_scope(dispute_id).await?;
        if scope.signers.is_empty() {
            return Err(ObserverError::NoPartyKeys);
        }
        let records = fetch(&self.client, std::slice::from_ref(&conv), &scope).await?;
        if records.is_empty() {
            return Err(ObserverError::KeyOpensNothing);
        }
        self.keep(&records).await;
        super::router::lock(&self.pasted).insert(scope.observed.clone(), key);
        self.observed_state(&scope, true).await
    }
}

// ── The bridge's entry points ─────────────────────────────────────────────────

/// The observed chat of `dispute_id` as stored, also before the relays are
/// up; `None` when the dispute is not this key's on the active node.
pub(crate) async fn stored(dispute_id: &str) -> anyhow::Result<Option<ObservedChat>> {
    let Ok((node, keys)) = super::router::node_and_keys().await else {
        return Ok(None);
    };
    if let Some(router) = super::router::router() {
        return match router.observed(dispute_id).await {
            Ok(state) => Ok(Some(state)),
            Err(ObserverError::UnknownDispute) => Ok(None),
            Err(e) => Err(anyhow::anyhow!("observed chat not read: {e:?}")),
        };
    }
    let Some(db) = crate::db::app_db::db() else {
        return Ok(None);
    };
    let Some(row) = db.get_dispute(&node, dispute_id).await? else {
        return Ok(None);
    };
    let Some(scope) = Scope::of(&row, &keys.public_key().to_hex()) else {
        return Ok(None);
    };
    Ok(Some(scope.state(&ChatStore::Db(db), false).await?))
}

pub(crate) async fn read(dispute_id: &str) -> Result<ObservedChat, ObserverError> {
    super::router::node_and_keys().await?;
    let router = super::router::router().ok_or(ObserverError::NoRelays)?;
    router.read_observed(dispute_id).await
}

pub(crate) async fn paste(
    dispute_id: &str,
    key: Zeroizing<Vec<u8>>,
) -> Result<ObservedChat, ObserverError> {
    super::router::node_and_keys().await?;
    let router = super::router::router().ok_or(ObserverError::NoRelays)?;
    router.paste_observer_key(dispute_id, &key).await
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests;
