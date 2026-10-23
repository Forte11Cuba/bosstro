-- Phase 3: the disputes of every node the solver has used (D6). One row per
-- (node, dispute id), from the newest kind 38386 revision seen; the shape is
-- Mostrix's `admin_disputes`, trimmed to what the public event carries plus
-- what phase 4 fills from `AdminTookDispute`. Never edit a migration that has
-- shipped: add a file.

CREATE TABLE disputes (
    -- The node that published the 38386 (hex) and the dispute id (its `d`
    -- tag, a UUID). A dispute id is not an order id: the 38386 names no order.
    mostro_pubkey       TEXT NOT NULL,
    dispute_id          TEXT NOT NULL,
    -- Wire status (kebab-case): initiated, in-progress, settled,
    -- seller-refunded, released, cooperatively-canceled.
    status              TEXT NOT NULL,
    -- The `initiator` tag as published: buyer, seller or unknown.
    initiator           TEXT NOT NULL,
    -- When the dispute was opened: the `published_at` tag, or the legacy
    -- `created_at` tag. Never the event's own created_at. NULL when neither.
    opened_at           INTEGER,
    -- NIP-40 `expiration` of the revision, if any.
    expires_at          INTEGER,
    -- The revision this row holds, for NIP-01 ordering across restarts: the
    -- newest created_at wins, then the lowest id.
    event_id            TEXT NOT NULL,
    event_created_at    INTEGER NOT NULL,

    -- Phase 4: set when this solver takes the dispute (AdminTookDispute →
    -- SolverDisputeInfo); all NULL until then, and cleared when the node
    -- reopens it. `taken_at` is the marker: NULL means not taken by us.
    taken_at            INTEGER,
    order_id            TEXT,
    order_kind          TEXT,
    amount              INTEGER,
    fiat_amount         INTEGER,
    fiat_code           TEXT,
    payment_method      TEXT,
    premium             INTEGER,
    fee                 INTEGER,
    initiator_pubkey    TEXT,
    buyer_pubkey        TEXT,
    seller_pubkey       TEXT,

    PRIMARY KEY (mostro_pubkey, dispute_id)
);
