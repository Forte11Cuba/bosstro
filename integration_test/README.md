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
`--send-file` / `--expect-file`) writes and reads ../app's format with code
of its own. Blobs go to a local Blossom server (`blossom_server`), never a
public one: the app reaches it only in a debug build, through
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

The helpers both chat runs share are in `e2e_support.dart`.
