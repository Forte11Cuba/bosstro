import 'package:bosstro/core/services/device_security.dart';

/// Records what would reach `MainActivity`, and answers [clearSensitive]
/// with [canClear] (false: the app is in the background).
class FakeDeviceSecurity extends DeviceSecurity {
  FakeDeviceSecurity();

  final List<String> calls = [];
  bool canClear = true;

  @override
  Future<void> setSecure(bool secure) async => calls.add('secure:$secure');

  @override
  Future<void> copySensitive(String text) async => calls.add('copy:$text');

  @override
  Future<bool> clearSensitive() async {
    calls.add('clear');
    return canClear;
  }
}
