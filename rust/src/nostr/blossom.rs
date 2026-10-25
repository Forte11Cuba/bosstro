//! Blossom blob storage (BUD-01 / BUD-02) for chat attachments, from
//! MostroP2P/app's `nostr/blossom.rs`. Uploads the way MostroP2P/app does, so
//! the URLs either app sends are ones the other can fetch:
//!
//! * `PUT {server}/upload` with `application/octet-stream`: the blob is
//!   ciphertext, whatever the file was.
//! * Authorised by a kind 24242 event signed by a **throwaway key per
//!   upload**, never the solver key: a Blossom server would otherwise see one
//!   pubkey across every file of every dispute.
//! * The blob lives at `{server}/{sha256}` (BUD-01), the URL sent in the
//!   chat. A download is checked against that hash before it is decrypted.
//!
//! Logs name a server, never a full blob URL.
//!
//! Protocol reference: <https://github.com/hzrd149/blossom>
use anyhow::anyhow;
use sha2::{Digest, Sha256};

use crate::attachments::MAX_BLOB_BYTES;

/// Servers tried in order; the first that accepts the upload is used.
///
/// MostroP2P/app's list: they accept opaque blobs (media-only servers sniff the
/// content and refuse ciphertext) and keep them indefinitely (dispute
/// evidence must not expire).
pub const BLOSSOM_SERVERS: &[&str] = &[
    "https://cdn.hzrd149.com",
    "https://nostr.download",
    "https://blossom-01.uid.ovh",
    "https://files.sovbit.host",
    "https://blssm.us",
];

/// How long one upload or download may take: 25 MB on a slow mobile link.
/// MostroP2P/app's timeout.
const TRANSFER_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(300);
/// Lifetime of the upload authorisation, as MostroP2P/app.
const AUTH_TTL_SECS: i64 = 3600;
/// Most redirects a download follows (never off https).
#[cfg(not(target_arch = "wasm32"))]
const MAX_REDIRECTS: usize = 5;

/// **Debug builds only:** a local Blossom server for the end-to-end test
/// (`integration_test/`), in place of the public list. Its URLs are the only
/// `http://` ones fetched. Release builds never read it.
#[cfg(debug_assertions)]
pub const TEST_SERVER_ENV: &str = "BOSSTRO_TEST_BLOSSOM_SERVER";

#[cfg(debug_assertions)]
fn test_server() -> Option<String> {
    std::env::var(TEST_SERVER_ENV)
        .ok()
        .map(|s| s.trim_end_matches('/').to_string())
        .filter(|s| s.starts_with("http://127.0.0.1:") || s.starts_with("http://localhost:"))
}

#[cfg(not(debug_assertions))]
fn test_server() -> Option<String> {
    None
}

/// The servers an upload tries.
pub fn servers() -> Vec<String> {
    match test_server() {
        Some(server) => vec![server],
        None => BLOSSOM_SERVERS.iter().map(|s| s.to_string()).collect(),
    }
}

/// Whether a blob URL may be fetched: `https://`, or the debug build's test
/// server.
pub fn is_fetchable(url: &str) -> bool {
    url.starts_with("https://")
        || test_server().is_some_and(|server| url.starts_with(&format!("{server}/")))
}

/// Why a transfer failed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BlossomError {
    /// Over [`MAX_BLOB_BYTES`].
    TooLarge,
    /// Every server refused the upload, or none answered.
    UploadFailed,
    /// The download failed, or the URL is not one that may be fetched.
    DownloadFailed,
    /// The bytes downloaded are not the blob the URL names.
    HashMismatch,
}

/// Where an uploaded blob can be fetched from.
#[derive(Debug, Clone, PartialEq)]
pub struct UploadedBlob {
    pub url: String,
    /// Hex SHA-256 of the blob, the last segment of `url`.
    pub sha256: String,
}

/// Hex SHA-256 of `bytes`.
pub fn sha256_hex(bytes: &[u8]) -> String {
    hex::encode(Sha256::digest(bytes))
}

/// The blob hash a Blossom URL names: the last path segment, optionally with
/// an extension (`…/<sha256>.bin`). `None` when it is not 64 hex digits — such
/// a URL cannot be verified, so it is not fetched.
pub fn sha256_from_url(url: &str) -> Option<String> {
    let path = url.split(['?', '#']).next()?;
    let last = path.rsplit('/').next()?;
    let hash = last.split('.').next()?;
    (hash.len() == 64 && hash.bytes().all(|b| b.is_ascii_hexdigit()))
        .then(|| hash.to_ascii_lowercase())
}

/// Upload an encrypted blob to the first of [`servers`] that accepts it.
pub async fn upload_blob(bytes: &[u8]) -> Result<UploadedBlob, BlossomError> {
    let servers = servers();
    let servers: Vec<&str> = servers.iter().map(String::as_str).collect();
    upload_to(&servers, bytes).await
}

pub(crate) async fn upload_to(
    servers: &[&str],
    bytes: &[u8],
) -> Result<UploadedBlob, BlossomError> {
    if bytes.len() > MAX_BLOB_BYTES {
        return Err(BlossomError::TooLarge);
    }
    let sha256 = sha256_hex(bytes);
    for server in servers {
        let server = server.trim_end_matches('/');
        match try_upload(server, &sha256, bytes).await {
            Ok(()) => {
                return Ok(UploadedBlob {
                    url: format!("{server}/{sha256}"),
                    sha256,
                })
            }
            Err(e) => log::warn!("[blossom] upload to {server} failed: {e}"),
        }
    }
    Err(BlossomError::UploadFailed)
}

/// Download a blob and verify it is the one `url` names. `on_progress`
/// receives the fraction received (0.0–1.0) when the server sends a
/// `Content-Length`.
pub async fn download_blob(url: &str, on_progress: impl Fn(f64)) -> Result<Vec<u8>, BlossomError> {
    if !is_fetchable(url) {
        return Err(BlossomError::DownloadFailed);
    }
    fetch_verified(url, on_progress).await
}

/// The kind 24242 authorisation for uploading `sha256`, signed by a key
/// generated for this upload alone. Returns the `Authorization` header value.
fn upload_auth(sha256: &str) -> anyhow::Result<String> {
    use base64::{engine::general_purpose::STANDARD, Engine};
    use nostr_sdk::prelude::*;

    let keys = Keys::generate();
    let expiration = crate::rt::unix_now() + AUTH_TTL_SECS;
    let event = EventBuilder::new(Kind::Custom(24242), "Upload attachment")
        .tag(Tag::parse(["t", "upload"])?)
        .tag(Tag::parse(["x", sha256])?)
        .tag(Tag::parse(["expiration", &expiration.to_string()])?)
        .finalize(&keys)?;
    Ok(format!("Nostr {}", STANDARD.encode(event.as_json())))
}

/// The same client on both targets: hyper natively, the browser's `fetch` on
/// the web (a CORS request from a cross-origin isolated page; MostroP2P/app's
/// servers answer `Access-Control-Allow-Origin: *`, and one whose preflight
/// does not name `Authorization` refuses the upload, so the next is tried). The
/// timeout is set per request: the wasm builder has none. Natively a redirect
/// may not leave https, as the node pictures.
fn http_client() -> anyhow::Result<reqwest::Client> {
    let builder = reqwest::Client::builder();
    #[cfg(not(target_arch = "wasm32"))]
    let builder = builder.redirect(reqwest::redirect::Policy::custom(|attempt| {
        if attempt.url().scheme() != "https" {
            attempt.stop()
        } else if attempt.previous().len() > MAX_REDIRECTS {
            attempt.error("too many redirects")
        } else {
            attempt.follow()
        }
    }));
    builder
        .build()
        .map_err(|e| anyhow!("HTTP client build failed: {e}"))
}

/// Attempt one server. BUD-02 answers with a blob descriptor; when it names a
/// hash, it must be ours — a server that stored something else would hand the
/// party a URL that fails verification.
async fn try_upload(server: &str, sha256: &str, bytes: &[u8]) -> anyhow::Result<()> {
    let response = http_client()?
        .put(format!("{server}/upload"))
        .timeout(TRANSFER_TIMEOUT)
        .header("Content-Type", "application/octet-stream")
        .header("Authorization", upload_auth(sha256)?)
        .body(bytes.to_vec())
        .send()
        .await
        .map_err(|e| anyhow!("PUT /upload failed: {}", e.without_url()))?;
    let status = response.status();
    if !status.is_success() {
        anyhow::bail!("server returned {status}");
    }
    let body = response.text().await.unwrap_or_default();
    if let Ok(descriptor) = serde_json::from_str::<serde_json::Value>(&body) {
        if let Some(stored) = descriptor.get("sha256").and_then(|v| v.as_str()) {
            if !stored.eq_ignore_ascii_case(sha256) {
                anyhow::bail!("the server stored a different blob");
            }
        }
    }
    Ok(())
}

pub(crate) async fn fetch_verified(
    url: &str,
    on_progress: impl Fn(f64),
) -> Result<Vec<u8>, BlossomError> {
    use futures_util::StreamExt;

    let expected = sha256_from_url(url).ok_or(BlossomError::DownloadFailed)?;
    let failed = |e: &dyn std::fmt::Display| {
        log::warn!("[blossom] download failed: {e}");
        BlossomError::DownloadFailed
    };
    let response = http_client()
        .map_err(|e| failed(&e))?
        .get(url)
        .timeout(TRANSFER_TIMEOUT)
        .send()
        .await
        .map_err(|e| failed(&e.without_url()))?;
    if !response.status().is_success() {
        return Err(failed(&response.status()));
    }
    let mut body = Received::new(response.content_length())?;
    let mut chunks = response.bytes_stream();
    while let Some(chunk) = chunks.next().await {
        let chunk = chunk.map_err(|e| failed(&e.without_url()))?;
        if let Some(fraction) = body.push(&chunk)? {
            on_progress(fraction);
        }
    }
    let bytes = body.bytes;
    if sha256_hex(&bytes) != expected {
        return Err(BlossomError::HashMismatch);
    }
    Ok(bytes)
}

/// A download body as it arrives, held to [`MAX_BLOB_BYTES`] by the declared
/// length and by the bytes themselves: a server may omit the header or lie.
struct Received {
    bytes: Vec<u8>,
    total: Option<u64>,
}

impl Received {
    fn new(total: Option<u64>) -> Result<Self, BlossomError> {
        if total.is_some_and(|len| len > MAX_BLOB_BYTES as u64) {
            return Err(BlossomError::TooLarge);
        }
        let capacity = total.unwrap_or(0) as usize;
        Ok(Self {
            bytes: Vec::with_capacity(capacity),
            total,
        })
    }

    /// Append a chunk; the fraction received, when the length is known.
    fn push(&mut self, chunk: &[u8]) -> Result<Option<f64>, BlossomError> {
        self.bytes.extend_from_slice(chunk);
        if self.bytes.len() > MAX_BLOB_BYTES {
            return Err(BlossomError::TooLarge);
        }
        Ok(self
            .total
            .filter(|t| *t > 0)
            .map(|t| (self.bytes.len() as f64 / t as f64).min(1.0)))
    }
}

/// A minimal HTTP/1.1 server for Blossom tests, from MostroP2P/app.
#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod test_server {
    use std::sync::{Arc, Mutex};
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;

    /// One request as the test server saw it.
    #[derive(Debug, Clone, Default)]
    pub(crate) struct Seen {
        pub method: String,
        pub path: String,
        pub headers: Vec<(String, String)>,
        pub body: Vec<u8>,
    }

    impl Seen {
        pub(crate) fn header(&self, name: &str) -> Option<&str> {
            self.headers
                .iter()
                .find(|(k, _)| k.eq_ignore_ascii_case(name))
                .map(|(_, v)| v.as_str())
        }
    }

    /// A server answering every request with `status` and `body`, recording
    /// what it received. Returns its base URL.
    pub(crate) async fn serve(status: u16, body: Vec<u8>) -> (String, Arc<Mutex<Vec<Seen>>>) {
        serve_with(move |_| (status, body.clone())).await
    }

    /// A server answering each request with what `reply` makes of it.
    pub(crate) async fn serve_with(
        reply: impl Fn(&Seen) -> (u16, Vec<u8>) + Send + 'static,
    ) -> (String, Arc<Mutex<Vec<Seen>>>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let base = format!("http://{}", listener.local_addr().unwrap());
        let seen = Arc::new(Mutex::new(Vec::new()));
        let log = seen.clone();
        tokio::spawn(async move {
            while let Ok((mut socket, _)) = listener.accept().await {
                let mut raw = Vec::new();
                let mut buf = [0u8; 65536];
                // Read headers, then as much body as Content-Length says.
                let (head_end, length) = loop {
                    let n = socket.read(&mut buf).await.unwrap();
                    if n == 0 {
                        return;
                    }
                    raw.extend_from_slice(&buf[..n]);
                    if let Some(pos) = raw.windows(4).position(|w| w == b"\r\n\r\n") {
                        let head = String::from_utf8_lossy(&raw[..pos]).to_string();
                        let length = head
                            .lines()
                            .find_map(|l| {
                                l.to_ascii_lowercase()
                                    .strip_prefix("content-length:")
                                    .map(|v| v.trim().parse::<usize>().unwrap())
                            })
                            .unwrap_or(0);
                        break (pos + 4, length);
                    }
                };
                while raw.len() < head_end + length {
                    let n = socket.read(&mut buf).await.unwrap();
                    raw.extend_from_slice(&buf[..n]);
                }
                let head = String::from_utf8_lossy(&raw[..head_end - 4]).to_string();
                let mut lines = head.lines();
                let mut first = lines.next().unwrap().split(' ');
                let request = Seen {
                    method: first.next().unwrap().to_string(),
                    path: first.next().unwrap().to_string(),
                    headers: lines
                        .filter_map(|l| l.split_once(':'))
                        .map(|(k, v)| (k.trim().to_string(), v.trim().to_string()))
                        .collect(),
                    body: raw[head_end..head_end + length].to_vec(),
                };
                let (status, body) = reply(&request);
                log.lock().unwrap().push(request);
                let reply = format!(
                    "HTTP/1.1 {status} X\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                    body.len()
                );
                socket.write_all(reply.as_bytes()).await.unwrap();
                socket.write_all(&body).await.unwrap();
                socket.shutdown().await.ok();
            }
        });
        (base, seen)
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::test_server::{serve, Seen};
    use super::*;
    use nostr_sdk::prelude::*;
    use std::sync::Mutex;

    fn decoded_auth(seen: &Seen) -> Event {
        use base64::{engine::general_purpose::STANDARD, Engine};
        let header = seen
            .header("Authorization")
            .expect("an Authorization header");
        let json = STANDARD
            .decode(header.strip_prefix("Nostr ").unwrap())
            .unwrap();
        Event::from_json(json).unwrap()
    }

    #[tokio::test]
    async fn uploads_like_app_put_upload_octet_stream_throwaway_signer() {
        let blob = b"ciphertext bytes".to_vec();
        let sha = sha256_hex(&blob);
        let descriptor = format!(r#"{{"sha256":"{sha}","size":16}}"#);
        let (base, seen) = serve(200, descriptor.into_bytes()).await;

        let uploaded = upload_to(&[&base], &blob).await.unwrap();
        assert_eq!(
            uploaded,
            UploadedBlob {
                url: format!("{base}/{sha}"),
                sha256: sha.clone()
            }
        );

        let seen = seen.lock().unwrap()[0].clone();
        assert_eq!(
            (seen.method.as_str(), seen.path.as_str()),
            ("PUT", "/upload")
        );
        assert_eq!(
            seen.header("Content-Type"),
            Some("application/octet-stream")
        );
        assert_eq!(seen.body, blob);
        let auth = decoded_auth(&seen);
        auth.verify().unwrap();
        assert_eq!(auth.kind.as_u16(), 24242);
        let tag = |name: &str| {
            auth.tags
                .iter()
                .find(|t| t.as_slice()[0] == name)
                .map(|t| t.as_slice()[1].clone())
        };
        assert_eq!(tag("t").as_deref(), Some("upload"));
        assert_eq!(tag("x").as_deref(), Some(sha.as_str()));
        assert!(tag("expiration").is_some());
    }

    /// The authorisation is never signed by the solver key (nor by any key
    /// twice): a server cannot link the blobs to the solver or to each other.
    #[tokio::test]
    async fn every_upload_is_signed_by_a_throwaway_key_not_the_solver() {
        let solver = nostr_sdk::prelude::Keys::generate();
        let (base, seen) = serve(200, Vec::new()).await;
        upload_to(&[&base], b"one").await.unwrap();
        upload_to(&[&base], b"two").await.unwrap();
        let seen = seen.lock().unwrap().clone();
        let (a, b) = (decoded_auth(&seen[0]).pubkey, decoded_auth(&seen[1]).pubkey);
        assert_ne!(a, b);
        assert_ne!(a, solver.public_key());
        assert_ne!(b, solver.public_key());
    }

    #[tokio::test]
    async fn falls_back_to_the_next_server() {
        let (refusing, _) = serve(415, b"media only".to_vec()).await;
        let (accepting, seen) = serve(201, Vec::new()).await;
        let uploaded = upload_to(&[&refusing, &accepting], b"blob").await.unwrap();
        assert!(uploaded.url.starts_with(&accepting));
        assert_eq!(seen.lock().unwrap().len(), 1);
        let (still_refusing, _) = serve(500, Vec::new()).await;
        assert_eq!(
            upload_to(&[&still_refusing], b"blob").await.unwrap_err(),
            BlossomError::UploadFailed
        );
    }

    #[tokio::test]
    async fn a_server_that_stored_another_blob_is_not_trusted() {
        let other = "0".repeat(64);
        let (base, _) = serve(200, format!(r#"{{"sha256":"{other}"}}"#).into_bytes()).await;
        assert!(upload_to(&[&base], b"blob").await.is_err());
    }

    #[tokio::test]
    async fn an_oversized_blob_is_not_uploaded() {
        let (base, seen) = serve(200, Vec::new()).await;
        let huge = vec![0u8; MAX_BLOB_BYTES + 1];
        assert_eq!(
            upload_to(&[&base], &huge).await.unwrap_err(),
            BlossomError::TooLarge
        );
        assert!(seen.lock().unwrap().is_empty());
    }

    #[tokio::test]
    async fn a_download_must_match_its_hash() {
        let blob = b"the real ciphertext".to_vec();
        let (base, _) = serve(200, blob.clone()).await;
        let url = format!("{base}/{}", sha256_hex(&blob));
        let progress = Mutex::new(Vec::new());
        let got = fetch_verified(&url, |p| progress.lock().unwrap().push(p))
            .await
            .unwrap();
        assert_eq!(got, blob);
        assert_eq!(progress.lock().unwrap().last().copied(), Some(1.0));

        // A server (or anyone in between) swapping the bytes is caught.
        let (tampered, _) = serve(200, b"something else".to_vec()).await;
        let url = format!("{tampered}/{}", sha256_hex(&blob));
        assert_eq!(
            fetch_verified(&url, |_| {}).await.unwrap_err(),
            BlossomError::HashMismatch
        );
    }

    #[tokio::test]
    async fn an_oversized_download_is_refused() {
        let blob = vec![7u8; MAX_BLOB_BYTES + 1];
        let (base, _) = serve(200, blob.clone()).await;
        let url = format!("{base}/{}", sha256_hex(&blob));
        assert_eq!(
            fetch_verified(&url, |_| {}).await.unwrap_err(),
            BlossomError::TooLarge
        );
    }

    #[tokio::test]
    async fn only_https_blob_urls_are_fetched() {
        let hash = sha256_hex(b"x");
        assert_eq!(
            download_blob(&format!("http://example.com/{hash}"), |_| {})
                .await
                .unwrap_err(),
            BlossomError::DownloadFailed
        );
        assert_eq!(
            download_blob("https://example.com/not-a-hash", |_| {})
                .await
                .unwrap_err(),
            BlossomError::DownloadFailed
        );
    }

    #[test]
    fn a_body_is_held_to_the_limit_whatever_its_header_says() {
        assert!(Received::new(Some(MAX_BLOB_BYTES as u64 + 1)).is_err());

        // Declared length: progress is reported and capped at 1.0.
        let mut body = Received::new(Some(4)).unwrap();
        assert_eq!(body.push(b"ab").unwrap(), Some(0.5));
        assert_eq!(body.push(b"cdef").unwrap(), Some(1.0));

        // No length: no progress, and the bytes alone enforce the cap.
        let mut body = Received::new(None).unwrap();
        assert_eq!(body.push(b"x").unwrap(), None);
        assert!(body.push(&vec![0u8; MAX_BLOB_BYTES]).is_err());
    }

    #[test]
    fn reads_the_hash_from_blossom_urls() {
        let h = "B1674191A88EC5CDD733E4240A81803105DC412D6C6708D53AB94FC248F4F553";
        assert_eq!(
            sha256_from_url(&format!("https://cdn.hzrd149.com/{h}")),
            Some(h.to_ascii_lowercase())
        );
        assert_eq!(
            sha256_from_url(&format!("https://x.y/{h}.bin?download=1")),
            Some(h.to_ascii_lowercase())
        );
        assert_eq!(sha256_from_url("https://x.y/abc"), None);
    }
}
