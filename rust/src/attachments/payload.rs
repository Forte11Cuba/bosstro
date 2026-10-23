//! The chat message that carries an attachment, from ../app's
//! `attachments/payload.rs`.
//!
//! A JSON object sent as the text of an ordinary chat message (the inner
//! kind 1 of the chat envelope). Two shapes, every field as ../app writes and
//! parses it:
//!
//! ```json
//! {"type":"image_encrypted","blossom_url":"https://…/<sha256>","nonce":"<hex>",
//!  "mime_type":"image/jpeg","original_size":1,"width":1,"height":1,
//!  "filename":"…","encrypted_size":29}
//! {"type":"file_encrypted","file_type":"document","blossom_url":"…","nonce":"<hex>",
//!  "mime_type":"application/pdf","original_size":1,"filename":"…","encrypted_size":29}
//! ```
//!
//! `nonce` repeats the one at the head of the blob. ../app's parser requires
//! the field (a plain `String`, no default), so it is sent; readers decrypt
//! with the blob's own.
use serde::{Deserialize, Serialize};

use crate::attachments::media::sanitize_filename;
use crate::attachments::{MAX_ATTACHMENT_BYTES, MAX_BLOB_BYTES};
use crate::nostr::blossom;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum AttachmentPayload {
    /// A JPEG or PNG, previewed inline.
    #[serde(rename = "image_encrypted")]
    Image(ImagePayload),
    /// Anything else; from ../app, a PDF (`file_type` `document`).
    #[serde(rename = "file_encrypted")]
    File(FilePayload),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ImagePayload {
    pub blossom_url: String,
    pub nonce: String,
    pub mime_type: String,
    pub original_size: u64,
    pub width: u32,
    pub height: u32,
    pub filename: String,
    pub encrypted_size: u64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FilePayload {
    pub file_type: String,
    pub blossom_url: String,
    pub nonce: String,
    pub mime_type: String,
    pub original_size: u64,
    pub filename: String,
    pub encrypted_size: u64,
}

impl AttachmentPayload {
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).expect("attachment payload serializes")
    }
}

/// A received attachment, validated: what the chat shows before it is opened.
#[derive(Debug, Clone, PartialEq)]
pub struct IncomingAttachment {
    /// `image_encrypted`: shown as a picture once its bytes prove it is one.
    pub is_image: bool,
    pub blossom_url: String,
    /// Hex SHA-256 of the encrypted blob, from the URL. The download is
    /// checked against it before decrypting.
    pub sha256: String,
    /// As declared by the sender: a label only. What the file is is read
    /// from its bytes once decrypted.
    pub mime_type: String,
    pub file_name: String,
    pub original_size: u64,
    pub width: Option<u32>,
    pub height: Option<u32>,
}

/// Read a chat message's text as an attachment, if it is one.
///
/// Anything that is not a well-formed, safe attachment — plain text, JSON of
/// another shape, a URL that is not HTTPS (`blossom::is_fetchable`) or does
/// not name the blob's hash, a size over the limit — is `None`, and the
/// message stays text.
pub fn parse(text: &str) -> Option<IncomingAttachment> {
    // ../app only considers text that starts with `{`.
    if !text.trim_start().starts_with('{') {
        return None;
    }
    let payload: AttachmentPayload = serde_json::from_str(text).ok()?;
    let (url, mime, name, original, encrypted, is_image, dims) = match payload {
        AttachmentPayload::Image(p) => (
            p.blossom_url,
            p.mime_type,
            p.filename,
            p.original_size,
            p.encrypted_size,
            true,
            Some((p.width, p.height)),
        ),
        AttachmentPayload::File(p) => (
            p.blossom_url,
            p.mime_type,
            p.filename,
            p.original_size,
            p.encrypted_size,
            false,
            None,
        ),
    };
    let sha256 = blossom::sha256_from_url(&url)?;
    if !blossom::is_fetchable(&url)
        || encrypted > MAX_BLOB_BYTES as u64
        || original > MAX_ATTACHMENT_BYTES as u64
    {
        return None;
    }
    Some(IncomingAttachment {
        is_image,
        blossom_url: url,
        sha256,
        mime_type: mime,
        file_name: sanitize_filename(&name),
        original_size: original,
        width: dims.map(|d| d.0),
        height: dims.map(|d| d.1),
    })
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    pub(crate) const HASH: &str =
        "b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553";

    // ../app's own test samples (`attachments/payload.rs`), byte for byte.
    pub(crate) fn app_image() -> String {
        format!(
            r#"{{"type":"image_encrypted","blossom_url":"https://cdn.hzrd149.com/{HASH}","nonce":"0102030405060708090a0b0c","mime_type":"image/jpeg","original_size":524288,"width":1920,"height":1080,"filename":"receipt.jpg","encrypted_size":524316}}"#
        )
    }

    pub(crate) fn app_pdf() -> String {
        format!(
            r#"{{"type":"file_encrypted","file_type":"document","blossom_url":"https://nostr.download/{HASH}","nonce":"0102030405060708090a0b0c","mime_type":"application/pdf","original_size":1048576,"filename":"bank.pdf","encrypted_size":1048604}}"#
        )
    }

    /// ../app's parser, as it is: its structs have exactly these fields, no
    /// defaults, so a missing or mistyped field fails it. Kept apart from
    /// ours so a change to ours is caught.
    mod app_parser {
        #[derive(serde::Deserialize)]
        #[serde(tag = "type")]
        #[allow(dead_code)]
        pub enum AttachmentPayload {
            #[serde(rename = "image_encrypted")]
            Image {
                blossom_url: String,
                nonce: String,
                mime_type: String,
                original_size: u64,
                width: u32,
                height: u32,
                filename: String,
                encrypted_size: u64,
            },
            #[serde(rename = "file_encrypted")]
            File {
                file_type: String,
                blossom_url: String,
                nonce: String,
                mime_type: String,
                original_size: u64,
                filename: String,
                encrypted_size: u64,
            },
        }
    }

    #[test]
    fn reads_what_app_sends() {
        let a = parse(&app_image()).unwrap();
        assert!(a.is_image);
        assert_eq!(a.sha256, HASH);
        assert_eq!((a.width, a.height), (Some(1920), Some(1080)));
        assert_eq!(a.file_name, "receipt.jpg");
        assert_eq!(a.original_size, 524288);
        let a = parse(&app_pdf()).unwrap();
        assert!(!a.is_image);
        assert_eq!(a.mime_type, "application/pdf");
        assert_eq!(a.width, None);
    }

    #[test]
    fn writes_byte_for_byte_what_app_writes_and_app_reads_it() {
        for sample in [app_image(), app_pdf()] {
            let ours = serde_json::from_str::<AttachmentPayload>(&sample)
                .unwrap()
                .to_json();
            assert_eq!(ours, sample);
            serde_json::from_str::<app_parser::AttachmentPayload>(&ours).unwrap();
        }
    }

    #[test]
    fn plain_text_and_other_json_stay_text() {
        assert!(parse("hola, ya te transferí").is_none());
        assert!(parse(r#"{"type":"file","url":"https://x/y","name":"a"}"#).is_none());
        // An image missing width/height is malformed for ../app too.
        assert!(parse(&app_image().replace(r#""width":1920,"height":1080,"#, "")).is_none());
        // So is one without the nonce.
        assert!(
            parse(&app_image().replace(r#""nonce":"0102030405060708090a0b0c","#, "")).is_none()
        );
    }

    #[test]
    fn refuses_unsafe_urls_and_oversized_blobs() {
        assert!(parse(&app_image().replace("https://", "http://")).is_none());
        assert!(parse(&app_image().replace(HASH, "not-a-hash")).is_none());
        assert!(parse(&app_image().replace("524316", &(MAX_BLOB_BYTES + 1).to_string())).is_none());
        assert!(
            parse(&app_image().replace("524288", &(MAX_ATTACHMENT_BYTES + 1).to_string()))
                .is_none()
        );
        // Compared as u64: 2^32 + 1 must not wrap to 1 on a 32-bit target.
        assert!(parse(&app_image().replace("524316", "4294967297")).is_none());
    }

    #[test]
    fn a_hostile_file_name_is_defused() {
        let a = parse(&app_pdf().replace("bank.pdf", "../../etc/passwd")).unwrap();
        assert_eq!(a.file_name, "passwd");
    }
}
