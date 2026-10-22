import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The Android side of keeping the secret key off the screen and out of the
/// clipboard (`MainActivity.kt`). Where the channel is missing (widget
/// tests), every call is a no-op.
class DeviceSecurity {
  const DeviceSecurity([this._channel = channel]);

  static const channel = MethodChannel(
    'foundation.mostro.bosstro/device_security',
  );

  final MethodChannel _channel;

  /// FLAG_SECURE on or off: no screenshots, screen recording or recent-apps
  /// thumbnail while it is on.
  Future<void> setSecure(bool secure) =>
      _call<void>('setSecure', secure).then((_) {});

  /// Copies [text] marked as sensitive (EXTRA_IS_SENSITIVE): hidden in
  /// Android 13+'s copy preview and kept out of keyboards' clipboard history.
  Future<void> copySensitive(String text) =>
      _call<void>('copySensitive', text).then((_) {});

  /// Clears the clipboard if it still holds what [copySensitive] put there.
  /// Returns false when that could not be checked yet (the app is in the
  /// background), so the caller retries.
  Future<bool> clearSensitive() async =>
      await _call<bool>('clearSensitive') ?? true;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }
}

/// Copies a secret key and clears it from the clipboard after [clearAfter],
/// unless something else was copied over it. When the time runs out with the
/// app in the background, where the clipboard cannot be read, it is cleared
/// as soon as the app is back.
class SensitiveClipboard with WidgetsBindingObserver {
  SensitiveClipboard(this._device, {this.clearAfter = defaultClearAfter});

  static const defaultClearAfter = Duration(seconds: 60);

  final DeviceSecurity _device;
  final Duration clearAfter;

  Timer? _timer;
  bool _pending = false;
  bool _observing = false;

  /// Whether a copied secret still waits to be cleared.
  bool get pending => _pending;

  Future<void> copy(String text) async {
    await _device.copySensitive(text);
    _pending = true;
    _timer?.cancel();
    _timer = Timer(clearAfter, _clear);
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  Future<void> _clear() async {
    if (!_pending) return;
    if (await _device.clearSensitive()) {
      _pending = false;
      _stopObserving();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only once the time is up: before that the timer is still running.
    if (state == AppLifecycleState.resumed &&
        _pending &&
        !(_timer?.isActive ?? false)) {
      _clear();
    }
  }

  void _stopObserving() {
    if (!_observing) return;
    WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }

  void dispose() {
    _timer?.cancel();
    _stopObserving();
  }
}
