-- Phase 5c: the observed chat. What buyer and seller wrote to each other in
-- their own (P2P) chat, read with the shared key one of them disclosed to the
-- solver (or the solver pasted). Its own table, so it never mixes with the
-- solver's conversations (dispute_messages). One row per message, per node,
-- dispute and solver key that read it (D6). The inner event id is the
-- message's identity: copies and re-reads are one row. No key is stored: a
-- disclosed key is the text of a message in dispute_messages, and a pasted
-- one lives in memory only (crate::chat::observer).

CREATE TABLE observed_messages (
    mostro_pubkey   TEXT NOT NULL,
    dispute_id      TEXT NOT NULL,
    -- The solver key (hex) that read it.
    solver_pubkey   TEXT NOT NULL,
    -- The verified inner event id (hex).
    message_id      TEXT NOT NULL,
    -- buyer or seller: the verified inner signer (a trade key the take named).
    sender          TEXT NOT NULL,
    content         TEXT NOT NULL,
    -- The inner event's created_at, as its writer set it.
    created_at      INTEGER NOT NULL,
    -- This device's clock when it was read.
    received_at     INTEGER NOT NULL,

    PRIMARY KEY (mostro_pubkey, dispute_id, solver_pubkey, message_id)
);
