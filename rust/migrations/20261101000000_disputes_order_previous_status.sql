-- The order's status when the dispute was opened (active or fiat-sent), from
-- the take's SolverDisputeInfo: whether the buyer had already marked the fiat
-- as sent. NULL for a take stored before this column; a recovery reads it.
ALTER TABLE disputes ADD COLUMN order_previous_status TEXT;
