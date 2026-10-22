import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/services/device_security.dart';
import 'package:bosstro/shared/providers/device_security_providers.dart';

/// Keeps the window secure (FLAG_SECURE) while [child] is on screen: no
/// screenshot, screen recording or recent-apps thumbnail of a screen that
/// shows the secret key. Nested or stacked secure screens are counted, so
/// leaving one does not lift the flag under another.
class SecureWindow extends ConsumerStatefulWidget {
  const SecureWindow({super.key, required this.child});

  final Widget child;

  /// Secure screens currently mounted.
  static int _active = 0;

  @override
  ConsumerState<SecureWindow> createState() => _SecureWindowState();
}

class _SecureWindowState extends ConsumerState<SecureWindow> {
  /// Kept from [initState]: `ref` is not read in [dispose].
  late final DeviceSecurity _device = ref.read(deviceSecurityProvider);

  @override
  void initState() {
    super.initState();
    if (SecureWindow._active++ == 0) _device.setSecure(true);
  }

  @override
  void dispose() {
    if (--SecureWindow._active == 0) _device.setSecure(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
