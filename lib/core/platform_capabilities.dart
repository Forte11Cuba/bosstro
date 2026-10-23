import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// What the device can do for the key screens. Android is the target the
/// app is built for (A2); Linux and web run it for development and as a
/// convenience, without the Android-only protections.
///
/// Each check takes `isWeb` and `platform` rather than reading them, because
/// `kIsWeb` is a compile-time constant: a test could otherwise never reach
/// the web branch. Callers use the getters below.
abstract final class PlatformCapabilities {
  /// Scanning a QR code with the camera. `mobile_scanner` has no Linux
  /// implementation, and on web the key is pasted, as in ../app
  /// (`qrInputFor`).
  static bool scanQrOn(bool isWeb, TargetPlatform platform) =>
      !isWeb && platform == TargetPlatform.android;

  /// Copying a secret key. Only Android copies it protected: marked
  /// sensitive and cleared after a minute (`MainActivity.kt`). Elsewhere the
  /// clipboard would keep the key, and desktop clipboard managers record
  /// their history, so the key is written down instead.
  static bool copySecretOn(bool isWeb, TargetPlatform platform) =>
      !isWeb && platform == TargetPlatform.android;

  static bool get scanQr => scanQrOn(kIsWeb, defaultTargetPlatform);

  static bool get copySecret => copySecretOn(kIsWeb, defaultTargetPlatform);
}
