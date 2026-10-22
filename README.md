<p align="center">
  <img src="icons/bosstro-256.png" width="128" alt="Bosstro">
</p>

# Bosstro

The mobile app for [Mostro](https://mostro.network) dispute solvers. See a node's disputes, take
one, chat with the buyer and the seller, and pay the buyer or refund the seller — from a phone.

Bosstro brings the admin side of [Mostrix](https://github.com/MostroP2P/mostrix) to Android, on
the architecture of [Mostro v2](https://github.com/MostroP2P/app): a Rust core (Nostr, keys,
protocol, persistence) with a Flutter UI, bridged by
[flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge).

> **Status:** phase 0 — scaffold. The three-tab shell runs and calls the Rust core; solver keys,
> nodes and disputes arrive in the next phases.

## Building

Requirements: Flutter 3.41, Rust (stable), the Android SDK and NDK, and the bridge codegen at the
pinned version:

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

## Development

See [AGENTS.md](AGENTS.md) for the architecture, the decisions behind it, the commands, and how
generated code is handled, and [.specify/DESIGN_SYSTEM.md](.specify/DESIGN_SYSTEM.md) for the
design guide every UI change is reviewed against.

## License

[AGPL-3.0-or-later](LICENSE). Parts of this code are copied from Mostro v2, which is AGPL.
