#!/usr/bin/env bash
# Run the IndexedDB storage tests (rust/src/db/indexeddb.rs) in headless Chrome.
#
# They are the same checks as the SQLite backend's (rust/src/db/contract.rs), but
# IndexedDB exists only in a browser, so `cargo test` cannot reach them.
#
# Built without scripts/build-web.sh's wasm-threads flags: with them the test
# harness fails to link (a dependency's cdylib meets a std built without atomics),
# and IndexedDB does not need threads. Nightly, as the web build.
#
# wasm-pack downloads the newest ChromeDriver, which refuses an older Chrome. When
# that happens, point CHROMEDRIVER at the driver matching `google-chrome --version`
# (Chrome for Testing, https://googlechromelabs.github.io/chrome-for-testing/).
#
# Usage:
#   ./scripts/test-web-storage.sh
#   CHROMEDRIVER=/path/to/chromedriver ./scripts/test-web-storage.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for tool in wasm-pack rustup google-chrome; do
  command -v "$tool" >/dev/null || { echo "✗ $tool is not installed." >&2; exit 1; }
done

driver_args=()
if [[ -n "${CHROMEDRIVER-}" ]]; then
  driver_args=(--chromedriver "$CHROMEDRIVER")
fi

RUSTUP_TOOLCHAIN=nightly wasm-pack test --headless --chrome "${driver_args[@]}" \
  rust --lib -- db::indexeddb
