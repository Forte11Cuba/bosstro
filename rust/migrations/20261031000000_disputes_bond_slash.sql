-- Bond slash: which anti-abuse bonds this solver's resolution slashed
-- (no-slash, buyer, seller, both), with resolved_as. NULL while open, for a
-- dispute that closed some other way, and for one resolved before this
-- column (it reads as not known).
ALTER TABLE disputes ADD COLUMN bond_slash TEXT;
