# Integration tests

Run by hand on Linux, never in CI, and never against a real node.

`take_against_local_mostrod_test.dart` drives the phase 4 screens (not a
solver, a take from Pending, a Recover) through the real Rust core, against a
local relay and a local mostrod with at least one `initiated` dispute and one
`in-progress` dispute held by the solver key. It uses a temporary database
and keeps the key in memory: the developer's data and keyring are untouched.

```bash
flutter test integration_test/take_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:7000 \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_STRANGER=<nsec of a key that is no solver there> \
  --dart-define=E2E_SOLVER=<nsec of a solver key>
```

`chat_against_local_mostrod_test.dart` drives the phase 5 screens: it takes
two `initiated` disputes, opens them, and trades a message each way with
their buyers and sellers (the second take rebuilds the chat's shared REQ;
the first dispute's seller is reached after it). The parties are played by `rust/examples/chat_party.rs`
with their trade secret keys, so each dispute's order must name trade keys you
hold: create a test order and dispute for each in a copy of the node's
database, and publish its kind 38386 (signed by the node key) to the local
relay. The solver key must be a solver there (`users.is_solver = 1`).

```bash
(cd rust && cargo build --example chat_party)
flutter test integration_test/chat_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:7000 \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_SOLVER=<solver secret> \
  --dart-define=E2E_SOLVER_PUBKEY=<solver pubkey hex> \
  --dart-define=E2E_DISPUTE=<dispute id> \
  --dart-define=E2E_BUYER=<buyer trade secret hex> \
  --dart-define=E2E_SELLER=<seller trade secret hex> \
  --dart-define=E2E_DISPUTE_2=<second dispute id> \
  --dart-define=E2E_BUYER_2=<its buyer trade secret hex> \
  --dart-define=E2E_SELLER_2=<its seller trade secret hex> \
  --dart-define=E2E_PARTY_BIN=$PWD/rust/target/debug/examples/chat_party
```

Run mostrod from a copy of its settings directory (`mostrod -d <dir>`) whose
`[nostr] relays` lists only the local relay, so neither the test rows nor the
node's answers reach a real relay.

`attachments_against_local_mostrod_test.dart` drives the phase 5 attachments:
it takes one `initiated` dispute; its buyer sends an image and a PDF, which
the app shows, verifies and saves (Save hands its bytes to a test saver, as
the system's save dialog cannot be driven) byte for byte; then the solver
sends a photo from the gallery (a test picker) to the seller, who decrypts
it, and its EXIF (camera, GPS) must be gone. The party (`chat_party`, with
`--send-file` / `--expect-file`) writes and reads MostroP2P/app's format
with code of its own. Blobs go to a local Blossom server (`blossom_server`),
never a public one: the app reaches it only in a debug build, through
`BOSSTRO_TEST_BLOSSOM_SERVER` (`rust/src/nostr/blossom.rs`), the only
`http://` origin it fetches from.

`E2E_FILES` is a directory with `party-photo.jpg`, `bank-statement.pdf` and
`solver-photo.jpg`; the solver's photo must carry EXIF with the text
`BosstroTestCam` (Pillow: `Image.Exif()`, tag `0x010F`), which the test checks
is gone on arrival.

```bash
(cd rust && cargo build --example chat_party --example blossom_server)
rust/target/debug/examples/blossom_server 7001 &
BOSSTRO_TEST_BLOSSOM_SERVER=http://127.0.0.1:7001 \
flutter test integration_test/attachments_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:7000 \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_SOLVER=<solver secret> \
  --dart-define=E2E_SOLVER_PUBKEY=<solver pubkey hex> \
  --dart-define=E2E_DISPUTE=<dispute id> \
  --dart-define=E2E_BUYER=<buyer trade secret hex> \
  --dart-define=E2E_SELLER=<seller trade secret hex> \
  --dart-define=E2E_PARTY_BIN=$PWD/rust/target/debug/examples/chat_party \
  --dart-define=E2E_BLOSSOM=http://127.0.0.1:7001 \
  --dart-define=E2E_FILES=<directory>
```

`observer_against_local_mostrod_test.dart` drives the phase 5c screens: the
buyer and the seller write to each other in their own chat (`chat_party
--peer <other pubkey> --say`), the seller sends a PDF there (`--send-file`,
encrypted as MostroP2P/app does under the two trade keys) and then shares
the chat key with the solver (`--share-key`). The app takes the dispute,
sees the disclosure in Info, reads both sides, shows the file as one that
cannot be opened and offers no message field; a random key pasted opens nothing and
says so; the right key (`--print-key`) pasted reads; Refresh brings a later
message, none twice. Same defines as the attachments run (`E2E_FILES` needs
only `bank-statement.pdf`), with one dispute:

```bash
(cd rust && cargo build --example chat_party --example blossom_server)
rust/target/debug/examples/blossom_server 7001 &
BOSSTRO_TEST_BLOSSOM_SERVER=http://127.0.0.1:7001 \
flutter test integration_test/observer_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:7000 \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_SOLVER=<solver secret> \
  --dart-define=E2E_SOLVER_PUBKEY=<solver pubkey hex> \
  --dart-define=E2E_DISPUTE=<dispute id> \
  --dart-define=E2E_BUYER=<buyer trade secret hex> \
  --dart-define=E2E_SELLER=<seller trade secret hex> \
  --dart-define=E2E_PARTY_BIN=$PWD/rust/target/debug/examples/chat_party \
  --dart-define=E2E_BLOSSOM=http://127.0.0.1:7001 \
  --dart-define=E2E_FILES=<directory>
```

`new_dispute.sh` adds such a dispute (an order cloned with fresh trade keys,
its 38386 published with the node key) to a copy of a mostrod home, and with
`SOLVER_PK` registers that key as a read-write solver; it refuses
`~/.mostro`. Its output is the `E2E_DISPUTE` / `E2E_BUYER` / `E2E_SELLER`
values:

```bash
eval "$(SOLVER_PK=<solver pubkey hex> integration_test/new_dispute.sh <home copy>)"
```

The helpers the runs share are in `e2e_support.dart`.

## Resolution (phase 6), with real regtest sats

`resolve_against_local_mostrod_test.dart` drives the phase 6 screens, and
`resolve_against_a_local_mostrod` (an `#[ignore]` test in
`rust/src/mostro/resolve.rs`) sends one `AdminSettle` / `AdminCancel` from the
Rust core for the answers the app reaches only in a race. **The disputes must
be real trades**: `new_dispute.sh` clones orders with no hold invoice, and
settle or cancel would fail in LND. Never against a real node or public relays.

The setup (no keys are written here; generate your own):

- **Lightning:** Polar's regtest network: mostrod on `alice` (its
  `settings.toml` points at `~/.polar/networks/1/volumes/lnd/alice`), the
  seller's wallet `bob`, the buyer's `carol`. `lncli` runs inside the
  containers: `docker exec -u lnd polar-n1-<node> lncli --network=regtest
  --lnddir=/home/lnd/.lnd …`. With an old chain tip LND reads "not synced",
  and mostrod 0.20.1 goes into **automatic maintenance**
  (`daemon_state.maintenance_mode`, reason `lnd_unsynced`), which answers
  `NewOrder` and the takes with `CantDo(MaintenanceMode)` until LND has been
  synced for a while. Mine a block first (`bitcoin-cli … generatetoaddress 1
  <addr>` in `polar-n1-backend1`), and clear the row in the copy if it is set.
- **mostrod** from a copy of a home whose `[nostr] relays` lists only a local
  relay (`nak serve --port <port>`), with a **node key of its own** (a fresh
  `nsec_privkey`) when another test mostrod runs from a copy of the same
  home: two daemons with one key on one relay would both answer. Solvers are
  rows in its `users` table: `is_solver = 1`, `category` 1 (Read) or 2
  (Read-Write).
- **The parties:** MostroP2P/mostro-cli, **built from its current main**
  (0.16.3; an older build cannot read mostrod 0.20's answers: "Error
  serializing message"), one `MCLI_DIR` per party so each has its own keys, with
  `MOSTRO_PUBKEY`, `RELAYS` (the local relay only) and `TRANSPORT=nip44`.
  Each dispute: the seller's `neworder -k sell … -a <sats>`; the buyer's
  `takesell -o <order> -i <invoice>` with carol's invoice for `sats - fee`
  (mostrod's fee is `fee * sats / 2`, here 0.5 %); the seller's hold
  invoice from `getdm`, for `sats + fee`, paid by `bob` (`payinvoice -f`
  blocks until it is settled or canceled: run it in the background); the
  buyer's `fiatsent` and `dispute`. The dispute id is the 38386's `d`; its
  order id is in the node's `disputes` table (ids are 16-byte blobs).

The app run has two steps, each its own `flutter test` (the core starts once
per process):

```bash
# A Read solver takes dispute 2 and asks to pay its buyer: refused, said so.
flutter test integration_test/resolve_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:<port> \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_SOLVER=<Read solver secret> \
  --dart-define=E2E_STEP=read-only \
  --dart-define=E2E_DISPUTE_2=<dispute 2>

# A Read-Write solver pays dispute 1's buyer, takes dispute 3, takes dispute 2
# over from the Read solver (Recover a dispute) and refunds its seller.
flutter test integration_test/resolve_against_local_mostrod_test.dart -d linux \
  --dart-define=E2E_RELAY=ws://localhost:<port> \
  --dart-define=E2E_NODE=<node hex> \
  --dart-define=E2E_SOLVER=<Read-Write solver secret> \
  --dart-define=E2E_STEP=resolve \
  --dart-define=E2E_DISPUTE=<dispute 1> \
  --dart-define=E2E_DISPUTE_2=<dispute 2> \
  --dart-define=E2E_DISPUTE_3=<dispute 3>
```

Check the sats outside, before and after: `alice lookupinvoice <order hash>`
(the seller's hold invoice: `SETTLED` after paying the buyer, `CANCELED` after
a refund), `carol listinvoices` (the buyer's invoice `SETTLED` for
`sats - fee`), bob's `payinvoice` output (`SUCCEEDED`, or `FAILED` with
`INCORRECT_PAYMENT_DETAILS` and "0 + 0 sat" after a refund) and the channel
balances.

Then the Rust test, once per answer (the feed does not follow the node, so
the request leaves even for a dispute the node has closed):

```bash
cd rust && BOSSTRO_E2E_RELAY=ws://localhost:<port> BOSSTRO_E2E_NODE=<node hex> \
  BOSSTRO_E2E_SOLVER=<secret> BOSSTRO_E2E_DISPUTE=<dispute> BOSSTRO_E2E_ORDER=<its order> \
  BOSSTRO_E2E_RESOLUTION=pay|refund BOSSTRO_E2E_EXPECT=<outcome> \
  cargo test --lib resolve_against_a_local_mostrod -- --ignored --nocapture
```

- dispute 1 again, `pay`, Read-Write key → `not-in-dispute`
  (`invalid_order_status`): a retry after a settle that happened pays nothing;
- dispute 2, the Read key → `taken-over` (`IsNotYourDispute`), its take dropped;
- dispute 3 after `cancel -o <order>` from both parties (mostro-cli) →
  `cooperatively-canceled`; the seller's hold invoice is `CANCELED` by the
  parties' cancel, and the node's 38386 reads `cooperatively-canceled`.

## Bond slash, with real regtest sats

Same setup as the resolution run, on a mostrod whose copied `settings.toml` has
`[anti_abuse_bond] enabled = true` (here `apply_to = "take"`: the taker posts the
bond) and a node key of its own. Its kind 38385 then says `bond_enabled = "true"`,
which is what makes Bosstro offer the choice.

- The buyer's `takesell` answers with the taker's **bond invoice**
  (`PayBondInvoice`): pay it from `carol` in the background (`payinvoice -f`); the
  bond row turns `locked`. Then the seller's hold invoice arrives as usual.
- Take the dispute with the solver key (`mostro-cli admtakedispute -d <dispute>` with
  `ADMIN_NSEC`), then resolve through the Rust core with
  `BOSSTRO_E2E_BOND=no-slash|buyer|seller|both` (`resolve_against_a_local_mostrod`).
- Slashing a party with no bond answers `bond-not-posted` and moves nothing. A valid
  slash settles that party's bond HTLC (`pending-payout`, `lost-dispute`) and the other
  party gets `AddBondInvoice` for its share (`getdm`).
