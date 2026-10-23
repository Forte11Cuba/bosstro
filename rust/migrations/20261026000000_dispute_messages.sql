-- Phase 5: the dispute chat. One row per message of one conversation: a node,
-- a dispute, a party (buyer or seller) and the solver key that holds it (D6).
-- The inner event id is the message's identity: a copy from another relay,
-- the solver's own message coming back (K_sign is shared) and a replay are
-- all the same row. No key is stored: the channel keys are derived in memory
-- from the loaded solver key (crate::chat).

CREATE TABLE dispute_messages (
    mostro_pubkey   TEXT NOT NULL,
    dispute_id      TEXT NOT NULL,
    -- buyer or seller: whose conversation.
    party           TEXT NOT NULL,
    -- The solver key (hex) of the conversation.
    solver_pubkey   TEXT NOT NULL,
    -- The verified inner event id (hex).
    message_id      TEXT NOT NULL,
    -- buyer, seller or you: the verified inner signer.
    sender          TEXT NOT NULL,
    content         TEXT NOT NULL,
    -- The inner event's created_at, as its writer set it.
    created_at      INTEGER NOT NULL,
    -- This device's clock when the message was accepted (or sent). The
    -- subscription cursor is the newest min(created_at, received_at), so a
    -- message dated in the future never moves it past the local clock.
    received_at     INTEGER NOT NULL,
    -- sending, sent or failed (only this key's messages are ever not sent).
    delivery        TEXT NOT NULL,

    PRIMARY KEY (mostro_pubkey, dispute_id, party, solver_pubkey, message_id)
);
