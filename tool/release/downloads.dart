/// The "Downloads" section of a GitHub release (docs/RELEASING.md).
///
/// File names here are the contract with the workflow that uploads them;
/// test/ci/release_workflow_test.dart holds the two sides equal.
///
/// Android only: it is the target Bosstro is built for (AGENTS.md, A2). Linux
/// and the web build and run for development, without the Android-only
/// protections of the solver key, so a release does not offer them.
library;

/// Every asset a release carries, by platform key, in display order.
Map<String, String> releaseAssetNames(String tag) => {
  'android-v8': 'bosstro-$tag-arm64-v8a.apk',
  'android-v7': 'bosstro-$tag-armeabi-v7a.apk',
  'android-aab': 'bosstro-$tag.aab',
};

/// Renders the section. The three files come from one job, and the release
/// is published only when it succeeded, so all of them are always there.
String renderDownloads({required String tag, required String repositoryUrl}) {
  final names = releaseAssetNames(tag);
  String link(String platform) {
    final file = names[platform]!;
    return '[`$file`]($repositoryUrl/releases/download/$tag/$file)';
  }

  return '''
## 📥 Downloads

### 🤖 Android

| File | Architecture | For |
| --- | --- | --- |
| ${link('android-v8')} | **v8** — ARMv8-A, 64-bit (AArch64) | **Modern phones.** Pick this one if unsure. |
| ${link('android-v7')} | **v7** — ARMv7-A, 32-bit | **Old or entry-level phones** that run a 32-bit Android. |
$_androidNotes
${link('android-aab')} is the **Android App Bundle** for the Google Play Console — the store builds the per-device APKs from it. It is not installable on a phone.

Verify a download with `sha256sum -c SHA256SUMS.txt --ignore-missing`.
''';
}

const _androidNotes = '''

Both need **Android 7.0 (API 24) or later** and are the same app: an APK holds
native machine code (the Flutter engine and Bosstro's Rust core, which does all
the cryptography), and one file per CPU instruction set keeps each download to
a fraction of the size of a universal APK. Every release is signed with the
same key, so it installs over the previous version and keeps your data.

Bosstro holds your **solver key**: install it only from this page, and check
the file against `SHA256SUMS.txt` before you do.

<details>
<summary><b>Which APK is mine?</b></summary>

- **`arm64-v8a` (v8)** targets the 64-bit ARMv8-A instruction set. Practically
  every phone released since 2016–2017 runs a 64-bit Android, and recent
  devices — the Pixel 7 and later, and any phone built on 2023-or-newer Arm
  cores — are **64-bit only**: they cannot run the v7 APK at all.
- **`armeabi-v7a` (v7)** targets 32-bit ARMv7-A with hardware floating point.
  It is for phones with a 32-bit CPU **and** for phones whose 64-bit-capable
  CPU ships with a 32-bit Android — common in budget and Android Go models.
- **To be sure:** try v8 first. If Android answers *"App not installed"* or
  *"package is not compatible with your phone"*, install v7. With a computer,
  `adb shell getprop ro.product.cpu.abilist` prints the supported ABIs —
  if `arm64-v8a` is in the list, use v8.
- x86 devices (emulators, some Chromebooks) are not covered by these builds.

</details>
''';
