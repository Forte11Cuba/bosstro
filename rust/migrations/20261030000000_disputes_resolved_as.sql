-- Phase 6: how a dispute this solver held ended, from the node's answer to
-- its own AdminSettle / AdminCancel: paid-buyer, refunded-seller or
-- cooperatively-canceled (CooperativeCancelAccepted). NULL until then, and
-- for a dispute that closed some other way. A 38386 status says what
-- happened to the dispute; this says that this key did it.
ALTER TABLE disputes ADD COLUMN resolved_as TEXT;
