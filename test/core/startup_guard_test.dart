import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/startup_failure.dart';
import 'package:bosstro/core/startup_sequence.dart';

void main() {
  group('startup guard', () {
    test('a failure reaches runApp, naming the step that failed', () async {
      // Arrange — without the guard the sequence throws, runApp never runs,
      // and Flutter paints nothing: not a broken screen, an absent one.
      Widget? painted;
      final boom = StateError('boom');

      // Act
      await runGuarded((startup) async {
        await startup.optional('opening the local database', () async {});
        await startup.required('loading the engine', () async => throw boom);
      }, run: (app) => painted = app);

      // Assert
      expect(
        painted,
        isA<StartupFailureApp>()
            .having((a) => a.step, 'step', 'loading the engine')
            .having((a) => a.error, 'error', same(boom)),
      );
    });

    test('a startup that succeeds paints nothing from the guard', () async {
      // Arrange
      var ran = false;

      // Act
      await runGuarded(
        (startup) => startup.required('loading the engine', () async {}),
        run: (_) => ran = true,
      );

      // Assert
      expect(ran, isFalse, reason: 'the failure surface is for failures only');
    });

    test('main runs the whole startup through the guard', () {
      // Arrange — running main needs the Rust library, so this reads it: the
      // guard is only worth anything if every step runs inside it.
      final source = File('lib/main.dart').readAsStringSync();

      // Assert
      expect(source, contains('Future<void> main() => runGuarded(_startup);'));
      expect(
        source,
        contains(
          "startup.required('loading the engine', () => RustLib.init())",
        ),
      );
      expect(
        RegExp(
          r'^\s*await RustLib\.init\(\)',
          multiLine: true,
        ).hasMatch(source),
        isFalse,
        reason: 'the engine is loaded inside its step, not before the guard',
      );
    });
  });
}
