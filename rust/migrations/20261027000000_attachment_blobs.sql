-- Phase 5, part 2: the chat attachment cache (from ../app's attachment_blobs).
-- Encrypted blobs only, exactly as downloaded from Blossom (or as this device
-- uploaded them), keyed by their SHA-256: the decrypted file is never written
-- here, and neither is its key. Bounded (db/sqlite.rs, oldest out first): a
-- miss only costs a download.

CREATE TABLE attachment_blobs (
    sha256      TEXT PRIMARY KEY NOT NULL,
    data        BLOB NOT NULL,
    size        INTEGER NOT NULL,
    created_at  INTEGER NOT NULL
);

CREATE INDEX attachment_blobs_by_age ON attachment_blobs (created_at);
