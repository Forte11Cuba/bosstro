//! The observed chat (phase 5c), across the bridge: what the buyer and the
//! seller of a dispute this key holds wrote to each other in their own chat,
//! read with the key of that conversation.
//!
//! A party of MostroP2P/app sends the solver, in its dispute chat, the text
//! `"Shared key: "` + the 64-hex secret of its trade's `K_conv`
//! (`share_chat_key_with_solver`). `K_conv` decrypts the conversation but
//! cannot sign as its `pub(K_sign)`, so the grant is read only by
//! construction (<https://mostro.network/protocol/chat.html>). The solver
//! can also paste such a key. Nothing is ever sent on that conversation:
//! this module has no way to.
//!
//! The read is a one-off query, never a live subscription: a long-lived REQ
//! would count against the relays' cap per connection (phase 5). The
//! messages read are kept (`observed_messages`), apart from the solver's own
//! conversations. A pasted key lives in memory only.
//!
//! Rust does not translate: refusals are markers Dart words.

use anyhow::Result;

use crate::api::chat::{ChatAttachment, ChatParty};

/// A party sent this key the key of its chat with the other party.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyDisclosure {
    /// Who sent it: the verified inner signer of the message, on that
    /// party's own conversation with this key.
    pub party: ChatParty,
    /// When (the message's `created_at`, Unix seconds).
    pub shared_at: i64,
}

/// One message of the observed chat. The content is the party's own text:
/// shown as plain text, never as links or markup.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ObservedMessage {
    /// The inner event id (hex): the message's identity.
    pub id: String,
    /// Who wrote it, from its verified inner signer.
    pub sender: ChatParty,
    /// The text; for an attachment, its JSON (not shown).
    pub content: String,
    /// The inner event's `created_at` (Unix seconds), as the writer set it.
    pub created_at: i64,
    /// Set when the text is a well-formed attachment. It cannot be opened:
    /// MostroP2P/app encrypts the files of this chat with the raw ECDH secret
    /// of the two trade keys, which the shared key does not give.
    pub attachment: Option<ChatAttachment>,
}

/// The observed chat of one dispute as stored, and what can read more.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ObservedChat {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    /// The newest disclosure of each party, oldest first.
    pub disclosures: Vec<KeyDisclosure>,
    /// A key pasted for this dispute is held (in memory, until the app stops
    /// or the key changes).
    pub has_pasted_key: bool,
    /// Where a read starts (Unix seconds): a week before the dispute was
    /// opened (or taken, when its open time is not known).
    pub since: i64,
    /// Oldest first.
    pub messages: Vec<ObservedMessage>,
}

/// Why the observed chat was not read. Dart maps each marker to its copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ObserverError {
    /// No solver key is loaded.
    NoKey,
    /// No node is chosen.
    NoNode,
    /// The relay pool is not running.
    NoRelays,
    /// The dispute is not one this key holds (or held) on the active node.
    UnknownDispute,
    /// The node's answer to the take named neither party's trade key, so no
    /// message could be told to come from either.
    NoPartyKeys,
    /// No party shared its key and none was pasted.
    NoSharedKey,
    /// What was pasted is not a key: 64 hexadecimal characters, alone or
    /// after `Shared key: `.
    InvalidKey,
    /// The key opens no message of this dispute's buyer or seller since
    /// [`ObservedChat::since`]: it is another conversation's, or they did
    /// not write.
    KeyOpensNothing,
    /// The relays could not be asked. Try again.
    FetchFailed,
}

/// The observed chat of `dispute_id` as stored, without asking the relays;
/// `None` when the dispute is not this key's on the active node.
pub async fn observed_chat(dispute_id: String) -> Result<Option<ObservedChat>> {
    crate::chat::observer::stored(&dispute_id).await
}

/// Ask the relays for the observed chat of `dispute_id` with every key known
/// for it (the parties' disclosures, a pasted one), keep what opens, and
/// return it all. `KeyOpensNothing` when nothing opens and nothing was kept
/// before.
pub async fn read_observed_chat(dispute_id: String) -> Result<ObservedChat, ObserverError> {
    crate::chat::observer::read(&dispute_id).await
}

/// Check `key` (pasted by the solver; `Shared key: ` and surrounding spaces
/// allowed) against the relays: it is kept, in memory, only when it opens at
/// least one message of this dispute's buyer or seller, and what it opened
/// is stored. The bytes are wiped once read.
pub async fn paste_shared_key(
    dispute_id: String,
    key: Vec<u8>,
) -> Result<ObservedChat, ObserverError> {
    crate::chat::observer::paste(&dispute_id, zeroize::Zeroizing::new(key)).await
}
