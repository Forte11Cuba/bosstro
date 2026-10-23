-- Phase 2 (A4): the settings key-value store, the relays and the node
-- pictures. Same tables as ../app's schema.rs; phase 3 adds the disputes in
-- a migration of its own. Never edit a migration that has shipped: sqlx
-- checks each applied file's checksum and refuses to open the database.

-- Generic key-value settings (active node, node registry blobs, node info).
-- Keys: crate::db::settings_keys.
CREATE TABLE settings (
    key             TEXT PRIMARY KEY NOT NULL,
    value           TEXT NOT NULL
);

-- One row per relay URL, as JSON (crate::api::relays::RelayInfo). Device-wide
-- (one list for every node); a relay a node announced carries that node's
-- pubkey inside the JSON (`announced_by`, D6).
CREATE TABLE relays (
    url             TEXT PRIMARY KEY NOT NULL,
    data            TEXT NOT NULL
);

-- Each node's kind 0 picture as downloaded (crate::node_pictures), with the
-- URL it came from: fetched again only when the profile names another.
CREATE TABLE node_pictures (
    pubkey          TEXT PRIMARY KEY NOT NULL,
    url             TEXT NOT NULL,
    data            BLOB NOT NULL,
    fetched_at      INTEGER NOT NULL
);
