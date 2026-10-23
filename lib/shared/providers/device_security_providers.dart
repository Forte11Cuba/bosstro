import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/services/device_security.dart';

/// The Android side of FLAG_SECURE and the sensitive clipboard. Tests
/// override it to record the calls.
final deviceSecurityProvider = Provider<DeviceSecurity>(
  (ref) => const DeviceSecurity(),
);

/// The one clipboard a secret key is copied through.
final sensitiveClipboardProvider = Provider<SensitiveClipboard>((ref) {
  final clipboard = SensitiveClipboard(ref.watch(deviceSecurityProvider));
  ref.onDispose(clipboard.dispose);
  return clipboard;
});
