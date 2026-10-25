/// The "Downloads" section of a GitHub release (docs/RELEASING.md).
///
/// File names here are the contract with the workflows that upload them;
/// test/ci/release_workflow_test.dart holds the two sides equal.
///
/// MostroP2P/app's, Android only: Bosstro releases no desktop or iOS build
/// (AGENTS.md, A2).
library;

/// Every asset a release can carry, by platform key, in display order.
Map<String, String> releaseAssetNames(String tag) => {
  'android-v8': 'bosstro-$tag-arm64-v8a.apk',
  'android-v7': 'bosstro-$tag-armeabi-v7a.apk',
  'android-aab': 'bosstro-$tag.aab',
};

const _platformLabels = {
  'android-v8': 'Android (v8)',
  'android-v7': 'Android (v7)',
  'android-aab': 'Android (app bundle)',
};

/// Renders the section. [assets] is the set of files that were actually
/// built: a platform without its file is named as missing instead of linked
/// to a 404. Null means "all of them".
String renderDownloads({
  required String tag,
  required String repositoryUrl,
  Set<String>? assets,
}) {
  final names = releaseAssetNames(tag);
  bool has(String platform) =>
      assets == null || assets.contains(names[platform]);
  String link(String platform) {
    final file = names[platform]!;
    return '[`$file`]($repositoryUrl/releases/download/$tag/$file)';
  }

  final out = StringBuffer('## 📥 Downloads\n\n');

  if (has('android-v8') || has('android-v7')) {
    out.writeln('### 🤖 Android\n');
    out.writeln('| File | Architecture | For |\n| --- | --- | --- |');
    if (has('android-v8')) {
      out.writeln(
        '| ${link('android-v8')} | **v8** — ARMv8-A, 64-bit (AArch64) '
        '| **Modern phones.** Pick this one if unsure. |',
      );
    }
    if (has('android-v7')) {
      out.writeln(
        '| ${link('android-v7')} | **v7** — ARMv7-A, 32-bit '
        '| **Old or entry-level phones** that run a 32-bit Android. |',
      );
    }
    out.writeln(_androidNotes);
  }
  if (has('android-aab')) {
    out.writeln(
      '${link('android-aab')} is the **Android App Bundle** for the Google '
      'Play Console — the store builds the per-device APKs from it. It is '
      'not installable on a phone.\n',
    );
  }

  final missing = [
    for (final platform in names.keys)
      if (!has(platform)) _platformLabels[platform]!,
  ];
  if (missing.isNotEmpty) {
    out.writeln(
      '> ⚠️ The ${_joinNames(missing)} '
      '${missing.length == 1 ? 'build' : 'builds'} failed for this release '
      'and ${missing.length == 1 ? 'is' : 'are'} not attached.\n',
    );
  }

  out.writeln(
    'Verify a download with `sha256sum -c SHA256SUMS.txt --ignore-missing`.',
  );
  return out.toString();
}

String _joinNames(List<String> names) =>
    names.length == 1
        ? names.single
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

const _androidNotes = '''

Both need **Android 7.0 (API 24) or later** and are the same app: an APK holds
native machine code (the Flutter engine and Bosstro's Rust core, which does all
the cryptography), and one file per CPU instruction set keeps each download to
a fraction of the size of a universal APK. Every release is signed with the
same key, so it installs over the previous version and keeps your data.

<details>
<summary><b>Which APK is mine?</b></summary>

- **`arm64-v8a` (v8)** targets the 64-bit ARMv8-A instruction set. Practically
  every phone released since 2016–2017 runs a 64-bit Android, Google Play has
  required 64-bit builds since August 2019, and recent devices — the Pixel 7
  and later, and any phone built on 2023-or-newer Arm cores — are
  **64-bit only**: they cannot run the v7 APK at all. 64-bit code is also
  noticeably faster at the elliptic-curve and encryption work the app does.
- **`armeabi-v7a` (v7)** targets 32-bit ARMv7-A with hardware floating point.
  It is for phones with a 32-bit CPU (Cortex-A7/A9/A15 class, roughly 2015
  and earlier) **and** for phones whose 64-bit-capable CPU ships with a
  32-bit Android — common in budget and Android Go models with 2 GB of RAM
  or less.
- **To be sure:** try v8 first. If Android answers *"App not installed"* or
  *"package is not compatible with your phone"*, install v7. With a computer,
  `adb shell getprop ro.product.cpu.abilist` prints the supported ABIs —
  if `arm64-v8a` is in the list, use v8.
- x86 devices (emulators, some Chromebooks) are not covered by these builds.

</details>
''';
