// The phase 6 screens against a real mostrod, a real relay and real regtest
// sats, on Linux, by hand (README.md here). Never against a real node.
//
// The disputes must be real trades (a hold invoice the seller paid), made
// with mostro-cli; each step names the ones it uses:
//
// - `E2E_STEP=read-only` logs in a Read solver, takes `E2E_DISPUTE_2`, and
//   asks to pay its buyer: the node says the key may not, and the detail and
//   Settings say so.
// - `E2E_STEP=resolve` logs in a Read-Write solver: it takes `E2E_DISPUTE`
//   and pays its buyer; takes `E2E_DISPUTE_3` and leaves it (for a
//   cooperative cancel after); takes `E2E_DISPUTE_2` over from the Read
//   solver through Recover a dispute and refunds its seller. Both end in the
//   closed disputes. The sats are checked outside, with lncli.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/features/disputes/screens/recover_screen.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/resolution/screens/resolution_screen.dart';
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';

import 'e2e_support.dart';

const _relay = String.fromEnvironment('E2E_RELAY');
const _node = String.fromEnvironment('E2E_NODE');
const _solver = String.fromEnvironment('E2E_SOLVER');
const _step = String.fromEnvironment('E2E_STEP');
const _dispute = String.fromEnvironment('E2E_DISPUTE');
const _dispute2 = String.fromEnvironment('E2E_DISPUTE_2');
const _dispute3 = String.fromEnvironment('E2E_DISPUTE_3');

/// Ask for [action] ("Pay the buyer" / "Refund the seller") on the dispute
/// open in the detail, confirm it on the full-screen confirmation, and wait
/// for the outcome titled [outcome].
Future<void> _resolve(
  WidgetTester tester,
  String action,
  String outcome,
) async {
  final opener = find.descendant(
    of: find.byType(ResolutionCard),
    matching: find.text(action),
  );
  await until(tester, opener, what: 'the resolution card');
  await tester.ensureVisible(opener);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(opener);
  await until(tester, find.byType(ResolutionScreen), what: 'the confirmation');
  final answer = find.descendant(
    of: find.byType(ResolutionScreen),
    matching: find.widgetWithText(FilledButton, action),
  );
  await until(tester, answer, what: 'the confirmation\'s answer');
  await tester.ensureVisible(answer);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(answer);
  await until(tester, find.text(outcome), seconds: 40, what: outcome);
  debugPrint('[e2e] $action: $outcome');
}

/// Leave the outcome for the dispute.
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.text('Back to the dispute'));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.byType(ResolutionScreen), findsNothing);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'resolution against a local mostrod: $_step',
    (tester) async {
      await startApp(tester, relay: _relay, node: _node, solver: _solver);
      await until(tester, find.text('Pending'));

      if (_step == 'read-only') {
        await takeDispute(tester, _dispute2);
        await openDispute(tester, _dispute2);
        await _resolve(
          tester,
          'Pay the buyer',
          'You cannot pay or refund on this node',
        );
        await _back(tester);
        // The actions stay, with the reason they will be refused.
        await until(
          tester,
          find.textContaining('can mediate on this node but not pay or refund'),
          what: 'the read-only note',
        );
        expect(find.text('Pay the buyer'), findsOneWidget);
        // Settings shows the permission learned.
        if (find.byTooltip('Back').evaluate().isNotEmpty) {
          await tester.tap(find.byTooltip('Back'));
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.tap(find.text('Settings'));
        await until(tester, find.text('Mediate only'), what: 'the permission');
        debugPrint('[e2e] Settings: Mediate only');
        return;
      }

      expect(_step, 'resolve');
      // ── Pay the buyer ────────────────────────────────────────────────
      await takeDispute(tester, _dispute);
      await openDispute(tester, _dispute);
      await _resolve(tester, 'Pay the buyer', 'Resolved: you paid the buyer');
      await _back(tester);
      expect(find.byType(ResolutionCard), findsNothing, reason: 'read only now');
      await until(tester, find.text('You paid the buyer'), what: 'the result');

      // ── A third one, left for a cooperative cancel ───────────────────
      await takeDispute(tester, _dispute3);

      // ── Take over the Read solver's and refund the seller ────────────
      if (find.byTooltip('Back').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Back'));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.tap(find.text('In progress'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Recover'));
      await until(tester, find.byType(RecoverScreen));
      final candidate = find.byWidgetPredicate(
        (w) => w is PendingDisputeRow && w.dispute.disputeId == _dispute2,
      );
      await until(tester, candidate, what: 'the Read solver\'s dispute');
      await tester.ensureVisible(candidate);
      await tester.tap(candidate);
      await until(tester, find.text('Recover dispute'));
      await tester.tap(find.text('Recover dispute'));
      await until(
        tester,
        find.text('Dispute recovered. It is in My disputes.'),
        what: 'the take-over',
      );
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      await openDispute(tester, _dispute2);
      await _resolve(
        tester,
        'Refund the seller',
        'Resolved: you refunded the seller',
      );
      await _back(tester);

      // ── Both closed, under the open one ──────────────────────────────
      if (find.byTooltip('Back').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Back'));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.tap(find.text('In progress'));
      await until(tester, find.text('Closed'), what: 'the closed disputes');
      final closed =
          tester
              .widgetList<InProgressDisputeRow>(
                find.byType(InProgressDisputeRow),
              )
              .map((r) => (r.dispute.disputeId, r.dispute.resolvedAs))
              .toList();
      debugPrint('[e2e] In progress: $closed');
      expect(closed.first.$1, _dispute3, reason: 'the open one first');
    },
    skip:
        _relay.isEmpty ||
        _node.isEmpty ||
        _solver.isEmpty ||
        _step.isEmpty ||
        _dispute2.isEmpty,
  );
}
