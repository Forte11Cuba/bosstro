import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/services/device_security.dart';

import '../../support/fake_device_security.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDeviceSecurity device;
  late SensitiveClipboard clipboard;

  setUp(() {
    device = FakeDeviceSecurity();
    clipboard = SensitiveClipboard(device);
  });
  tearDown(() => clipboard.dispose());

  test('copies marked sensitive and clears after a minute', () {
    fakeAsync((async) {
      clipboard.copy('nsec1secret');
      async.flushMicrotasks();
      expect(device.calls, ['copy:nsec1secret']);

      async.elapse(const Duration(seconds: 59));
      expect(device.calls, isNot(contains('clear')));

      async.elapse(const Duration(seconds: 1));
      expect(device.calls, ['copy:nsec1secret', 'clear']);
      expect(clipboard.pending, isFalse);
    });
  });

  test('a second copy restarts the minute', () {
    fakeAsync((async) {
      clipboard.copy('nsec1a');
      async.elapse(const Duration(seconds: 40));
      clipboard.copy('nsec1b');
      async.elapse(const Duration(seconds: 40));
      expect(device.calls, isNot(contains('clear')));
      async.elapse(const Duration(seconds: 20));
      expect(device.calls.where((c) => c == 'clear'), hasLength(1));
    });
  });

  test('in the background it waits, and clears once the app is back', () {
    fakeAsync((async) {
      device.canClear = false;
      clipboard.copy('nsec1secret');
      async.elapse(SensitiveClipboard.defaultClearAfter);
      expect(clipboard.pending, isTrue);

      device.canClear = true;
      clipboard.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(device.calls.where((c) => c == 'clear'), hasLength(2));
      expect(clipboard.pending, isFalse);
    });
  });

  test('coming back before the minute is up does not clear early', () {
    fakeAsync((async) {
      clipboard.copy('nsec1secret');
      async.elapse(const Duration(seconds: 10));
      clipboard.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(device.calls, isNot(contains('clear')));
    });
  });

  test('without the native side every call is a no-op', () async {
    const device = DeviceSecurity();
    await device.setSecure(true);
    await device.copySensitive('x');
    expect(await device.clearSensitive(), isTrue);
  });
}
