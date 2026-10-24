-- When the node answered this solver's resolution (Unix seconds, the device's
-- clock), with resolved_as: the closed list says how long ago it closed before
-- the node's terminal 38386 arrives. NULL while open, for a dispute that closed
-- some other way (its 38386 revision gives the time), and for one resolved
-- before this column.
ALTER TABLE disputes ADD COLUMN resolved_at INTEGER;
