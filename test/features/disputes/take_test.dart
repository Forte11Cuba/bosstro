import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/disputes/screens/recover_screen.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/not_solver_banner.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/take_dialog.dart';
import 'package:bosstro/features/nodes/screens/choose_node_screen.dart';
import 'package:bosstro/shared/widgets/status_chip.dart';

import '../../support/screen_harness.dart';

/// Opened 2023-11-14 22:13:20 UTC, taken an hour later; the tests' clock is
/// two hours after the opening.
const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
const _b = '1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9';

Future<void> _pump(
  WidgetTester tester,
  FakeDisputesCore core, {
  String location = AppRoute.pending,
  Locale locale = const Locale('es'),
  Brightness brightness = Brightness.dark,
  double textScale = 2,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: location,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    overrides: fakeCoreOverrides(disputes: core),
  ),
);

/// Lets the providers' coalescing timer run, then the frame settle.
Future<void> _afterUpdates(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

FakeDisputesCore _withPending() =>
    FakeDisputesCore(disputes: [sampleDispute(id: _a)]);

void main() {
  // DS-A11Y-4: every new screen and dialog at 320 dp, 2× text, Spanish, in
  // both themes, with no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('the take confirmation fits, $theme', (tester) async {
      setSurface(tester);
      await _pump(tester, _withPending(), brightness: brightness);
      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('¿Tomar esta disputa?'), findsOneWidget);
      // DS-CMP-26: the answer repeats the opener's verb.
      expect(find.text('Tomar la disputa'), findsOneWidget);
    });

    testWidgets('the not-a-solver banner fits, $theme', (tester) async {
      setSurface(tester);
      final core = _withPending()..status = SolverStatus.no;
      await _pump(tester, core, brightness: brightness);
      expect(tester.takeException(), isNull);
      expect(find.byType(NotSolverBanner), findsOneWidget);
      expect(find.text('No eres solver en este nodo'), findsOneWidget);
      expect(find.text('Cambiar de nodo'), findsOneWidget);
    });

    testWidgets('In progress fits, $theme', (tester) async {
      setSurface(tester);
      final core =
          FakeDisputesCore()
            ..held = [
              sampleTaken(id: _a),
              sampleTaken(id: _b, fiatCode: null, amount: 1234567),
            ];
      await _pump(
        tester,
        core,
        location: AppRoute.inProgress,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(InProgressDisputeRow), findsWidgets);
      expect(find.text('Recuperar'), findsOneWidget);
    });

    testWidgets('Recover fits, $theme', (tester) async {
      setSurface(tester);
      final core =
          FakeDisputesCore()
            ..candidates = [
              sampleDispute(id: _a, status: DisputeStatus.inProgress),
            ];
      await _pump(
        tester,
        core,
        location: AppRoute.recover,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('El nodo no publica'), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(PendingDisputeRow), 200);
      await tester.ensureVisible(find.text('Abierta por el vendedor'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Abierta por el vendedor'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('¿Recuperar esta disputa?'), findsOneWidget);
    });
  }

  group('taking from Pending', () {
    testWidgets('a confirmed take waits for the node in the dialog, then '
        'moves the dispute to Your disputes', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core = _withPending()..takeAnswer = Completer();
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);

      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pump();

      // Waiting: the answer button is busy, the dialog cannot be left, and
      // nothing spins in the middle of the screen (DS-CMP-13).
      expect(core.takes, [_a]);
      expect(find.byType(TakeDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TakeDialog),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(TakeDialog), findsOneWidget);

      core.takeAnswer!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TakeDialog), findsNothing);
      expect(
        find.text('Dispute taken. It is in Your disputes.'),
        findsOneWidget,
      );
      await _afterUpdates(tester);
      expect(find.byType(PendingDisputeRow), findsNothing);

      await tester.tap(find.text('In progress'));
      await tester.pumpAndSettle();
      expect(find.byType(InProgressDisputeRow), findsOneWidget);
    });

    testWidgets('a double tap opens one dialog and sends one take', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      final core = _withPending();
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);

      await tester.tap(find.byType(PendingDisputeRow));
      await tester.tap(find.byType(PendingDisputeRow), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(TakeDialog), findsOneWidget);

      await tester.tap(find.text('Take dispute'));
      await tester.tap(find.text('Take dispute'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(core.takes, [_a]);
    });

    testWidgets('cancel sends nothing', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core = _withPending();
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);
      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(core.takes, isEmpty);
      expect(find.byType(TakeDialog), findsNothing);
    });

    testWidgets('the row is a button that says it takes the dispute', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      await _pump(
        tester,
        _withPending(),
        locale: const Locale('en'),
        textScale: 1,
      );
      final semantics = tester.getSemantics(
        find
            .ancestor(
              of: find.byType(PendingDisputeRow),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.hint, isNotNull);
      expect(
        find.bySemanticsLabel(RegExp('Opened by the seller')),
        findsWidgets,
      );
    });

    testWidgets('not a solver: the outcome says so, offers the node '
        'selector, and the banner stays on Pending', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core = _withPending()..takeOutcome = TakeOutcome.notSolver;
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);

      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pumpAndSettle();

      expect(find.byType(TakeDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TakeDialog),
          matching: find.text('You are not a solver on this node'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(NotSolverBanner), findsOneWidget);
      // The dispute is still there to take, on the right node.
      expect(find.byType(PendingDisputeRow), findsOneWidget);

      await tester.tap(find.text('Switch node'));
      await tester.pumpAndSettle();
      expect(find.byType(ChooseNodeScreen), findsOneWidget);
    });

    testWidgets('no answer: nothing is retried, and Recover is offered', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      final core = _withPending()..takeOutcome = TakeOutcome.noAnswer;
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);

      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pumpAndSettle();

      expect(find.text('The node did not answer'), findsOneWidget);
      expect(core.takes, [_a], reason: 'asked once');
      await tester.tap(find.text('Recover a dispute'));
      await tester.pumpAndSettle();
      expect(find.byType(RecoverScreen), findsOneWidget);
      expect(core.takes, [_a], reason: 'opening Recover asks nothing');
    });

    testWidgets('a refusal and a request that did not leave say why', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      final core =
          _withPending()
            ..takeOutcome = TakeOutcome.refused
            ..takeReason = 'not_found';
      await _pump(tester, core, locale: const Locale('en'), textScale: 1);

      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pumpAndSettle();
      expect(find.text('The node did not give you this dispute'), findsOne);
      expect(
        find.text('The node no longer has this dispute\'s order.'),
        findsOne,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      core.takeError = TakeError.noRelays;
      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pumpAndSettle();
      expect(find.text('The request was not sent'), findsOne);
      expect(find.textContaining('No relay took it'), findsOne);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // The node's settings (its PoW) were never read: nothing was sent.
      core.takeError = TakeError.nodeInfoUnavailable;
      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take dispute'));
      await tester.pumpAndSettle();
      expect(find.text('The request was not sent'), findsOne);
      expect(find.textContaining('could not read this node'), findsOne);
    });
  });

  group('In progress', () {
    testWidgets('a row shows the amount, the opener, when it was taken and '
        'the short id, in lime: the solver\'s move', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core = FakeDisputesCore()..held = [sampleTaken()];
      await _pump(
        tester,
        core,
        location: AppRoute.inProgress,
        locale: const Locale('en'),
        textScale: 1,
      );
      expect(find.text('75,000 sats · 50 EUR'), findsOneWidget);
      expect(find.text('Opened by the seller'), findsOneWidget);
      expect(find.text('Taken 1 hour ago'), findsOneWidget);
      expect(find.text('8a0c1e64…4b2c'), findsOneWidget);
      expect(
        tester.widget<StatusChip>(find.byType(StatusChip)).kind,
        StatusChipKind.turn,
      );
    });

    testWidgets('amounts read in the solver\'s language, the fiat code only '
        'when known', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core =
          FakeDisputesCore()
            ..held = [sampleTaken(amount: 1234567, fiatCode: null)];
      await _pump(
        tester,
        core,
        location: AppRoute.inProgress,
        locale: const Locale('es'),
        textScale: 1,
      );
      expect(find.text('1.234.567 sats · 50'), findsOneWidget);
    });

    testWidgets('the header and the empty state open Recover a dispute', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      await _pump(
        tester,
        FakeDisputesCore(),
        location: AppRoute.inProgress,
        locale: const Locale('en'),
        textScale: 1,
      );
      expect(find.text('No disputes in progress'), findsOneWidget);
      await tester.tap(find.text('Recover a dispute'));
      await tester.pumpAndSettle();
      expect(find.byType(RecoverScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recover'));
      await tester.pumpAndSettle();
      expect(find.byType(RecoverScreen), findsOneWidget);
    });
  });

  group('Recover a dispute', () {
    testWidgets('one at a time, behind a confirmation that warns about the '
        'take-over', (tester) async {
      setSurface(tester, width: 400, height: 800);
      final core =
          FakeDisputesCore()
            ..candidates = [
              sampleDispute(id: _a, status: DisputeStatus.inProgress),
              sampleDispute(id: _b, status: DisputeStatus.inProgress),
            ];
      await _pump(
        tester,
        core,
        location: AppRoute.recover,
        locale: const Locale('en'),
        textScale: 1,
      );
      // Not known to be the solver's: neutral (amendment 3).
      for (final chip in tester.widgetList<StatusChip>(
        find.byType(StatusChip),
      )) {
        expect(chip.kind, StatusChipKind.neutral);
      }
      expect(find.textContaining('other solvers\''), findsOneWidget);

      await tester.tap(find.byType(PendingDisputeRow).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('read-only, like Serbero'), findsOneWidget);
      await tester.tap(find.text('Recover dispute'));
      await tester.pumpAndSettle();

      expect(core.takes, [_a], reason: 'never in bulk');
      expect(
        find.text('Dispute recovered. It is in Your disputes.'),
        findsOneWidget,
      );
      await _afterUpdates(tester);
      expect(find.byType(PendingDisputeRow), findsOneWidget);
    });

    testWidgets('a dispute held by another solver cannot be taken over', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 800);
      final core =
          FakeDisputesCore()
            ..candidates = [
              sampleDispute(id: _a, status: DisputeStatus.inProgress),
            ]
            ..takeOutcome = TakeOutcome.cannotTakeOver;
      await _pump(
        tester,
        core,
        location: AppRoute.recover,
        locale: const Locale('en'),
        textScale: 1,
      );
      await tester.tap(find.byType(PendingDisputeRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recover dispute'));
      await tester.pumpAndSettle();
      expect(find.text('Another solver holds this dispute'), findsOneWidget);
      expect(find.textContaining('Only a dispute held by'), findsOneWidget);
      // Ambiguous: no banner says this key is no solver.
      expect(core.status, SolverStatus.unknown);
    });

    testWidgets('nothing to recover says so', (tester) async {
      setSurface(tester);
      await _pump(tester, FakeDisputesCore(), location: AppRoute.recover);
      expect(tester.takeException(), isNull);
      expect(find.text('Nada que recuperar'), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('shows whether this key is a solver here once known', (
      tester,
    ) async {
      setSurface(tester, width: 400, height: 900);
      final core = FakeDisputesCore();
      await _pump(
        tester,
        core,
        location: AppRoute.settings,
        locale: const Locale('en'),
        textScale: 1,
      );
      expect(find.text('Solver on this node'), findsNothing);
      expect(find.text('Permission'), findsNothing);
    });

    testWidgets('known standing and permission', (tester) async {
      setSurface(tester, width: 400, height: 900);
      final core =
          FakeDisputesCore()
            ..status = SolverStatus.yes
            ..permission = SolverPermission.read;
      await _pump(
        tester,
        core,
        location: AppRoute.settings,
        locale: const Locale('en'),
        textScale: 1,
      );
      expect(find.text('Solver on this node'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Mediate only'), findsOneWidget);
    });

    testWidgets('fits at 320 dp, 2× text, es with the standing known', (
      tester,
    ) async {
      setSurface(tester);
      final core =
          FakeDisputesCore()
            ..status = SolverStatus.no
            ..permission = SolverPermission.readWrite;
      await _pump(tester, core, location: AppRoute.settings);
      expect(tester.takeException(), isNull);
      expect(find.text('Solver en este nodo'), findsOneWidget);
    });
  });
}
