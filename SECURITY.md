# Security Policy

Bosstro holds a **Mostro dispute solver's key**. On the nodes where that key is a solver it
can take disputes, read the parties' messages, and — with Read-Write permission — settle a
dispute (pay the buyer) or cancel it (refund the seller). A flaw that leaks the key, or lets
someone act with it, can send a trade's sats to the wrong party. Reports are taken seriously
and handled through coordinated disclosure.

## Reporting a Vulnerability

**Do not open a public issue, pull request, or discussion for a security vulnerability.**

Report it privately by email to <security@mostro.network>.

If you would like to encrypt your report, ask for a public key at that address before sending
details.

### What to Include

The more of this you can provide, the faster the issue can be triaged:

- A description of the vulnerability and its impact (what an attacker can achieve).
- Steps to reproduce, or a proof of concept.
- Platform (Android, or the Linux and web development builds) and the version and commit,
  both shown in Settings → About.
- Affected layer, if known: Flutter UI (`lib/`) or Rust core (`rust/`).
- Any relevant logs, with keys (`nsec…`, hex secrets), chat keys and invoices redacted.

Please do not test against disputes, nodes or relays you do not operate, and never take a
dispute that is not yours to probe a node. Run your own `mostrod` and relay; the integration
tests (`integration_test/README.md`) show how.

## Response Process

- **Acknowledgement:** within 72 hours of the report.
- **Initial assessment:** severity and affected versions confirmed, normally within 7 days.
- **Fix:** critical issues are targeted for a fix within 30 days. Lower-severity issues are
  scheduled into the normal release cycle.
- **Updates:** you will be kept informed of progress until the issue is resolved.
- **Disclosure:** details are published only after a fix is available. Reporters are credited
  when the fix is announced, unless they ask to remain anonymous.

## Supported Versions

Security fixes are applied to the latest released version and to the `main` branch. Older
releases do not receive backports.

## Scope

**In scope** — this repository:

- The Rust core (`rust/`): the solver key, the Nostr protocol and transport, the dispute
  feed, the admin actions (take, settle, cancel), the dispute chat and its attachments, the
  observed chat, and local storage.
- The Flutter shell (`lib/`): UI, navigation, secure storage of the key, the protected
  clipboard and screenshot blocking on Android, and device integration.
- Build and release tooling (`scripts/`, `tool/`, `.github/workflows/`), including how a
  release is signed.

**Out of scope** — report these to their own projects:

- The Mostro daemon and its dispute logic: [MostroP2P/mostro](https://github.com/MostroP2P/mostro).
- Protocol types shared with other clients: [mostro-core](https://github.com/MostroP2P/mostro-core).
- The trader app ([MostroP2P/app](https://github.com/MostroP2P/app)) and the TUI client
  ([MostroP2P/mostrix](https://github.com/MostroP2P/mostrix)).
- Third-party Nostr relays, Blossom servers, and Mostro nodes operated by others.
- Upstream dependencies (`nostr-sdk`, Flutter, Rust crates) — report those upstream, though a
  heads-up is welcome if Bosstro is exploitable through them.

The following are generally **not** treated as vulnerabilities:

- The limits AGENTS.md documents and accepts: the key in process memory while the app runs
  (the Android Keystore cannot sign with secp256k1), chat messages stored in plain text until
  SQLCipher, and the others under "Accepted limits" and "Key handling".
- The Linux and web builds lacking the Android-only protections (no screenshot blocking, no
  protected clipboard, the key in browser storage on the web): they are development targets
  and are not released.
- Automated scanner output with no demonstrated impact.
- Attacks that require a compromised or rooted device, or physical access to an unlocked one.
- Social engineering, phishing, or a solver voluntarily disclosing their secret key.
- Denial of service against public relays or a third party's infrastructure.

## Security Model

How the key is stored, crosses into Rust, and is shown or copied is under "Key handling" in
[AGENTS.md](AGENTS.md); what the app reads from and sends to a node is under "Protocol". In
short: the only key is the solver's, kept in the Android Keystore-backed secure storage and in
Rust's memory, never logged and never written elsewhere; the node's own key never enters the
app; chat keys are derived in memory and never stored.

## Solver Advisory

Your secret key (`nsec`) is your solver identity on every node that added it. Nobody from the
Mostro project will ever ask for it. Keep a backup offline (Settings → Back up secret key),
never reuse the key of a trading app as your solver key, and install Bosstro only from this
repository's Releases page, checking the file against `SHA256SUMS.txt`.
