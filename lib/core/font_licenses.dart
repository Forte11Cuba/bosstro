import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the licence of each bundled font family with the
/// [LicenseRegistry], next to the package licences Flutter already collects.
///
/// The OFL (Outfit, Manrope, and the flags of Noto Color Emoji) lets them
/// ship inside the app only with their copyright notice and licence, and
/// `pubspec.yaml` bundles those texts as assets for exactly this.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, asset) in const [
      ('Outfit', 'assets/fonts/outfit/OFL.txt'),
      ('Manrope', 'assets/fonts/manrope/OFL.txt'),
      ('Noto Color Emoji', 'assets/fonts/noto_flags/LICENSE.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(asset));
    }
  });
}
