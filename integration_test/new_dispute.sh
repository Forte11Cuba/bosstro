#!/usr/bin/env bash
# Adds a test order and an `initiated` dispute, with fresh buyer and seller
# trade keys, to the database of a COPY of a mostrod home (never ~/.mostro),
# and publishes the dispute's kind 38386, signed by that node's key, to the
# local relay. With SOLVER_PK set, registers that key as a read-write solver.
# Prints E2E_DISPUTE / E2E_BUYER / E2E_SELLER lines for the runs in README.md.
#
#   SOLVER_PK=<hex> integration_test/new_dispute.sh <mostrod home copy> [relay]
#
# Needs sqlite3, python3 and nak. The copy must already hold one order in
# `dispute` status: it is cloned with the new keys (ids are 16-byte blobs).
set -euo pipefail
HOME_DIR=${1:?usage: new_dispute.sh <mostrod home copy> [relay]}
RELAY=${2:-ws://localhost:7000}
if [[ "$(realpath "$HOME_DIR")" == "$(realpath ~/.mostro 2>/dev/null || true)" ]]; then
  echo "refusing to touch ~/.mostro: use a copy" >&2
  exit 1
fi
DB=$HOME_DIR/mostro.db
NODE_NSEC=$(grep -m1 nsec_privkey "$HOME_DIR/settings.toml" | sed 's/.*"\(nsec1[0-9a-z]*\)".*/\1/')
NODE_SK=$(nak decode "$NODE_NSEC" 2>/dev/null | tr -d '"' | tail -1)
BUYER=$(nak key generate)
SELLER=$(nak key generate)
BUYER_PK=$(nak key public "$BUYER")
SELLER_PK=$(nak key public "$SELLER")
ORDER=$(python3 -c 'import uuid; print(uuid.uuid4())')
DISPUTE=$(python3 -c 'import uuid; print(uuid.uuid4())')
OHEX=$(echo "$ORDER" | tr -d '-' | tr a-f A-F)
DHEX=$(echo "$DISPUTE" | tr -d '-' | tr a-f A-F)
NOW=$(date +%s)
TEMPLATE=$(sqlite3 "$DB" "SELECT hex(id) FROM orders WHERE status = 'dispute' LIMIT 1;")
[[ -n "$TEMPLATE" ]] || { echo "no order in dispute status to clone" >&2; exit 1; }
sqlite3 "$DB" <<SQL
CREATE TEMP TABLE t AS SELECT * FROM orders WHERE hex(id) = '$TEMPLATE';
UPDATE t SET id = X'$OHEX', event_id = lower(hex(randomblob(32))),
  buyer_pubkey = '$BUYER_PK', master_buyer_pubkey = '$BUYER_PK',
  seller_pubkey = '$SELLER_PK', master_seller_pubkey = '$SELLER_PK',
  creator_pubkey = '$SELLER_PK', dispute_initiator_pubkey = '$BUYER_PK',
  status = 'dispute', created_at = $NOW, taken_at = $NOW;
INSERT INTO orders SELECT * FROM t;
INSERT INTO disputes (id, order_id, status, order_previous_status, solver_pubkey, created_at, taken_at)
  VALUES (X'$DHEX', X'$OHEX', 'initiated', 'fiat-sent', NULL, $NOW, 0);
SQL
if [[ -n "${SOLVER_PK:-}" ]]; then
  sqlite3 "$DB" "INSERT OR IGNORE INTO users (pubkey, is_solver, category, created_at)
                 VALUES ('$SOLVER_PK', 1, 2, $NOW);"
fi
# `</dev/null`: nak otherwise waits on stdin.
nak event -k 38386 -d "$DISPUTE" -t s=initiated -t initiator=buyer -t published_at="$NOW" \
  -t z=dispute -t y=mostro --sec "$NODE_SK" "$RELAY" </dev/null >/dev/null 2>&1
echo "E2E_DISPUTE=$DISPUTE"
echo "E2E_BUYER=$BUYER"
echo "E2E_SELLER=$SELLER"
