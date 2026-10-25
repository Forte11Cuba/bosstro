//! Chat attachments (phase 5, part 2): images and PDFs in the dispute chat,
//! encrypted on the device and stored on Blossom. Ported from MostroP2P/app
//! (`rust/src/attachments/`), the app the parties use: the same file key
//! (`crypto::file_enc::attachment_key`), the same blob (`crypto::file_enc`),
//! the same JSON message ([`payload`]) and the same Blossom upload
//! (`nostr::blossom`), so either app opens the other's files.
//!
//! - [`media`]: what may be sent and what a received file really is, decided
//!   by the bytes.
//! - [`payload`]: the JSON message, written and read as MostroP2P/app does.
//! - [`transfer`]: send and open, on top of the chat router.
pub mod media;
pub mod payload;
pub mod transfer;

/// Largest file attached, before encryption. MostroP2P/app's limit.
pub const MAX_ATTACHMENT_BYTES: usize = 25 * 1024 * 1024;

/// Largest encrypted blob: the file plus its nonce and tag.
pub const MAX_BLOB_BYTES: usize = MAX_ATTACHMENT_BYTES
    + crate::crypto::file_enc::NONCE_BYTES
    + crate::crypto::file_enc::TAG_BYTES;
