-- Phase 3: Pending reads one node's `initiated` disputes. A file of its own
-- rather than an edit of 20261024000000, which databases already applied.
CREATE INDEX disputes_by_node_status ON disputes (mostro_pubkey, status);
