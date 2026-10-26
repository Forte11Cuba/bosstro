# Changelog

All notable changes to Bosstro are documented here, newest first. This file is
written by the release workflow (docs/RELEASING.md) — do not edit it by hand.
Versions follow [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-26

### ✨ Features

- About, and a startup failure screen instead of a blank one ([#27](https://github.com/MostroP2P/bosstro/pull/27)) by @grunch
- **release:** publish signed Android APKs from a pushed tag ([#26](https://github.com/MostroP2P/bosstro/pull/26)) by @grunch
- **disputes:** My disputes in two parts, In progress and Closed ([#23](https://github.com/MostroP2P/bosstro/pull/23)) by @Forte11Cuba
- choose the app's language, in seven languages ([#21](https://github.com/MostroP2P/bosstro/pull/21)) by @Catrya
- **disputes:** open the dispute's detail once it is taken ([#19](https://github.com/MostroP2P/bosstro/pull/19)) by @Catrya
- **disputes:** show the order's status before the dispute ([#16](https://github.com/MostroP2P/bosstro/pull/16)) by @Forte11Cuba
- bond slash in the resolution (pay or refund, and whose bond is slashed) ([#14](https://github.com/MostroP2P/bosstro/pull/14)) by @Forte11Cuba
- phase 6 — resolution (pay the buyer, refund the seller) ([#11](https://github.com/MostroP2P/bosstro/pull/11)) by @Forte11Cuba
- phase 5c — observer (the chat between the parties) ([#10](https://github.com/MostroP2P/bosstro/pull/10)) by @Forte11Cuba
- phase 5 (part 2) — chat attachments ([#9](https://github.com/MostroP2P/bosstro/pull/9)) by @Forte11Cuba
- phase 4 — take dispute ([#7](https://github.com/MostroP2P/bosstro/pull/7)) by @Forte11Cuba
- phase 3 — pending disputes ([#6](https://github.com/MostroP2P/bosstro/pull/6)) by @Forte11Cuba
- phase 2 — nodes and relays ([#5](https://github.com/MostroP2P/bosstro/pull/5)) by @Forte11Cuba
- run on Linux and the web ([#3](https://github.com/MostroP2P/bosstro/pull/3)) by @Forte11Cuba
- phase 1 solver key ([#2](https://github.com/MostroP2P/bosstro/pull/2)) by @Forte11Cuba
- phase 0 scaffold ([#1](https://github.com/MostroP2P/bosstro/pull/1)) by @Forte11Cuba

### 🐛 Bug Fixes

- require Flutter 3.47 in pubspec ([#24](https://github.com/MostroP2P/bosstro/pull/24)) by @grunch
- **disputes:** Info order, folded facts, currency; Pending never stuck loading ([#22](https://github.com/MostroP2P/bosstro/pull/22)) by @Forte11Cuba
- **resolution:** say when the node's bonds are not known, and nothing when it has none ([#20](https://github.com/MostroP2P/bosstro/pull/20)) by @Catrya
- keep content clear of the system navigation bar ([#18](https://github.com/MostroP2P/bosstro/pull/18)) by @Catrya
- **disputes:** open a dispute on its own screen at any width ([#17](https://github.com/MostroP2P/bosstro/pull/17)) by @Forte11Cuba
- **linux:** the app's emblem as the window icon ([#13](https://github.com/MostroP2P/bosstro/pull/13)) by @Forte11Cuba
- resolve buttons in the parties' colours, copy chat messages ([#12](https://github.com/MostroP2P/bosstro/pull/12)) by @Forte11Cuba

### 📚 Documentation

- refer to MostroP2P/app on GitHub, not ../app ([#29](https://github.com/MostroP2P/bosstro/pull/29)) by @grunch
- README for the first release, and a security policy ([#28](https://github.com/MostroP2P/bosstro/pull/28)) by @grunch

### 🧪 Tests

- guard the Android backup opt-out ([#25](https://github.com/MostroP2P/bosstro/pull/25)) by @grunch
- **disputes:** wait for the feed's updates instead of draining them ([#15](https://github.com/MostroP2P/bosstro/pull/15)) by @Forte11Cuba

### 👷 Build & CI

- upgrade to Flutter 3.47.7, AGP 9.1, Kotlin 2.4, Gradle 9.3 ([#4](https://github.com/MostroP2P/bosstro/pull/4)) by @Forte11Cuba

### 🧹 Chores

- point every link to MostroP2P/bosstro ([#33](https://github.com/MostroP2P/bosstro/pull/33)) by @grunch
- initialize repository ([`5e02bca`](https://github.com/MostroP2P/bosstro/commit/5e02bca))

### 🔧 Other Changes

- Phase 5 (part 1): dispute detail and chat ([#8](https://github.com/MostroP2P/bosstro/pull/8)) by @Forte11Cuba
