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
