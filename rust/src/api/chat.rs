//! The dispute chat (phase 5), across the bridge: one conversation with the
//! buyer and one with the seller of each dispute this key holds.
//!
//! The wire is the Mostro chat envelope (<https://mostro.network/protocol/dispute_chat.html>),
//! keyed between the solver key and each party's trade key (`crate::chat`).
//! Rust keeps the messages (one row per channel and inner event id) and
//! announces every change on [`on_chat_updates`]; Dart reads the thread again.
//!
//! Rust does not translate: states and refusals are markers Dart words.

use anyhow::Result;

/// Which party a conversation is with.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ChatParty {
    Buyer,
    Seller,
}

/// Who wrote a message, from its verified inner signer: the party of the
/// conversation, or this solver key.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ChatSender {
    Buyer,
    Seller,
    You,
}

/// Where a message of this key stands. The party's are always `Sent`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ChatDelivery {
    /// Being sent now.
    Sending,
    /// At least one relay took it (or it came back from one).
    Sent,
    /// No relay took it, or the app stopped while it was being sent. It is
    /// not sent again by itself: the solver retries.
    Failed,
}

/// Whether the conversation can be written to.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChatChannelState {
    /// The dispute is in progress and the party's trade key is known.
    Open,
    /// The dispute is over (its 38386 is terminal): read only.
    Closed,
    /// The node's answer to the take did not name this party's trade key, so
    /// there is no conversation with them.
    NoPartyKey,
}

/// One message as the chat shows it. The content is the party's own text:
/// shown as plain text, never as links or markup.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChatMessageView {
    /// The inner event id (hex): the message's identity.
    pub id: String,
    pub sender: ChatSender,
    pub content: String,
    /// The inner event's `created_at` (Unix seconds), as the writer set it.
    pub created_at: i64,
    pub delivery: ChatDelivery,
}

/// One conversation of a dispute, oldest message first.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChatThread {
    pub mostro_pubkey: String,
    pub dispute_id: String,
    pub party: ChatParty,
    pub state: ChatChannelState,
    pub messages: Vec<ChatMessageView>,
}

/// Something changed in a conversation. With `dispute_id` and `party` set,
/// that conversation; without them (the reader fell behind), any of the
/// node's, and Dart reads again what it shows.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChatUpdate {
    pub mostro_pubkey: String,
    pub dispute_id: Option<String>,
    pub party: Option<ChatParty>,
}

/// Why a message was not sent. Dart maps each marker to its copy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChatError {
    /// No solver key is loaded.
    NoKey,
    /// No node is chosen.
    NoNode,
    /// The relay pool is not running.
    NoRelays,
    /// The dispute is not one this key holds on the active node.
    UnknownDispute,
    /// The dispute is over: its chat is read only.
    Closed,
    /// The party's trade key is not known.
    NoPartyKey,
    /// Nothing to send once surrounding spaces are removed.
    Empty,
    /// Longer than [`crate::chat::MAX_MESSAGE_BYTES`].
    TooLong,
    /// The message to retry is not one of this key's unsent messages.
    UnknownMessage,
}

/// The conversation with `party` of `dispute_id`, a dispute this key holds
/// (or held until it closed) on the active node; `None` otherwise.
pub async fn chat_thread(dispute_id: String, party: ChatParty) -> Result<Option<ChatThread>> {
    crate::chat::router::thread(&dispute_id, party).await
}

/// Send `text` to `party`. Returns the message as stored, `Sending`; its
/// delivery arrives as a [`ChatUpdate`]. Surrounding spaces are removed.
pub async fn send_chat_message(
    dispute_id: String,
    party: ChatParty,
    text: String,
) -> Result<ChatMessageView, ChatError> {
    crate::chat::router::send(&dispute_id, party, &text).await
}

/// Send again a message of this key that failed: it goes as a new message
/// (a new id and time, so a party already past the old time still gets it),
/// which replaces the failed one.
pub async fn retry_chat_message(
    dispute_id: String,
    party: ChatParty,
    message_id: String,
) -> Result<ChatMessageView, ChatError> {
    crate::chat::router::retry(&dispute_id, party, &message_id).await
}

/// Stream of conversation changes for whichever node is active.
pub fn on_chat_updates() -> ChatUpdateStream {
    ChatUpdateStream {
        rx: crate::chat::router::subscribe_updates(),
    }
}

/// Wrapper so flutter_rust_bridge can hand Dart a pull-based stream.
pub struct ChatUpdateStream {
    rx: tokio::sync::broadcast::Receiver<ChatUpdate>,
}

impl ChatUpdateStream {
    /// The next update, or `None` once the router is gone. A reader that
    /// fell behind gets one update naming no conversation: read again.
    pub async fn next(&mut self) -> Option<ChatUpdate> {
        use tokio::sync::broadcast::error::RecvError;
        match self.rx.recv().await {
            Ok(update) => Some(update),
            Err(RecvError::Lagged(_)) => {
                self.rx = self.rx.resubscribe();
                Some(ChatUpdate {
                    mostro_pubkey: crate::config::active_mostro_pubkey().unwrap_or_default(),
                    dispute_id: None,
                    party: None,
                })
            }
            Err(RecvError::Closed) => None,
        }
    }
}
