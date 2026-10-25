import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:bosstro/core/startup_failure.dart';

/// Runs [body] and, if it throws, paints the failure surface naming the step
/// (../app's `startup_sequence.dart`, without its web smoke-test probe:
/// Bosstro has no web smoke test).
///
/// Without it an exception in startup means runApp never runs and Flutter
/// paints nothing — the page is not broken, it is absent, with no message
/// anywhere.
///
/// Apart from the app so it can be run without Rust: [run] defaults to the
/// real one and a test swaps it.
Future<void> runGuarded(
  Future<void> Function(StartupSequence startup) body, {
  @visibleForTesting void Function(Widget app) run = runApp,
}) async {
  final startup = StartupSequence();
  try {
    await body(startup);
  } catch (e, st) {
    debugPrint('[startup] fatal while ${startup.currentStep}: $e\n$st');
    // The screen first: it is what a person is waiting for. Anything ahead of
    // it that could throw would leave them with the blank page this replaces.
    run(StartupFailureApp(step: startup.currentStep, error: e));
  }
}

/// The startup steps, and which one is running.
///
/// Exists so a failure before `runApp` can say *where* it happened: the guard
/// that catches it is at the end of the sequence and has no other way to know.
///
/// Both helpers set [currentStep] on entry, so every stretch of startup runs
/// under its own name. That is the point of having two of them rather than one:
/// with only [optional], the mandatory stretches in between would keep running
/// under the label of whichever optional step finished last, and a failure
/// there would name a step that succeeded.
class StartupSequence {
  /// The step in progress. Read by the failure surface.
  String currentStep = 'starting up';

  /// A step the app can open without: a failure is recorded and startup
  /// continues, degraded.
  ///
  /// Every degradation prints the same `[startup]` prefix, so grepping it lists
  /// what a run gave up on, in order — which matters when one failure causes
  /// the next.
  Future<void> optional(String name, Future<void> Function() body) async {
    currentStep = name;
    try {
      await body();
    } catch (e, st) {
      debugPrint('[startup] $name failed — continuing without it: $e\n$st');
      // An Error is a bug, not a missing environment, so in debug it is
      // reported as an error — loud in the console and the IDE — instead of
      // one more log line. Reported, not thrown: a step that already fails
      // this way on some platform must not stop startup there.
      if (kDebugMode && e is Error) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'startup',
            context: ErrorDescription(
              'optional step "$name" hit a programming error',
            ),
          ),
        );
      }
    }
  }

  /// A step the app cannot open without: the failure propagates to the guard,
  /// which shows the failure surface naming [name].
  Future<T> required<T>(String name, Future<T> Function() body) {
    currentStep = name;
    return body();
  }
}
