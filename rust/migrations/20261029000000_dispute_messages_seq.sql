-- Phase 5c review: the order messages arrived in, to sort those of the same
-- second (created_at has a resolution of one second, and the inner id is
-- random). Assigned on insert as one more than the table's highest; the rows
-- already stored take their rowid, which is the order they were inserted in.
ALTER TABLE dispute_messages ADD COLUMN seq INTEGER NOT NULL DEFAULT 0;
UPDATE dispute_messages SET seq = rowid;
