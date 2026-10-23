//! The dispute chat (phase 5): one conversation with each party of every
//! dispute this solver key holds.
//!
//! **Keys.** Each party's channel starts from the ECDH secret between the
//! solver key and that party's trade key (the `buyer_pubkey` /
//! `seller_pubkey` of the take's `SolverDisputeInfo`), the same secret the
//! party computes from its trade key and the solver's pubkey (Mostrix
//! `derive_shared_keys`). HKDF splits it into `K_conv` (NIP-44 and the outer
//! `p` tag) and `K_sign` (the outer author): `mostro_core::chat`. Mostrix
//! persists the ECDH secret; Bosstro's database is not encrypted (SQLCipher
//! is post-MVP), so the keys are derived in memory from the loaded solver key
//! and forgotten with it (a log out, another key). Nothing secret is stored.
//!
//! **Messages.** A kind 14 signed by `K_sign`, `p` = `pub(K_conv)`, carrying a
//! NIP-44 kind 1 signed by whoever writes. The inner signers allowed are the
//! party's trade key and this solver key, nothing else (Mostrix
//! `dispute_chat_allowed_signers`); an unknown signer is dropped, never
//! guessed (`dispute_chat_role_for_inner_signer` fails closed). Nothing reads
//! or writes kind 1059. A message's content is never logged.
//!
//! - [`router`] follows the channels of the active node and key, receives,
//!   stores and sends.

pub mod router;

use std::collections::{HashMap, HashSet, VecDeque};
use std::hash::Hash;

use mostro_core::chat::derive_chat_keys;
use nostr_sdk::prelude::{EventId, Keys, PublicKey};

use crate::api::chat::{
    ChatAttachment, ChatAttachmentKind, ChatDelivery, ChatMessageView, ChatParty, ChatSender,
};

/// The longest message this app sends, in UTF-8 bytes. The spec bounds the
/// encrypted payload at 64 KiB; a 16 KiB text stays well under it once
/// signed, wrapped and base64-encoded.
pub const MAX_MESSAGE_BYTES: usize = 16 * 1024;

/// How far before the cursor a subscription starts again: a message of the
/// cursor's own second, or one dated a little behind it, is not missed. The
/// copies cost an id lookup.
pub const CURSOR_OVERLAP_SECS: i64 = 60;

/// The most `pub(K_sign)` authors one REQ carries; past it the channels are
/// split into a few REQs. No relay we use documents a cap on a filter's
/// authors, but some refuse very large filters: 100 authors are 50 disputes
/// held at once, far past what one solver works on.
pub const MAX_AUTHORS_PER_REQ: usize = 100;

/// Sustained chat events per conversation and minute, and the burst: the
/// spec's token bucket (Mostrix `chat_security`).
pub const RATE_PER_MINUTE: f64 = 30.0;
pub const RATE_BURST: f64 = 60.0;

/// How many outer event ids are remembered (each relay sends a copy).
pub const SEEN_OUTER_CAPACITY: usize = 4096;

impl ChatParty {
    pub fn as_wire(self) -> &'static str {
        match self {
            ChatParty::Buyer => "buyer",
            ChatParty::Seller => "seller",
        }
    }

    pub fn from_wire(value: &str) -> Option<Self> {
        match value {
            "buyer" => Some(ChatParty::Buyer),
            "seller" => Some(ChatParty::Seller),
            _ => None,
        }
    }

    /// The sender a message of this party reads as.
    pub fn sender(self) -> ChatSender {
        match self {
            ChatParty::Buyer => ChatSender::Buyer,
            ChatParty::Seller => ChatSender::Seller,
        }
    }
}

impl ChatSender {
    pub fn as_wire(self) -> &'static str {
        match self {
            ChatSender::Buyer => "buyer",
            ChatSender::Seller => "seller",
            ChatSender::You => "you",
        }
    }

    pub fn from_wire(value: &str) -> Option<Self> {
        match value {
            "buyer" => Some(ChatSender::Buyer),
            "seller" => Some(ChatSender::Seller),
            "you" => Some(ChatSender::You),
            _ => None,
        }
    }
}

impl ChatDelivery {
    pub fn as_wire(self) -> &'static str {
        match self {
            ChatDelivery::Sending => "sending",
            ChatDelivery::Sent => "sent",
            ChatDelivery::Failed => "failed",
        }
    }

    pub fn from_wire(value: &str) -> Option<Self> {
        match value {
            "sending" => Some(ChatDelivery::Sending),
            "sent" => Some(ChatDelivery::Sent),
            "failed" => Some(ChatDelivery::Failed),
            _ => None,
        }
    }
}

/// Which conversation: a node, a dispute, a party, and the solver key that
/// holds it (all hex but the dispute id, a UUID). Rows are keyed by all four
/// (D6), so neither a node switch nor another key mixes them.
#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct ChannelRef {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub party: ChatParty,
    pub solver_pubkey: String,
}

/// One stored message.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct ChatRecord {
    pub channel: ChannelRef,
    /// The verified inner event id (hex).
    pub message_id: String,
    pub sender: ChatSender,
    pub content: String,
    /// The inner event's `created_at`, as its writer set it.
    pub created_at: i64,
    /// This device's clock when it was accepted or sent.
    pub received_at: i64,
    pub delivery: ChatDelivery,
}

impl ChatRecord {
    /// What this message moves the cursor to: `min(created_at, received_at)`,
    /// so a message dated in the future never moves it past the local clock
    /// (else it would silence the conversation until that date).
    pub fn cursor(&self) -> i64 {
        clamp_since(self.created_at, self.received_at)
    }

    /// The message as the chat shows it. One of this key's still `Sending`
    /// that no send is working on (the app stopped meanwhile) reads `Failed`.
    pub fn view(&self, in_flight: bool) -> ChatMessageView {
        let delivery = match self.delivery {
            ChatDelivery::Sending if !in_flight => ChatDelivery::Failed,
            other => other,
        };
        ChatMessageView {
            id: self.message_id.clone(),
            sender: self.sender,
            content: self.content.clone(),
            created_at: self.created_at,
            delivery,
            attachment: attachment_of(&self.content),
        }
    }
}

/// The attachment a message's text declares, if it is a well-formed one.
pub fn attachment_of(content: &str) -> Option<ChatAttachment> {
    let a = crate::attachments::payload::parse(content)?;
    Some(ChatAttachment {
        kind: if a.is_image {
            ChatAttachmentKind::Image
        } else {
            ChatAttachmentKind::File
        },
        file_name: a.file_name,
        mime_type: a.mime_type,
        // At most 25 MiB: `parse` refuses more.
        size: u32::try_from(a.original_size).unwrap_or(u32::MAX),
        width: a.width,
        height: a.height,
    })
}

/// The spec's cursor rule: `min(accepted, local_now)` (Mostrix
/// `clamp_chat_since_cursor`).
pub fn clamp_since(accepted: i64, local_now: i64) -> i64 {
    accepted.min(local_now)
}

/// Where a channel's subscription starts. With messages stored, a little
/// before the cursor, and never past `now`. Without, a little before the
/// dispute could first be written to: its open time when the 38386 gave one
/// (a dispute recovered on a new device keeps its history), else the take.
pub fn subscription_since(
    cursor: Option<i64>,
    opened_at: Option<i64>,
    taken_at: i64,
    now: i64,
) -> i64 {
    let start = match cursor {
        Some(cursor) => clamp_since(cursor, now),
        None => opened_at.map_or(taken_at, |opened| opened.min(taken_at)),
    };
    start.min(now).saturating_sub(CURSOR_OVERLAP_SECS).max(0)
}

/// `(K_conv, K_sign)` of the channel between `solver` and a party's trade
/// key: ECDH, then HKDF (`mostro_core::chat`). The party derives the same
/// pair from its trade key and the solver's pubkey.
pub fn channel_keys(solver: &Keys, party: &PublicKey) -> anyhow::Result<(Keys, Keys)> {
    derive_chat_keys(solver, party).map_err(|e| anyhow::anyhow!("chat keys not derived: {e}"))
}

/// The inner signers accepted on a party's channel: that party's trade key
/// and this solver key, nothing else (Mostrix `dispute_chat_allowed_signers`).
pub fn allowed_signers(solver: &PublicKey, party: &PublicKey) -> Vec<PublicKey> {
    if solver == party {
        vec![*party]
    } else {
        vec![*party, *solver]
    }
}

/// Who wrote a message on `party`'s channel, from its verified inner signer;
/// `None` for anyone else (fail closed: never guessed).
pub fn sender_of(
    signer: &PublicKey,
    solver: &PublicKey,
    party: ChatParty,
    party_key: &PublicKey,
) -> Option<ChatSender> {
    if signer == solver {
        Some(ChatSender::You)
    } else if signer == party_key {
        Some(party.sender())
    } else {
        None
    }
}

/// Bounded set of recently handled outer event ids, oldest out first: the
/// spec's pre-decryption filter against copies from other relays. Not a
/// security boundary (the inner id is the durable dedup).
#[derive(Debug, Default)]
pub struct SeenOuter {
    ids: HashSet<EventId>,
    order: VecDeque<EventId>,
}

impl SeenOuter {
    pub fn contains(&self, id: &EventId) -> bool {
        self.ids.contains(id)
    }

    pub fn insert(&mut self, id: EventId) {
        if !self.ids.insert(id) {
            return;
        }
        self.order.push_back(id);
        if self.order.len() > SEEN_OUTER_CAPACITY {
            if let Some(oldest) = self.order.pop_front() {
                self.ids.remove(&oldest);
            }
        }
    }

    #[cfg(test)]
    pub fn len(&self) -> usize {
        self.ids.len()
    }
}

/// A token bucket per conversation: how much decryption a party can force.
/// Times are seconds on a monotonic clock, passed in so tests drive it.
#[derive(Debug)]
pub struct RateLimits<K> {
    buckets: HashMap<K, (f64, f64)>,
}

impl<K> Default for RateLimits<K> {
    fn default() -> Self {
        Self {
            buckets: HashMap::new(),
        }
    }
}

impl<K: Eq + Hash + Clone> RateLimits<K> {
    /// Whether one more event of `key` may be decrypted at `now`.
    pub fn allow(&mut self, key: &K, now: f64) -> bool {
        let (tokens, last) = self.buckets.entry(key.clone()).or_insert((RATE_BURST, now));
        let elapsed = (now - *last).max(0.0);
        *last = now;
        *tokens = (*tokens + elapsed * RATE_PER_MINUTE / 60.0).min(RATE_BURST);
        if *tokens >= 1.0 {
            *tokens -= 1.0;
            true
        } else {
            false
        }
    }

    pub fn remove(&mut self, key: &K) {
        self.buckets.remove(key);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The spec's test vector (<https://mostro.network/protocol/chat.html#test-vector>),
    /// with the solver as one side and a party's trade key as the other: both
    /// derive the same `K_conv` and `K_sign`.
    #[test]
    fn the_channel_keys_match_the_spec_vector_from_both_sides() {
        let solver =
            Keys::parse("548f68890c49fa42f104c60352395e60ff030b0b407e955f1eed1400d6c0347a")
                .unwrap();
        let party = Keys::parse("f258e73f07386d37133718b6127f873dd7c391b8f43b331ff8254034a13d2943")
            .unwrap();
        let (conv, sign) = channel_keys(&solver, &party.public_key()).unwrap();
        assert_eq!(
            conv.public_key().to_hex(),
            "bceb1cd2a8e98ee9729122a1693edcc39c3ace04582ff96a26705c5e4078a6f2"
        );
        assert_eq!(
            sign.public_key().to_hex(),
            "1dba04571059183f76b148119cfa6f8004dad30cb4e810180a6df17386a7f0b4"
        );
        let (their_conv, their_sign) = channel_keys(&party, &solver.public_key()).unwrap();
        assert_eq!(their_conv.public_key(), conv.public_key());
        assert_eq!(their_sign.public_key(), sign.public_key());
    }

    #[test]
    fn the_buyer_and_seller_channels_differ() {
        let solver = Keys::generate();
        let (buyer, seller) = (Keys::generate(), Keys::generate());
        let b = channel_keys(&solver, &buyer.public_key()).unwrap();
        let s = channel_keys(&solver, &seller.public_key()).unwrap();
        assert_ne!(b.1.public_key(), s.1.public_key());
        assert_ne!(b.0.public_key(), s.0.public_key());
    }

    #[test]
    fn only_the_party_and_the_solver_may_sign_and_nobody_else_is_guessed() {
        let solver = Keys::generate().public_key();
        let buyer = Keys::generate().public_key();
        let seller = Keys::generate().public_key();
        assert_eq!(allowed_signers(&solver, &buyer), vec![buyer, solver]);
        assert_eq!(
            sender_of(&solver, &solver, ChatParty::Buyer, &buyer),
            Some(ChatSender::You)
        );
        assert_eq!(
            sender_of(&buyer, &solver, ChatParty::Buyer, &buyer),
            Some(ChatSender::Buyer)
        );
        // The seller on the buyer's channel is a stranger there.
        assert_eq!(sender_of(&seller, &solver, ChatParty::Buyer, &buyer), None);
        let stranger = Keys::generate().public_key();
        assert_eq!(
            sender_of(&stranger, &solver, ChatParty::Seller, &seller),
            None
        );
    }

    /// A message dated in the future never moves the cursor past the clock.
    #[test]
    fn the_cursor_is_clamped_to_the_local_clock() {
        assert_eq!(clamp_since(2_000, 1_000), 1_000);
        assert_eq!(clamp_since(900, 1_000), 900);
        let record = ChatRecord {
            channel: ChannelRef {
                mostro_pubkey: "aa".into(),
                dispute_id: "d".into(),
                party: ChatParty::Buyer,
                solver_pubkey: "bb".into(),
            },
            message_id: "m".into(),
            sender: ChatSender::Buyer,
            content: String::new(),
            created_at: 10_000_000,
            received_at: 1_000,
            delivery: ChatDelivery::Sent,
        };
        assert_eq!(record.cursor(), 1_000);
        // And the subscription starts before the clock, whatever is stored.
        assert!(subscription_since(Some(10_000_000), None, 0, 1_000) <= 1_000);
    }

    #[test]
    fn the_first_subscription_reaches_back_to_the_dispute() {
        // Opened before the take (a recovery on another device): from the open.
        assert_eq!(
            subscription_since(None, Some(500), 2_000, 3_000),
            500 - CURSOR_OVERLAP_SECS
        );
        // No open time: from the take.
        assert_eq!(
            subscription_since(None, None, 2_000, 3_000),
            2_000 - CURSOR_OVERLAP_SECS
        );
        // A cursor wins, with the overlap.
        assert_eq!(
            subscription_since(Some(2_500), Some(500), 2_000, 3_000),
            2_500 - CURSOR_OVERLAP_SECS
        );
    }

    #[test]
    fn a_sending_message_nobody_sends_reads_failed() {
        let mut record = ChatRecord {
            channel: ChannelRef {
                mostro_pubkey: "aa".into(),
                dispute_id: "d".into(),
                party: ChatParty::Seller,
                solver_pubkey: "bb".into(),
            },
            message_id: "m".into(),
            sender: ChatSender::You,
            content: "hi".into(),
            created_at: 1,
            received_at: 1,
            delivery: ChatDelivery::Sending,
        };
        assert_eq!(record.view(true).delivery, ChatDelivery::Sending);
        assert_eq!(record.view(false).delivery, ChatDelivery::Failed);
        record.delivery = ChatDelivery::Sent;
        assert_eq!(record.view(false).delivery, ChatDelivery::Sent);
    }

    #[test]
    fn the_rate_limit_allows_a_burst_then_thirty_a_minute() {
        let mut limits = RateLimits::default();
        let allowed = (0..100).filter(|_| limits.allow(&"c", 0.0)).count();
        assert_eq!(allowed, RATE_BURST as usize);
        // Two seconds later: one more token.
        assert!(limits.allow(&"c", 2.0));
        assert!(!limits.allow(&"c", 2.0));
        // Another conversation has its own bucket.
        assert!(limits.allow(&"other", 2.0));
    }

    #[test]
    fn seen_outer_ids_are_bounded_oldest_first() {
        let mut seen = SeenOuter::default();
        let ids: Vec<EventId> = (0..=SEEN_OUTER_CAPACITY)
            .map(|n| {
                let mut bytes = [0u8; 32];
                bytes[..8].copy_from_slice(&(n as u64).to_be_bytes());
                EventId::from_byte_array(bytes)
            })
            .collect();
        for id in &ids {
            seen.insert(*id);
        }
        assert_eq!(seen.len(), SEEN_OUTER_CAPACITY);
        assert!(!seen.contains(&ids[0]));
        assert!(seen.contains(ids.last().unwrap()));
    }
}
