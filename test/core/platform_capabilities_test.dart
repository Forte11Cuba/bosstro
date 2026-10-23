import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities', () {
    test('Android scans QR codes and copies secrets protected', () {
      expect(
        PlatformCapabilities.scanQrOn(false, TargetPlatform.android),
        isTrue,
      );
      expect(
        PlatformCapabilities.copySecretOn(false, TargetPlatform.android),
        isTrue,
      );
    });

    test('Linux has neither: no scanner plugin, no protected clipboard', () {
      expect(
        PlatformCapabilities.scanQrOn(false, TargetPlatform.linux),
        isFalse,
      );
      expect(
        PlatformCapabilities.copySecretOn(false, TargetPlatform.linux),
        isFalse,
      );
    });

    // On web `platform` is the browser's OS: a phone browser reports android.
    test('web has neither, whatever OS the browser runs on', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
        expect(PlatformCapabilities.scanQrOn(true, platform), isFalse);
        expect(PlatformCapabilities.copySecretOn(true, platform), isFalse);
      }
    });
  });
}
