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

> **Status:** the MVP is complete, verified on a device and released: v0.1.0 was the first
> release. Serbero and notifications come next.

## What it does

- **Your solver key.** Log in with the nsec the node operator added as a solver, or create a
  new one and hand its npub to the operator. The key lives in the Android Keystore-backed
  secure storage and in the Rust core, never anywhere else; the node's own key never enters
  the app.
- **One node at a time.** Pick Mostro, a trusted community, or your own node, and the relays
  it uses.
- **Pending disputes** of the node, live, and **take** one. Bosstro learns from the node's
  answers whether your key is a solver there, and whether it is Read or Read-Write.
- **Your disputes:** in progress and closed. A take that got no answer is recovered by taking
  it again.
- **Chat** with the buyer and the seller of each dispute you hold, end-to-end encrypted, with
  images and PDFs. When a party shares their chat key, read the conversation between the
  buyer and the seller too.
- **Resolve:** pay the buyer or refund the seller (Read-Write solvers).
- In English, Spanish, Italian, French, German, Dutch and Brazilian Portuguese.

## Install

Android 7.0 or later. Download the APK from the
[Releases page](https://github.com/MostroP2P/bosstro/releases): `arm64-v8a` for almost any
phone, `armeabi-v7a` for an old or entry-level one on a 32-bit Android. Check it against the
release's `SHA256SUMS.txt` before installing: the app holds a key that can settle disputes.

`SHA256SUMS.txt` comes with the APK, so it only proves the download is whole; the signing
certificate proves who built it. Every Bosstro release is signed with the same key, and
Android refuses an update signed with any other. Its package name and certificate SHA-256, in
the form [AppVerifier](https://github.com/soupslurpr/AppVerifier) takes:

```text
foundation.mostro.bosstro
63:92:27:84:C2:E3:2A:F4:B6:03:0F:5E:2A:18:1F:74:9B:F6:95:E5:2F:1C:A8:45:7E:98:CB:05:D2:9E:B3:4B
```

Or with `apksigner` from the Android SDK build-tools, which prints it without the colons:

```bash
apksigner verify --print-certs bosstro-v0.1.0-arm64-v8a.apk
# Signer #1 certificate DN: CN=Bosstro, O=MostroP2P
# Signer #1 certificate SHA-256 digest: 63922784c2e32af4b6030f5e2a181f749bf695e52f1ca8457e98cb05d29eb34b
```

Use a key of its own: never the nsec of a trading app (Mostro, Mostrix's trader key), or the
two roles are linked publicly.

## Security

The key handling is described under "Key handling" in [AGENTS.md](AGENTS.md). Report a
vulnerability privately, as [SECURITY.md](SECURITY.md) explains — never in a public issue.

## Building

Requirements: Flutter 3.47.7, Rust (rustup picks the version in `rust-toolchain.toml`), the Android
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
