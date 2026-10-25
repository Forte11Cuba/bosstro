//! Sending and opening attachments, on top of the chat router. The flow is
//! MostroP2P/app's `send_attachment` / `download_attachment`, keyed between the
//! solver key and the party's trade key:
//!
//! **Send.** The file is checked and cleaned by its bytes
//! ([`media::prepare_for_send`]), encrypted with [`file_enc::attachment_key`],
//! uploaded to Blossom (a throwaway key signs the authorisation), its blob
//! kept in the cache so this device never downloads it again, and the JSON
//! message ([`payload`]) sent as an ordinary chat message: stored `Sending`,
//! published in the background, retried by hand as any text. An upload that
//! fails leaves nothing stored; Dart keeps the bytes for a retry.
//!
//! **Open.** The blob comes from the cache or from Blossom (`https://` only,
//! held to [`MAX_BLOB_BYTES`], checked against the hash its URL names), then
//! is decrypted and its type read from its bytes ([`media::check_received`]).
//! The plaintext is handed to Dart in memory and never written here.
//!
//! The file key is derived when it is needed and dropped with the call.
//! Nothing logs a key, a full blob URL or a file's content.

use std::sync::{Arc, OnceLock};

use tokio::sync::broadcast;

use crate::api::chat::{
    AttachmentProgress, ChatError, ChatMessageView, ChatParty, OpenedAttachment,
};
use crate::attachments::media::{self, Refusal};
use crate::attachments::payload::{self, AttachmentPayload, FilePayload, ImagePayload};
use crate::attachments::MAX_BLOB_BYTES;
use crate::chat::router::{self, Router};
use crate::crypto::file_enc;
use crate::nostr::blossom::{self, BlossomError};

/// Capacity of the progress channel toward Dart.
const PROGRESS_CAPACITY: usize = 64;

fn progress() -> &'static broadcast::Sender<AttachmentProgress> {
    static PROGRESS: OnceLock<broadcast::Sender<AttachmentProgress>> = OnceLock::new();
    PROGRESS.get_or_init(|| broadcast::channel(PROGRESS_CAPACITY).0)
}

pub(crate) fn subscribe_progress() -> broadcast::Receiver<AttachmentProgress> {
    progress().subscribe()
}

fn report(id: &str, fraction: f64) {
    let _ = progress().send(AttachmentProgress {
        id: id.to_string(),
        fraction,
    });
}

impl From<Refusal> for ChatError {
    fn from(refusal: Refusal) -> Self {
        match refusal {
            Refusal::TooLarge => ChatError::FileTooLarge,
            Refusal::Unsupported => ChatError::UnsupportedFile,
            Refusal::InvalidImage => ChatError::InvalidImage,
        }
    }
}

/// CPU work on a file (decoding, re-encoding, decrypting up to 25 MiB): on
/// the blocking pool natively, off the runtime's workers; inline on the web,
/// which has no other thread.
async fn off_thread<T: Send + 'static>(work: impl FnOnce() -> T + Send + 'static) -> T {
    #[cfg(not(target_arch = "wasm32"))]
    {
        tokio::task::spawn_blocking(work)
            .await
            .expect("attachment work panicked")
    }
    #[cfg(target_arch = "wasm32")]
    {
        work()
    }
}

/// [`crate::api::chat::send_chat_attachment`].
pub(crate) async fn send(
    dispute_id: &str,
    party: ChatParty,
    bytes: Vec<u8>,
    file_name: &str,
    upload_id: &str,
) -> Result<ChatMessageView, ChatError> {
    router::node_and_keys().await?;
    let router = router::router().ok_or(ChatError::NoRelays)?;
    send_on(router, dispute_id, party, bytes, file_name, upload_id).await
}

pub(crate) async fn send_on(
    router: &Arc<Router>,
    dispute_id: &str,
    party: ChatParty,
    bytes: Vec<u8>,
    file_name: &str,
    upload_id: &str,
) -> Result<ChatMessageView, ChatError> {
    // Refused at once when the conversation cannot be written to: nothing
    // is uploaded for a message that could never be sent.
    let (keys, _, party_key) = router.writable(dispute_id, party).await?;

    // 1. What it is, decided by the bytes; images leave without metadata.
    let prepared = off_thread(move || media::prepare_for_send(bytes)).await?;
    let shape = Shape {
        kind: prepared.kind,
        width: prepared.width,
        height: prepared.height,
        original_size: prepared.bytes.len() as u64,
    };
    report(upload_id, 0.1);

    // 2. Encrypted with the key shared with the party.
    let blob = {
        let key = file_enc::attachment_key(&keys, &party_key).map_err(|e| {
            log::warn!("[attachments] key not derived: {e}");
            ChatError::NoPartyKey
        })?;
        let plaintext = prepared.bytes;
        off_thread(move || file_enc::encrypt_file(&plaintext, &key))
            .await
            .map_err(|e| {
                log::warn!("[attachments] not encrypted: {e}");
                ChatError::UploadFailed
            })?
    };
    report(upload_id, 0.3);

    // 3. Uploaded, and our own copy kept so our bubble never downloads it.
    let uploaded = blossom::upload_blob(&blob).await.map_err(|e| match e {
        BlossomError::TooLarge => ChatError::FileTooLarge,
        _ => ChatError::UploadFailed,
    })?;
    if let Err(e) = router.store.save_blob(&uploaded.sha256, &blob).await {
        log::warn!("[attachments] blob not cached: {e}");
    }
    report(upload_id, 0.9);

    // 4. MostroP2P/app's message: JPEG and PNG as `image_encrypted`, a PDF as
    //    `file_encrypted` (`document`).
    let message = message_for(&shape, &blob, uploaded.url, file_name);
    let sent = router.send(dispute_id, party, &message.to_json()).await?;
    report(upload_id, 1.0);
    Ok(sent)
}

/// What the message says of a prepared file.
struct Shape {
    kind: media::Kind,
    width: Option<u32>,
    height: Option<u32>,
    original_size: u64,
}

/// The JSON message of a prepared file and its blob, field for field as
/// MostroP2P/app writes it.
fn message_for(
    shape: &Shape,
    blob: &[u8],
    blossom_url: String,
    file_name: &str,
) -> AttachmentPayload {
    let nonce = hex::encode(&blob[..file_enc::NONCE_BYTES]);
    let filename = media::sanitize_filename(file_name);
    let mime_type = shape.kind.mime().to_string();
    let original_size = shape.original_size;
    let encrypted_size = blob.len() as u64;
    match (shape.width, shape.height) {
        (Some(width), Some(height)) => AttachmentPayload::Image(ImagePayload {
            blossom_url,
            nonce,
            mime_type,
            original_size,
            width,
            height,
            filename,
            encrypted_size,
        }),
        _ => AttachmentPayload::File(FilePayload {
            file_type: "document".to_string(),
            blossom_url,
            nonce,
            mime_type,
            original_size,
            filename,
            encrypted_size,
        }),
    }
}

/// [`crate::api::chat::open_chat_attachment`].
pub(crate) async fn open(
    dispute_id: &str,
    party: ChatParty,
    message_id: &str,
) -> Result<OpenedAttachment, ChatError> {
    router::node_and_keys().await?;
    let router = router::router().ok_or(ChatError::NoRelays)?;
    open_on(router, dispute_id, party, message_id).await
}

pub(crate) async fn open_on(
    router: &Router,
    dispute_id: &str,
    party: ChatParty,
    message_id: &str,
) -> Result<OpenedAttachment, ChatError> {
    // Whatever the dispute's status: a closed one's files stay readable.
    let conversation = router.conversation(dispute_id, party).await?;
    let party_key = conversation.party_key.ok_or(ChatError::NoPartyKey)?;
    let record = router
        .store
        .get(&conversation.channel, message_id)
        .await
        .ok()
        .flatten()
        .ok_or(ChatError::UnknownMessage)?;
    let attachment = payload::parse(&record.content).ok_or(ChatError::UnknownMessage)?;

    let blob = blob_of(router, &attachment, message_id).await?;
    let key = file_enc::attachment_key(&conversation.keys, &party_key).map_err(|e| {
        log::warn!("[attachments] key not derived: {e}");
        ChatError::NoPartyKey
    })?;
    let (bytes, kind) = off_thread(move || {
        let bytes = file_enc::decrypt_file(&blob, &key).map_err(|_| ChatError::NotVerified)?;
        let kind = media::check_received(&bytes)?;
        Ok::<_, ChatError>((bytes, kind))
    })
    .await?;
    // Sent as an image, it must be one.
    if attachment.is_image && !kind.is_image() {
        return Err(ChatError::NotVerified);
    }
    Ok(OpenedAttachment {
        bytes,
        file_name: attachment.file_name,
        mime_type: kind.mime().to_string(),
        is_image: kind.is_image(),
    })
}

/// The encrypted blob of an attachment: cached (and still the blob its URL
/// names), or downloaded, verified and cached.
async fn blob_of(
    router: &Router,
    attachment: &payload::IncomingAttachment,
    message_id: &str,
) -> Result<Vec<u8>, ChatError> {
    match router.store.get_blob(&attachment.sha256).await {
        Ok(Some(blob)) if blob.len() <= MAX_BLOB_BYTES => {
            let sha256 = attachment.sha256.clone();
            let (blob, intact) = off_thread(move || {
                let intact = blossom::sha256_hex(&blob) == sha256;
                (blob, intact)
            })
            .await;
            if intact {
                return Ok(blob);
            }
            log::warn!("[attachments] a cached blob no longer matches its hash");
        }
        Ok(_) => {}
        Err(e) => log::warn!("[attachments] cache not read: {e}"),
    }
    let blob = blossom::download_blob(&attachment.blossom_url, |fraction| {
        report(message_id, fraction)
    })
    .await
    .map_err(|e| match e {
        BlossomError::HashMismatch => ChatError::NotVerified,
        BlossomError::TooLarge => ChatError::FileTooLarge,
        BlossomError::UploadFailed | BlossomError::DownloadFailed => ChatError::DownloadFailed,
    })?;
    if let Err(e) = router.store.save_blob(&attachment.sha256, &blob).await {
        log::warn!("[attachments] blob not cached: {e}");
    }
    Ok(blob)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use crate::api::chat::{ChatAttachmentKind, ChatDelivery, ChatSender};
    use crate::attachments::media::tests::{jpeg, PDF};
    use crate::chat::router::tests::{bench, bench_with, eventually, Bench, Party, DISPUTE_A};
    use crate::chat::router::ChatStore;
    use crate::db::Storage;
    use crate::disputes::feed::Store;
    use crate::nostr::blossom::test_server::{serve_with, Seen};
    use nostr_sdk::prelude::*;
    use std::sync::Mutex;

    /// One Blossom server for the whole test process, on a runtime of its
    /// own, named by the debug build's test variable (the only `http://`
    /// origin a blob may come from). Every test shares it: blobs are keyed by
    /// their hash. `PUT /upload` stores a blob at its hash; `PUT /plant/<h>`
    /// stores any bytes at `h`, as a lying server would.
    fn server() -> &'static (String, Arc<Mutex<Vec<Seen>>>) {
        static SERVER: OnceLock<(String, Arc<Mutex<Vec<Seen>>>)> = OnceLock::new();
        SERVER.get_or_init(|| {
            let (tx, rx) = std::sync::mpsc::channel();
            std::thread::spawn(move || {
                let runtime = tokio::runtime::Builder::new_current_thread()
                    .enable_all()
                    .build()
                    .unwrap();
                runtime.block_on(async move {
                    let stored: Arc<Mutex<std::collections::HashMap<String, Vec<u8>>>> =
                        Arc::default();
                    let served = serve_with(move |request| {
                        let mut stored = stored.lock().unwrap();
                        let path = request.path.trim_start_matches('/');
                        match (request.method.as_str(), path.strip_prefix("plant/")) {
                            ("PUT", Some(hash)) => {
                                stored.insert(hash.to_string(), request.body.clone());
                                (200, Vec::new())
                            }
                            ("PUT", None) => {
                                let sha = blossom::sha256_hex(&request.body);
                                stored.insert(sha.clone(), request.body.clone());
                                (200, format!(r#"{{"sha256":"{sha}"}}"#).into_bytes())
                            }
                            _ => match stored.get(path) {
                                Some(blob) => (200, blob.clone()),
                                None => (404, Vec::new()),
                            },
                        }
                    })
                    .await;
                    tx.send(served).unwrap();
                    std::future::pending::<()>().await;
                });
            });
            let served = rx.recv().unwrap();
            std::env::set_var(blossom::TEST_SERVER_ENV, &served.0);
            served
        })
    }

    fn base() -> &'static str {
        &server().0
    }

    /// A PDF carrying `marker`, so a scan can look for its plaintext.
    fn pdf_with(marker: &str) -> Vec<u8> {
        format!("%PDF-1.4\n% {marker}\n1 0 obj<<>>endobj\n%%EOF").into_bytes()
    }

    impl Party {
        /// Send `file` to the solver as MostroP2P/app does: encrypted with the
        /// key of the party's trade key and the solver's pubkey, uploaded, and
        /// the JSON written in the chat. Returns the JSON.
        async fn send_file(&self, solver: &PublicKey, file: &[u8], name: &str) -> String {
            let key = file_enc::attachment_key(&self.keys, solver).unwrap();
            let blob = file_enc::encrypt_file(file, &key).unwrap();
            let uploaded = blossom::upload_to(&[base()], &blob).await.unwrap();
            let message = message_for(&shape_of(file), &blob, uploaded.url, name);
            self.say(solver, &message.to_json()).await;
            message.to_json()
        }

        /// Open a file the solver sent, as MostroP2P/app does.
        async fn open_file(&self, solver: &PublicKey, json: &str) -> Vec<u8> {
            let attachment = payload::parse(json).expect("an attachment");
            let blob = blossom::download_blob(&attachment.blossom_url, |_| {})
                .await
                .unwrap();
            let key = file_enc::attachment_key(&self.keys, solver).unwrap();
            file_enc::decrypt_file(&blob, &key).unwrap()
        }
    }

    fn shape_of(file: &[u8]) -> Shape {
        let kind = media::sniff(file).unwrap();
        let (width, height) = if kind.is_image() {
            let size = image::load_from_memory(file).unwrap();
            (Some(size.width()), Some(size.height()))
        } else {
            (None, None)
        };
        Shape {
            kind,
            width,
            height,
            original_size: file.len() as u64,
        }
    }

    /// The message carrying the file `name`, once it is in the conversation.
    async fn file_message(b: &Bench, party: ChatParty, name: &str) -> ChatMessageView {
        let find = || async {
            b.messages(DISPUTE_A, party)
                .await
                .into_iter()
                .find(|m| m.attachment.as_ref().is_some_and(|a| a.file_name == name))
        };
        eventually(&format!("the file {name}"), || async {
            find().await.is_some()
        })
        .await;
        find().await.unwrap()
    }

    #[tokio::test]
    async fn the_solver_sends_an_image_and_the_party_opens_it() {
        let b = bench().await;
        server();
        let solver = b.solver.public_key();
        let sent = send_on(
            &b.router,
            DISPUTE_A,
            ChatParty::Buyer,
            jpeg(40, 20),
            "../x/receipt.jpg",
            "u1",
        )
        .await
        .unwrap();
        assert_eq!(sent.sender, ChatSender::You);
        let attachment = sent.attachment.clone().expect("an attachment");
        assert_eq!(attachment.kind, ChatAttachmentKind::Image);
        assert_eq!(attachment.file_name, "receipt.jpg");
        assert_eq!((attachment.width, attachment.height), (Some(40), Some(20)));
        eventually("sent", || async {
            b.messages(DISPUTE_A, ChatParty::Buyer)
                .await
                .iter()
                .any(|m| m.id == sent.id && m.delivery == ChatDelivery::Sent)
        })
        .await;

        // The buyer reads MostroP2P/app's JSON and opens the file with its own
        // key.
        let read = b.buyer.read(&solver).await;
        let (_, json) = read.iter().find(|(from, _)| *from == solver).unwrap();
        let value: serde_json::Value = serde_json::from_str(json).unwrap();
        assert_eq!(value["type"], "image_encrypted");
        let file = b.buyer.open_file(&solver, json).await;
        assert_eq!(media::sniff(&file), Some(media::Kind::Jpeg));
        assert_eq!(value["original_size"].as_u64(), Some(file.len() as u64));
        // The seller's key does not open it.
        let attachment = payload::parse(json).unwrap();
        let blob = blossom::download_blob(&attachment.blossom_url, |_| {})
            .await
            .unwrap();
        let wrong = file_enc::attachment_key(&b.seller.keys, &solver).unwrap();
        assert!(file_enc::decrypt_file(&blob, &wrong).is_err());

        // The upload was authorised by a throwaway key, never the solver's.
        let seen = server().1.lock().unwrap().clone();
        let auth = seen
            .iter()
            .filter(|s| s.method == "PUT" && s.path == "/upload")
            .map(|s| {
                use base64::{engine::general_purpose::STANDARD, Engine};
                let header = s.header("Authorization").unwrap();
                Event::from_json(
                    STANDARD
                        .decode(header.strip_prefix("Nostr ").unwrap())
                        .unwrap(),
                )
                .unwrap()
            })
            .find(|e| {
                e.tags
                    .iter()
                    .any(|t| t.as_slice() == ["x", attachment.sha256.as_str()])
            })
            .expect("the upload's authorisation");
        assert_ne!(auth.pubkey, solver);

        // And the solver opens its own file from the cache.
        let opened = open_on(&b.router, DISPUTE_A, ChatParty::Buyer, &sent.id)
            .await
            .unwrap();
        assert_eq!(opened.bytes, file);
        assert!(opened.is_image);
    }

    #[tokio::test]
    async fn a_party_sends_a_pdf_and_an_image_and_the_solver_opens_both() {
        let b = bench().await;
        server();
        let solver = b.solver.public_key();
        let pdf = pdf_with("the bank statement");
        b.seller.send_file(&solver, &pdf, "statement.pdf").await;
        let got = file_message(&b, ChatParty::Seller, "statement.pdf").await;
        let attachment = got.attachment.clone().unwrap();
        assert_eq!(attachment.kind, ChatAttachmentKind::File);
        assert_eq!(attachment.file_name, "statement.pdf");
        assert_eq!(attachment.size as usize, pdf.len());
        let opened = open_on(&b.router, DISPUTE_A, ChatParty::Seller, &got.id)
            .await
            .unwrap();
        assert_eq!(opened.bytes, pdf);
        assert_eq!(opened.mime_type, "application/pdf");
        assert!(!opened.is_image);

        let image = jpeg(8, 6);
        b.seller.send_file(&solver, &image, "photo.jpg").await;
        let got = file_message(&b, ChatParty::Seller, "photo.jpg").await;
        assert_eq!(got.attachment.unwrap().kind, ChatAttachmentKind::Image);
        let opened = open_on(&b.router, DISPUTE_A, ChatParty::Seller, &got.id)
            .await
            .unwrap();
        assert_eq!((opened.bytes, opened.is_image), (image, true));
    }

    #[tokio::test]
    async fn a_file_that_is_not_the_one_named_or_sealed_is_not_verified() {
        let b = bench().await;
        server();
        let solver = b.solver.public_key();
        let client = reqwest::Client::new();
        let key = file_enc::attachment_key(&b.buyer.keys, &solver).unwrap();

        // 1. The server hands back other bytes than the URL's hash names.
        let blob = file_enc::encrypt_file(PDF, &key).unwrap();
        let hash = blossom::sha256_hex(&blob);
        let other = file_enc::encrypt_file(PDF, &key).unwrap();
        client
            .put(format!("{}/plant/{hash}", base()))
            .body(other)
            .send()
            .await
            .unwrap();
        let swapped = message_for(&shape_of(PDF), &blob, format!("{}/{hash}", base()), "a.pdf");
        b.buyer.say(&solver, &swapped.to_json()).await;

        // 2. A blob sealed under another key (a stranger's), honestly stored.
        let stranger = Keys::generate();
        let foreign_key = file_enc::attachment_key(&stranger, &solver).unwrap();
        let foreign = file_enc::encrypt_file(PDF, &foreign_key).unwrap();
        let uploaded = blossom::upload_to(&[base()], &foreign).await.unwrap();
        let sealed = message_for(&shape_of(PDF), &foreign, uploaded.url, "b.pdf");
        b.buyer.say(&solver, &sealed.to_json()).await;

        // 3. Sent as an image, but a PDF once decrypted.
        let mut shape = shape_of(PDF);
        (shape.width, shape.height) = (Some(1), Some(1));
        let pdf_blob = file_enc::encrypt_file(PDF, &key).unwrap();
        let uploaded = blossom::upload_to(&[base()], &pdf_blob).await.unwrap();
        let disguised = message_for(&shape, &pdf_blob, uploaded.url, "c.jpg");
        assert!(matches!(disguised, AttachmentPayload::Image(_)));
        b.buyer.say(&solver, &disguised.to_json()).await;

        // 4. Not a type the chat opens (an executable), however it is named.
        let exe = file_enc::encrypt_file(b"MZ\x90\x00 not a pdf", &key).unwrap();
        let uploaded = blossom::upload_to(&[base()], &exe).await.unwrap();
        let named = message_for(&shape_of(PDF), &exe, uploaded.url, "d.pdf");
        b.buyer.say(&solver, &named.to_json()).await;

        b.wait_for(DISPUTE_A, ChatParty::Buyer, 4).await;
        let messages = b.messages(DISPUTE_A, ChatParty::Buyer).await;
        let mut answers = Vec::new();
        for m in messages.iter().filter(|m| m.attachment.is_some()) {
            let name = m.attachment.as_ref().unwrap().file_name.clone();
            let answer = open_on(&b.router, DISPUTE_A, ChatParty::Buyer, &m.id).await;
            answers.push((name, answer.map(|o| o.mime_type)));
        }
        answers.sort_by(|a, b| a.0.cmp(&b.0));
        assert_eq!(
            answers,
            vec![
                ("a.pdf".into(), Err(ChatError::NotVerified)),
                ("b.pdf".into(), Err(ChatError::NotVerified)),
                ("c.jpg".into(), Err(ChatError::NotVerified)),
                ("d.pdf".into(), Err(ChatError::UnsupportedFile)),
            ]
        );
        // A text message carries no attachment to open.
        b.buyer.say(&solver, "plain text").await;
        b.wait_for(DISPUTE_A, ChatParty::Buyer, 5).await;
        let messages = b.messages(DISPUTE_A, ChatParty::Buyer).await;
        let text = messages.iter().find(|m| m.content == "plain text").unwrap();
        assert!(text.attachment.is_none());
        assert_eq!(
            open_on(&b.router, DISPUTE_A, ChatParty::Buyer, &text.id)
                .await
                .unwrap_err(),
            ChatError::UnknownMessage
        );
    }

    #[tokio::test]
    async fn a_file_refused_by_its_bytes_is_never_uploaded_nor_stored() {
        let b = bench().await;
        server();
        for (bytes, refusal) in [
            (b"GIF89a....".to_vec(), ChatError::UnsupportedFile),
            (vec![0xFF, 0xD8, 0xFF, 0x00], ChatError::InvalidImage),
        ] {
            let answer = send_on(&b.router, DISPUTE_A, ChatParty::Seller, bytes, "x", "u").await;
            assert_eq!(answer.unwrap_err(), refusal);
        }
        // Nothing reached the seller's conversation.
        assert!(b.messages(DISPUTE_A, ChatParty::Seller).await.is_empty());
        // Another party's dispute, or none, is refused before any work.
        assert_eq!(
            send_on(
                &b.router,
                "00000000-0000-4000-8000-000000000000",
                ChatParty::Buyer,
                PDF.to_vec(),
                "x",
                "u"
            )
            .await
            .unwrap_err(),
            ChatError::UnknownDispute
        );
    }

    /// Nothing secret or decrypted reaches the database: no file key, and no
    /// plaintext of a file sent or opened. The encrypted blobs are there (the
    /// cache), so the scan sees what is written.
    #[tokio::test]
    async fn no_file_key_and_no_plaintext_is_written_to_storage() {
        server();
        let path = crate::db::sqlite::tests::temp_db_path();
        let storage: &'static crate::db::sqlite::SqliteStorage = Box::leak(Box::new(
            crate::db::sqlite::SqliteStorage::open(path.to_str().unwrap())
                .await
                .unwrap(),
        ));
        let b = bench_with(Store::Db(storage), ChatStore::Db(storage)).await;
        let solver = b.solver.public_key();

        b.buyer
            .send_file(&solver, &pdf_with("INCOMING-EVIDENCE-MARKER"), "in.pdf")
            .await;
        let got = file_message(&b, ChatParty::Buyer, "in.pdf").await;
        open_on(&b.router, DISPUTE_A, ChatParty::Buyer, &got.id)
            .await
            .unwrap();
        let sent = send_on(
            &b.router,
            DISPUTE_A,
            ChatParty::Buyer,
            pdf_with("OUTGOING-EVIDENCE-MARKER"),
            "out.pdf",
            "u",
        )
        .await
        .unwrap();
        eventually("sent", || async {
            b.messages(DISPUTE_A, ChatParty::Buyer)
                .await
                .iter()
                .any(|m| m.id == sent.id && m.delivery == ChatDelivery::Sent)
        })
        .await;

        let mut written = Vec::new();
        for suffix in ["", "-wal", "-shm"] {
            if let Ok(bytes) = std::fs::read(format!("{}{suffix}", path.to_str().unwrap())) {
                written.extend(bytes);
            }
        }
        let sha = payload::parse(&got_content(&b, &got.id).await)
            .unwrap()
            .sha256;
        let cached = storage.get_attachment_blob(&sha).await.unwrap().unwrap();
        assert!(
            written
                .windows(cached.len().min(64))
                .any(|w| w == &cached[..cached.len().min(64)]),
            "the encrypted blob is in the cache, so the scan sees it"
        );
        for marker in [
            &b"INCOMING-EVIDENCE-MARKER"[..],
            b"OUTGOING-EVIDENCE-MARKER",
        ] {
            assert!(
                !written.windows(marker.len()).any(|w| w == marker),
                "a plaintext was written"
            );
        }
        let text = String::from_utf8_lossy(&written).to_lowercase();
        for party in [&b.buyer.keys, &b.seller.keys] {
            let key = file_enc::attachment_key(&b.solver, &party.public_key()).unwrap();
            assert!(
                !text.contains(&hex::encode(*key)),
                "a file key was written as hex"
            );
            assert!(
                !written.windows(32).any(|w| w == &key[..]),
                "a file key was written as bytes"
            );
        }
    }

    async fn got_content(b: &Bench, id: &str) -> String {
        b.router
            .store
            .get(&b.channel(DISPUTE_A, ChatParty::Buyer), id)
            .await
            .unwrap()
            .unwrap()
            .content
    }
}
