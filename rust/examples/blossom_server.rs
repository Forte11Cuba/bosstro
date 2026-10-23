//! A local Blossom server for the end-to-end attachment test
//! (`integration_test/`), so no test file reaches a public server. In memory,
//! loopback only, and as small as BUD-01/BUD-02 allow:
//!
//! * `PUT /upload` stores the body at its SHA-256 and answers a descriptor
//!   (`{"sha256","size","url"}`); the `Authorization` header is logged, not
//!   checked.
//! * `GET /<sha256>` serves it back.
//!
//! ```text
//! cargo run --example blossom_server -- [port]     # default 7001
//! ```
//!
//! The app fetches `http://` blobs only in a debug build, and only from the
//! server named by `BOSSTRO_TEST_BLOSSOM_SERVER` (`nostr/blossom.rs`).

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use sha2::{Digest, Sha256};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

type Blobs = Arc<Mutex<HashMap<String, Vec<u8>>>>;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let port: u16 = std::env::args()
        .nth(1)
        .map(|p| p.parse())
        .transpose()?
        .unwrap_or(7001);
    let listener = TcpListener::bind(("127.0.0.1", port)).await?;
    let base = format!("http://127.0.0.1:{port}");
    println!("blossom test server on {base}");
    let blobs: Blobs = Arc::default();
    loop {
        let (socket, _) = listener.accept().await?;
        let blobs = blobs.clone();
        let base = base.clone();
        tokio::spawn(async move {
            if let Err(e) = serve(socket, &blobs, &base).await {
                eprintln!("request failed: {e}");
            }
        });
    }
}

async fn serve(mut socket: TcpStream, blobs: &Blobs, base: &str) -> std::io::Result<()> {
    let mut raw = Vec::new();
    let mut buf = vec![0u8; 64 * 1024];
    let (head_end, length) = loop {
        let n = socket.read(&mut buf).await?;
        if n == 0 {
            return Ok(());
        }
        raw.extend_from_slice(&buf[..n]);
        if let Some(pos) = raw.windows(4).position(|w| w == b"\r\n\r\n") {
            let head = String::from_utf8_lossy(&raw[..pos]).to_string();
            let length = head
                .lines()
                .find_map(|l| {
                    l.to_ascii_lowercase()
                        .strip_prefix("content-length:")
                        .and_then(|v| v.trim().parse::<usize>().ok())
                })
                .unwrap_or(0);
            break (pos + 4, length);
        }
    };
    while raw.len() < head_end + length {
        let n = socket.read(&mut buf).await?;
        if n == 0 {
            break;
        }
        raw.extend_from_slice(&buf[..n]);
    }
    let head = String::from_utf8_lossy(&raw[..head_end - 4]).to_string();
    let mut first = head.lines().next().unwrap_or_default().split(' ');
    let (method, path) = (
        first.next().unwrap_or_default().to_string(),
        first.next().unwrap_or_default().to_string(),
    );
    let signed = head
        .lines()
        .any(|l| l.to_ascii_lowercase().starts_with("authorization: nostr "));
    let body = raw[head_end..(head_end + length).min(raw.len())].to_vec();

    let (status, reply, kind) = match method.as_str() {
        "PUT" if path == "/upload" => {
            let sha = hex(&Sha256::digest(&body));
            let size = body.len();
            blobs.lock().unwrap().insert(sha.clone(), body);
            println!("PUT /upload {size} bytes → {sha} (signed: {signed})");
            let descriptor = format!(r#"{{"sha256":"{sha}","size":{size},"url":"{base}/{sha}"}}"#);
            ("200 OK", descriptor.into_bytes(), "application/json")
        }
        "GET" => {
            let sha = path.trim_start_matches('/').to_ascii_lowercase();
            match blobs.lock().unwrap().get(&sha) {
                Some(blob) => {
                    println!("GET {sha} ({} bytes)", blob.len());
                    ("200 OK", blob.clone(), "application/octet-stream")
                }
                None => ("404 Not Found", Vec::new(), "text/plain"),
            }
        }
        // CORS preflight, for a run in a browser.
        "OPTIONS" => ("204 No Content", Vec::new(), "text/plain"),
        _ => ("405 Method Not Allowed", Vec::new(), "text/plain"),
    };
    let header = format!(
        "HTTP/1.1 {status}\r\nContent-Type: {kind}\r\nContent-Length: {}\r\n\
         Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Authorization, Content-Type\r\n\
         Access-Control-Allow-Methods: GET, PUT, OPTIONS\r\nConnection: close\r\n\r\n",
        reply.len()
    );
    socket.write_all(header.as_bytes()).await?;
    socket.write_all(&reply).await?;
    socket.shutdown().await
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}
