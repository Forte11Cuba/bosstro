-- Phase 4: which solver key took the dispute (hex), set with the other take
-- columns from AdminTookDispute. A take belongs to one key: after a log out
-- and a log in with another nsec, the previous key's disputes are not this
-- key's to work on. NULL while `taken_at` is NULL.
ALTER TABLE disputes ADD COLUMN solver_pubkey TEXT;
