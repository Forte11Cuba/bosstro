//! What may be attached, decided by the bytes — never by the file name or a
//! MIME type the platform or a party claims. From MostroP2P/app's
//! `attachments/media.rs`.
//!
//! Sent: JPEG, PNG and PDF. Images are decoded and re-encoded before they
//! leave the device, which drops EXIF (GPS position, device, time) and any
//! other metadata; the orientation is applied to the pixels first so a phone
//! photo does not arrive sideways. Decoding is bounded, against
//! decompression bombs.
//!
//! Received: only JPEG, PNG and PDF are shown or saved, again by their bytes
//! once decrypted ([`check_received`]). MostroP2P/app sends nothing else.
use std::io::Cursor;

use anyhow::{anyhow, bail, Result};
use image::{DynamicImage, ImageDecoder, ImageFormat, ImageReader, Limits};

use crate::attachments::MAX_ATTACHMENT_BYTES;

/// Largest image side accepted, in pixels.
const MAX_IMAGE_SIDE: u32 = 10_000;
/// Memory the decoder may allocate: bounds a decompression bomb.
const MAX_DECODE_ALLOC: u64 = 256 * 1024 * 1024;
/// JPEG quality of the re-encoded image, as MostroP2P/app.
const JPEG_QUALITY: u8 = 90;
/// Longest file name kept, in characters.
const MAX_NAME_CHARS: usize = 120;

/// A file type recognised by its signature.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Jpeg,
    Png,
    Pdf,
}

impl Kind {
    pub fn mime(self) -> &'static str {
        match self {
            Kind::Jpeg => "image/jpeg",
            Kind::Png => "image/png",
            Kind::Pdf => "application/pdf",
        }
    }

    pub fn is_image(self) -> bool {
        matches!(self, Kind::Jpeg | Kind::Png)
    }

    fn format(self) -> Option<ImageFormat> {
        match self {
            Kind::Jpeg => Some(ImageFormat::Jpeg),
            Kind::Png => Some(ImageFormat::Png),
            Kind::Pdf => None,
        }
    }
}

/// Recognise JPEG, PNG and PDF by their leading bytes.
pub fn sniff(bytes: &[u8]) -> Option<Kind> {
    if bytes.starts_with(&[0xFF, 0xD8, 0xFF]) {
        Some(Kind::Jpeg)
    } else if bytes.starts_with(&[0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A]) {
        Some(Kind::Png)
    } else if bytes.starts_with(b"%PDF-") {
        Some(Kind::Pdf)
    } else {
        None
    }
}

/// Why a file is refused. The send path and the open path share them.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Refusal {
    /// Over [`MAX_ATTACHMENT_BYTES`].
    TooLarge,
    /// Not a JPEG, PNG or PDF.
    Unsupported,
    /// An image that does not decode, or is beyond the decoding limits.
    InvalidImage,
}

/// A file ready to be encrypted and uploaded.
#[derive(Debug)]
pub struct Prepared {
    pub kind: Kind,
    /// The bytes to encrypt: re-encoded for images, untouched for PDFs.
    pub bytes: Vec<u8>,
    pub width: Option<u32>,
    pub height: Option<u32>,
}

/// Check and clean a file the solver picked, before it is encrypted.
pub fn prepare_for_send(bytes: Vec<u8>) -> Result<Prepared, Refusal> {
    if bytes.len() > MAX_ATTACHMENT_BYTES {
        return Err(Refusal::TooLarge);
    }
    let kind = sniff(&bytes).ok_or(Refusal::Unsupported)?;
    if kind == Kind::Pdf {
        return Ok(Prepared {
            kind,
            bytes,
            width: None,
            height: None,
        });
    }
    let image = decode(&bytes, kind).map_err(|e| {
        log::debug!("[attachments] image refused: {e}");
        Refusal::InvalidImage
    })?;
    let (width, height) = (image.width(), image.height());
    let bytes = encode(&image, kind).map_err(|e| {
        log::debug!("[attachments] image not re-encoded: {e}");
        Refusal::InvalidImage
    })?;
    if bytes.len() > MAX_ATTACHMENT_BYTES {
        return Err(Refusal::TooLarge);
    }
    Ok(Prepared {
        kind,
        bytes,
        width: Some(width),
        height: Some(height),
    })
}

/// What a decrypted file from a party really is. Only JPEG, PNG and PDF are
/// handed to Dart; an image is checked against the same decoding limits as
/// one sent (its header only: the pixels are decoded by Dart, at a bounded
/// size), so Flutter never decodes a bomb.
pub fn check_received(bytes: &[u8]) -> Result<Kind, Refusal> {
    if bytes.len() > MAX_ATTACHMENT_BYTES {
        return Err(Refusal::TooLarge);
    }
    let kind = sniff(bytes).ok_or(Refusal::Unsupported)?;
    if let Some(format) = kind.format() {
        let (width, height) = ImageReader::with_format(Cursor::new(bytes), format)
            .into_dimensions()
            .map_err(|_| Refusal::InvalidImage)?;
        if !within_limits(width, height) {
            return Err(Refusal::InvalidImage);
        }
    }
    Ok(kind)
}

fn within_limits(width: u32, height: u32) -> bool {
    width > 0
        && height > 0
        && width <= MAX_IMAGE_SIDE
        && height <= MAX_IMAGE_SIDE
        && u64::from(width) * u64::from(height) * 4 <= MAX_DECODE_ALLOC
}

fn decode(bytes: &[u8], kind: Kind) -> Result<DynamicImage> {
    let format = kind.format().ok_or_else(|| anyhow!("not an image"))?;
    let mut limits = Limits::default();
    limits.max_image_width = Some(MAX_IMAGE_SIDE);
    limits.max_image_height = Some(MAX_IMAGE_SIDE);
    limits.max_alloc = Some(MAX_DECODE_ALLOC);
    let mut reader = ImageReader::with_format(Cursor::new(bytes), format);
    reader.limits(limits);
    let mut decoder = reader.into_decoder()?;
    let orientation = decoder.orientation()?;
    let mut image = DynamicImage::from_decoder(decoder)?;
    image.apply_orientation(orientation);
    Ok(image)
}

fn encode(image: &DynamicImage, kind: Kind) -> Result<Vec<u8>> {
    let mut out = Cursor::new(Vec::new());
    match kind {
        Kind::Jpeg => {
            // JPEG has no alpha: flatten so an RGBA source still encodes.
            let rgb = DynamicImage::ImageRgb8(image.to_rgb8());
            let encoder =
                image::codecs::jpeg::JpegEncoder::new_with_quality(&mut out, JPEG_QUALITY);
            rgb.write_with_encoder(encoder)?
        }
        Kind::Png => image.write_to(&mut out, ImageFormat::Png)?,
        Kind::Pdf => bail!("PDFs are not re-encoded"),
    }
    Ok(out.into_inner())
}

/// A file name safe to show and to save under: the last path component only,
/// no control or invisible characters, bounded length. A party chooses it,
/// so it is untrusted — `../../x` must not escape a directory.
pub fn sanitize_filename(name: &str) -> String {
    let last = name.rsplit(['/', '\\']).next().unwrap_or("");
    // `: * ? " < > |` too: legal on the sender's side, but creating the file
    // fails on Windows and FAT/exFAT storage.
    let clean: String = last
        .chars()
        .filter(|c| {
            !c.is_control()
                && !is_invisible_format(*c)
                && !matches!(c, ':' | '*' | '?' | '"' | '<' | '>' | '|')
        })
        .collect();
    let clean = clean.trim().trim_start_matches('.').trim();
    if clean.is_empty() {
        return "attachment".to_string();
    }
    if clean.chars().count() <= MAX_NAME_CHARS {
        return clean.to_string();
    }
    // Keep the extension when shortening.
    match clean.rsplit_once('.') {
        Some((stem, ext)) if ext.chars().count() <= 10 => {
            let keep = MAX_NAME_CHARS - ext.chars().count() - 1;
            format!("{}.{ext}", stem.chars().take(keep).collect::<String>())
        }
        _ => clean.chars().take(MAX_NAME_CHARS).collect(),
    }
}

/// Bidirectional overrides and zero-width characters: not controls, but they
/// let a name lie about itself — `recibo\u{202E}fdp.exe` shows as
/// `reciboexe.pdf`.
fn is_invisible_format(c: char) -> bool {
    matches!(
        c,
        '\u{200B}'..='\u{200F}' | '\u{202A}'..='\u{202E}' | '\u{2060}'..='\u{2069}' | '\u{FEFF}'
    )
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use image::{Rgb, RgbImage};

    pub(crate) fn jpeg(width: u32, height: u32) -> Vec<u8> {
        let img = DynamicImage::ImageRgb8(RgbImage::from_pixel(width, height, Rgb([200, 30, 30])));
        let mut out = Cursor::new(Vec::new());
        img.write_to(&mut out, ImageFormat::Jpeg).unwrap();
        out.into_inner()
    }

    pub(crate) fn png(width: u32, height: u32) -> Vec<u8> {
        let img = DynamicImage::ImageRgba8(image::RgbaImage::from_pixel(
            width,
            height,
            image::Rgba([1, 2, 3, 128]),
        ));
        let mut out = Cursor::new(Vec::new());
        img.write_to(&mut out, ImageFormat::Png).unwrap();
        out.into_inner()
    }

    pub(crate) const PDF: &[u8] = b"%PDF-1.4\n1 0 obj<<>>endobj\n%%EOF";

    /// Splice an APP1/Exif segment right after SOI, carrying an orientation
    /// tag and a fake GPS marker string.
    fn with_exif(jpeg: &[u8], orientation: u16) -> Vec<u8> {
        let mut tiff = Vec::new();
        tiff.extend_from_slice(b"MM\x00\x2A\x00\x00\x00\x08"); // big-endian TIFF, IFD at 8
        tiff.extend_from_slice(&1u16.to_be_bytes()); // one entry
        tiff.extend_from_slice(&0x0112u16.to_be_bytes()); // Orientation
        tiff.extend_from_slice(&3u16.to_be_bytes()); // SHORT
        tiff.extend_from_slice(&1u32.to_be_bytes()); // count
        tiff.extend_from_slice(&orientation.to_be_bytes());
        tiff.extend_from_slice(&[0, 0]);
        tiff.extend_from_slice(&0u32.to_be_bytes()); // no next IFD
        tiff.extend_from_slice(b"GPS-SECRET-LOCATION");
        let mut app1 = b"Exif\x00\x00".to_vec();
        app1.extend_from_slice(&tiff);
        let len = (app1.len() + 2) as u16;
        let mut out = jpeg[..2].to_vec(); // SOI
        out.extend_from_slice(&[0xFF, 0xE1]);
        out.extend_from_slice(&len.to_be_bytes());
        out.extend_from_slice(&app1);
        out.extend_from_slice(&jpeg[2..]);
        out
    }

    fn contains(haystack: &[u8], needle: &[u8]) -> bool {
        haystack.windows(needle.len()).any(|w| w == needle)
    }

    /// A PNG header claiming `width` × `height`, with no pixels behind it.
    fn png_header(width: u32, height: u32) -> Vec<u8> {
        let mut out = b"\x89PNG\r\n\x1a\n".to_vec();
        let mut ihdr = b"IHDR".to_vec();
        ihdr.extend_from_slice(&width.to_be_bytes());
        ihdr.extend_from_slice(&height.to_be_bytes());
        ihdr.extend_from_slice(&[8, 6, 0, 0, 0]);
        out.extend_from_slice(&13u32.to_be_bytes());
        out.extend_from_slice(&ihdr);
        let crc = crc32(&ihdr);
        out.extend_from_slice(&crc.to_be_bytes());
        out
    }

    fn crc32(bytes: &[u8]) -> u32 {
        let mut crc = 0xFFFF_FFFFu32;
        for &b in bytes {
            crc ^= u32::from(b);
            for _ in 0..8 {
                crc = if crc & 1 == 1 {
                    (crc >> 1) ^ 0xEDB8_8320
                } else {
                    crc >> 1
                };
            }
        }
        !crc
    }

    #[test]
    fn sniffs_by_content_not_by_name() {
        assert_eq!(sniff(&jpeg(2, 2)), Some(Kind::Jpeg));
        assert_eq!(sniff(PDF), Some(Kind::Pdf));
        assert_eq!(sniff(&png(2, 2)), Some(Kind::Png));
        assert_eq!(sniff(b"GIF89a"), None);
        assert_eq!(sniff(b"PK\x03\x04 docx"), None);
    }

    #[test]
    fn an_image_loses_its_metadata_and_keeps_its_orientation() {
        let original = with_exif(&jpeg(40, 20), 6); // 6 = rotate 90° clockwise
        assert!(contains(&original, b"GPS-SECRET-LOCATION"));
        let p = prepare_for_send(original).unwrap();
        assert_eq!(p.kind, Kind::Jpeg);
        assert!(
            !contains(&p.bytes, b"Exif"),
            "EXIF must not leave the device"
        );
        assert!(!contains(&p.bytes, b"GPS-SECRET-LOCATION"));
        // The rotation is now in the pixels: 40×20 turned becomes 20×40.
        assert_eq!((p.width, p.height), (Some(20), Some(40)));
        assert_eq!(sniff(&p.bytes), Some(Kind::Jpeg));
    }

    #[test]
    fn a_png_stays_a_png_and_a_pdf_passes_untouched() {
        let p = prepare_for_send(png(3, 5)).unwrap();
        assert_eq!((p.kind, p.width, p.height), (Kind::Png, Some(3), Some(5)));
        let p = prepare_for_send(PDF.to_vec()).unwrap();
        assert_eq!((p.kind, p.bytes.as_slice()), (Kind::Pdf, PDF));
    }

    #[test]
    fn refuses_what_it_cannot_vouch_for() {
        assert_eq!(
            prepare_for_send(b"hello".to_vec()).unwrap_err(),
            Refusal::Unsupported
        );
        assert_eq!(
            prepare_for_send(vec![0xFF, 0xD8, 0xFF, 0x00, 0x01]).unwrap_err(),
            Refusal::InvalidImage
        );
        let mut huge = b"%PDF-".to_vec();
        huge.resize(MAX_ATTACHMENT_BYTES + 1, 0);
        assert_eq!(prepare_for_send(huge).unwrap_err(), Refusal::TooLarge);
        // A decompression bomb: the header alone claims 20 000 × 20 000.
        assert_eq!(
            prepare_for_send(png_header(20_000, 20_000)).unwrap_err(),
            Refusal::InvalidImage
        );
    }

    #[test]
    fn a_received_file_is_what_its_bytes_say() {
        assert_eq!(check_received(&jpeg(4, 4)), Ok(Kind::Jpeg));
        assert_eq!(check_received(&png(4, 4)), Ok(Kind::Png));
        assert_eq!(check_received(PDF), Ok(Kind::Pdf));
        assert_eq!(
            check_received(b"MZ\x90\x00 an exe"),
            Err(Refusal::Unsupported)
        );
        assert_eq!(
            check_received(&png_header(20_000, 20_000)),
            Err(Refusal::InvalidImage)
        );
        assert_eq!(
            check_received(&png_header(9_000, 9_000)),
            Err(Refusal::InvalidImage)
        );
        assert_eq!(
            check_received(&png_header(0, 10)),
            Err(Refusal::InvalidImage)
        );
    }

    #[test]
    fn file_names_cannot_escape_or_mislead() {
        assert_eq!(sanitize_filename("../../etc/passwd"), "passwd");
        assert_eq!(sanitize_filename("C:\\Users\\a\\recibo.pdf"), "recibo.pdf");
        assert_eq!(sanitize_filename("foto\u{202e}gpj.exe"), "fotogpj.exe");
        assert_eq!(sanitize_filename("a:b*c?\"d<e>f|.pdf"), "abcdef.pdf");
        assert_eq!(sanitize_filename("  "), "attachment");
        assert_eq!(sanitize_filename(".."), "attachment");
        let long = format!("{}.pdf", "a".repeat(300));
        let short = sanitize_filename(&long);
        assert!(short.ends_with(".pdf") && short.chars().count() == MAX_NAME_CHARS);
    }
}
