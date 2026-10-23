//! The dispute chat (phase 5), across the bridge: one conversation with the
//! buyer and one with the seller of each dispute this key holds.
//!
//! The wire is the Mostro chat envelope (<https://mostro.network/protocol/dispute_chat.html>),
//! keyed between the solver key and each party's trade key (`crate::chat`).
//! Rust keeps the messages (one row per channel and inner event id) and
//! announces every change on [`on_chat_updates`]; Dart reads the thread again.
//!
//! Attachments (part 2) are messages too: their text is ../app's JSON
//! (`crate::attachments::payload`), read into [`ChatAttachment`]. Dart hands
//! over the bytes of a picked file and gets a received one back decrypted, in
//! memory; the key, the encryption, the upload, the hash check and the type
//! check are all here.
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
    /// The text; for an attachment, its JSON (not shown).
    pub content: String,
    /// The inner event's `created_at` (Unix seconds), as the writer set it.
    pub created_at: i64,
    pub delivery: ChatDelivery,
    /// Set when the text is a well-formed attachment (an `https://` blob URL
    /// that names its hash, sizes within the limits). Not opened yet: what
    /// the file really is is known only from [`open_chat_attachment`].
    pub attachment: Option<ChatAttachment>,
}

/// How an attachment is shown before it is opened.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChatAttachmentKind {
    /// Sent as an image (`image_encrypted`): previewed in the bubble.
    Image,
    /// Sent as a file (`file_encrypted`; from ../app, a PDF): name and size.
    File,
}

/// An attachment as its message declares it: labels, until it is opened.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChatAttachment {
    pub kind: ChatAttachmentKind,
    /// Sanitized: the last path component only, no control or invisible
    /// characters, at most 120 characters.
    pub file_name: String,
    /// As the sender declared it: a label only.
    pub mime_type: String,
    /// The file's size before encryption, as declared (at most 25 MiB).
    pub size: u32,
    /// Pixel size, for an image: lets the bubble keep its shape.
    pub width: Option<u32>,
    pub height: Option<u32>,
}

/// An attachment opened: decrypted in memory, its type read from its bytes.
/// The plaintext is never written to disk by Rust; Dart writes it only when
/// the solver saves it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenedAttachment {
    pub bytes: Vec<u8>,
    /// Sanitized, as [`ChatAttachment::file_name`].
    pub file_name: String,
    /// `image/jpeg`, `image/png` or `application/pdf`, from the bytes.
    pub mime_type: String,
    /// A JPEG or a PNG, within the decoding limits: Dart may preview it.
    pub is_image: bool,
}

/// How far a transfer is: `id` is the upload id Dart chose, or the message
/// id of a download; `fraction` goes from 0 to 1.
#[derive(Debug, Clone, PartialEq)]
pub struct AttachmentProgress {
    pub id: String,
    pub fraction: f64,
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
    /// The message to retry is not one of this key's unsent messages, or
    /// the message to open carries no attachment.
    UnknownMessage,
    /// The file is over 25 MiB (before encryption).
    FileTooLarge,
    /// The file is not a JPEG, PNG or PDF, by its bytes.
    UnsupportedFile,
    /// An image that does not decode, or is beyond the decoding limits.
    InvalidImage,
    /// No Blossom server took the file. Nothing was sent; try again.
    UploadFailed,
    /// The file could not be downloaded. Try again.
    DownloadFailed,
    /// The file downloaded is not the one the message names (its hash), or
    /// it does not open with this conversation's key (its tag), or it is not
    /// what it was sent as. Trying again gives the same answer.
    NotVerified,
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

/// Send the file `bytes` (picked by the solver, named `file_name`) to
/// `party`: checked and cleaned by its bytes (JPEG, PNG or PDF, at most
/// 25 MiB; images re-encoded without metadata), encrypted with the key shared
/// with the party, uploaded to Blossom, and sent as ../app's JSON message.
/// Returns the message as stored, `Sending`, as [`send_chat_message`]; a
/// message that then fails is retried with [`retry_chat_message`] (the file
/// is not uploaded again). `upload_id`, chosen by Dart, names the upload on
/// [`on_attachment_progress`]. A refusal before the message exists
/// (`UploadFailed`, …) leaves nothing stored: Dart keeps the bytes for a
/// retry.
pub async fn send_chat_attachment(
    dispute_id: String,
    party: ChatParty,
    bytes: Vec<u8>,
    file_name: String,
    upload_id: String,
) -> Result<ChatMessageView, ChatError> {
    crate::attachments::transfer::send(&dispute_id, party, bytes, &file_name, &upload_id).await
}

/// Open the attachment of `message_id` in the conversation with `party`:
/// the encrypted blob from the cache, or downloaded (`https://` only, at most
/// 25 MiB) and checked against the hash its URL names, then decrypted with
/// the key shared with the party and checked to be a JPEG, PNG or PDF.
/// Works on a closed dispute too. A download reports on
/// [`on_attachment_progress`] under `message_id`.
pub async fn open_chat_attachment(
    dispute_id: String,
    party: ChatParty,
    message_id: String,
) -> Result<OpenedAttachment, ChatError> {
    crate::attachments::transfer::open(&dispute_id, party, &message_id).await
}

/// Stream of every transfer's progress (uploads and downloads).
pub fn on_attachment_progress() -> AttachmentProgressStream {
    AttachmentProgressStream {
        rx: crate::attachments::transfer::subscribe_progress(),
    }
}

/// Wrapper so flutter_rust_bridge can hand Dart a pull-based stream.
pub struct AttachmentProgressStream {
    rx: tokio::sync::broadcast::Receiver<AttachmentProgress>,
}

impl AttachmentProgressStream {
    /// The next report, or `None` once the sender is gone. A reader that
    /// fell behind skips what it missed: progress is only ever a hint.
    pub async fn next(&mut self) -> Option<AttachmentProgress> {
        use tokio::sync::broadcast::error::RecvError;
        loop {
            match self.rx.recv().await {
                Ok(progress) => return Some(progress),
                Err(RecvError::Lagged(_)) => continue,
                Err(RecvError::Closed) => return None,
            }
        }
    }
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
