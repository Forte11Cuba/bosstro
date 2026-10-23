<p align="center">
  <img src="icons/bosstro-256.png" width="128" alt="Bosstro">
</p>

# Bosstro

The mobile app for [Mostro](https://mostro.network) dispute solvers. See a node's disputes, take
one, chat with the buyer and the seller, and pay the buyer or refund the seller — from a phone.

Bosstro brings the admin side of [Mostrix](https://github.com/MostroP2P/mostrix) to Android (and, for development, to Linux and the web), on
the architecture of [Mostro v2](https://github.com/MostroP2P/app): a Rust core (Nostr, keys,
protocol, persistence) with a Flutter UI, bridged by
[flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge).

> **Status:** phase 1 — solver key. Log in with an nsec or create a new one; the key lives in
> secure storage and in the Rust core. Nodes and disputes arrive in the next phases.

## Building

Requirements: Flutter 3.41, Rust (rustup picks the version in `rust-toolchain.toml`), the Android
SDK and NDK, and the bridge codegen at the pinned version:

```bash
cargo install flutter_rust_bridge_codegen --version 2.11.1 --locked
cargo install cargo-expand --locked
```

Then:

```bash
flutter pub get
flutter run -d android
```

The Rust core is built by cargokit as part of the Android build; there is no `cargo run`.

**`can't find crate for core` / "the `armv7-linux-androideabi` target may not be installed"**
while the targets are installed: the machine also has a system Rust (`/usr/bin/rustc`, from the
distribution's packages). Gradle puts `/usr/bin` first on the `PATH`, and since rustup 1.28
`rustup run` no longer moves `~/.cargo/bin` ahead of it, so cargo picks the system compiler, which
has no Android targets. Point cargo at rustup's proxy, or remove the system Rust:

```bash
RUSTC=~/.cargo/bin/rustc flutter run -d android
```

### Linux and web

Android is the target Bosstro is built for. It also runs on the Linux desktop and in a browser,
which is quicker for development, **without the Android-only protections of the secret key**: no
screenshot blocking, and the nsec cannot be copied (there is no protected clipboard to put it in).
On the web the key is kept in browser storage, which is much weaker than the Android Keystore. QR
scanning is Android-only; Linux and web paste the key.

**Linux** needs the GTK and keyring development packages:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev
flutter run -d linux
```

**Web** compiles the Rust core to WebAssembly with threads, which needs Rust nightly with
`rust-src`, the `wasm32-unknown-unknown` target and `wasm-pack`. Build the core first (again after
any Rust change), then run with the cross-origin isolation headers the wasm threads require:

```bash
rustup toolchain install nightly --component rust-src --target wasm32-unknown-unknown
cargo install wasm-pack --locked
./scripts/build-web.sh
flutter run -d chrome \
  --web-header=Cross-Origin-Opener-Policy=same-origin \
  --web-header=Cross-Origin-Embedder-Policy=require-corp
```

Do not use `flutter_rust_bridge_codegen build-web`: it emits a wasm without shared memory and the
page stays blank (`scripts/build-web.sh` explains why and checks for it). A built bundle served by a
static host gets the headers from `web/coi-serviceworker.min.js`.

## Development

See [AGENTS.md](AGENTS.md) for the architecture, the decisions behind it, the commands, and how
generated code is handled, and [.specify/DESIGN_SYSTEM.md](.specify/DESIGN_SYSTEM.md) for the
design guide every UI change is reviewed against.

## License

[AGPL-3.0-or-later](LICENSE). Parts of this code are copied from Mostro v2, which is AGPL.
