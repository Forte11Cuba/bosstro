// The phase 4 screens against a real mostrod and relay, on Linux, by hand:
// not a solver, a take from Pending, and a Recover. Never against a real
// node. Skipped unless the dart-defines below are set (README.md here).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/disputes/screens/recover_screen.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/not_solver_banner.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/take_dialog.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/src/rust/api.dart' as rust;
import 'package:bosstro/src/rust/api/nodes.dart' as nodes_api;
import 'package:bosstro/src/rust/api/relays.dart' as relays_api;
import 'package:bosstro/src/rust/frb_generated.dart';

const _relay = String.fromEnvironment('E2E_RELAY');
const _node = String.fromEnvironment('E2E_NODE');
const _stranger = String.fromEnvironment('E2E_STRANGER');
const _solver = String.fromEnvironment('E2E_SOLVER');

/// The key in memory: the desktop keyring is never touched.
class _MemoryStore implements SecretStore {
  final _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

/// Pump frames until [finder] finds something, or fail after [seconds]. The
/// shimmer and the minute ticks never let `pumpAndSettle` settle.
Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
  String? what,
}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for ${what ?? finder}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'not a solver, a take from Pending and a Recover, against a local mostrod',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('en')];

      await RustLib.init();
      // A database of its own: the developer's is never touched.
      final dir = await Directory.systemTemp.createTemp('bosstro_e2e_');
      await rust.initDb(path: '${dir.path}/bosstro.db');
      await nodes_api.selectActiveNode(pubkey: _node);
      await relays_api.initializeRelays();
      // The local relay only: the defaults are removed (in this database).
      await relays_api.addRelay(url: _relay);
      for (final relay in await relays_api.getRelays()) {
        if (relay.url != _relay) {
          await relays_api.removeRelay(url: relay.url);
        }
      }

      final service = SolverKeyService(store: _MemoryStore());
      final stranger = await service.logIn(_stranger);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            solverKeyServiceProvider.overrideWithValue(service),
            solverKeyProvider.overrideWith(() => SolverKeyNotifier(stranger)),
            activeNodeProvider.overrideWith(() => ActiveNodeNotifier(_node)),
          ],
          child: const BosstroApp(initialLocation: AppRoute.pending),
        ),
      );

      // ── 1. A key the node does not know: not a solver ───────────────────
      await _until(tester, find.byType(PendingDisputeRow), what: 'Pending');
      final waiting = find.byType(PendingDisputeRow).evaluate().length;
      debugPrint('[e2e] Pending lists $waiting disputes');
      await tester.tap(find.byType(PendingDisputeRow).first);
      await _until(tester, find.text('Take dispute'));
      await tester.tap(find.text('Take dispute'));
      await _until(
        tester,
        find.descendant(
          of: find.byType(TakeDialog),
          matching: find.text('You are not a solver on this node'),
        ),
        what: 'the not-a-solver outcome',
      );
      await tester.tap(find.text('Close'));
      await _until(tester, find.byType(NotSolverBanner), what: 'the banner');
      debugPrint('[e2e] 1. not a solver: outcome and banner shown');

      // ── 2. A solver key takes the oldest waiting dispute ────────────────
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BosstroApp)),
      );
      await container.read(solverKeyProvider.notifier).logIn(_solver);
      await _until(
        tester,
        find.byType(PendingDisputeRow),
        what: 'Pending again',
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(NotSolverBanner), findsNothing);
      final first = tester.widget<PendingDisputeRow>(
        find.byType(PendingDisputeRow).first,
      );
      final taken = first.dispute.disputeId;
      await tester.tap(find.byType(PendingDisputeRow).first);
      await _until(tester, find.text('Take dispute'));
      await tester.tap(find.text('Take dispute'));
      await _until(
        tester,
        find.text('Dispute taken. It is in Your disputes.'),
        what: 'the take',
      );
      await tester.tap(find.text('In progress'));
      await _until(
        tester,
        find.byType(InProgressDisputeRow),
        what: 'Your disputes',
      );
      final row = tester.widget<InProgressDisputeRow>(
        find.byType(InProgressDisputeRow).first,
      );
      expect(row.dispute.disputeId, taken);
      debugPrint(
        '[e2e] 2. taken $taken: ${row.dispute.amount} sats, '
        '${row.dispute.fiatAmount} ${row.dispute.fiatCode}',
      );

      // ── 3. Recover a dispute this key holds on the node, not here ───────
      await tester.tap(find.text('Recover'));
      await _until(tester, find.byType(RecoverScreen));
      await _until(
        tester,
        find.byType(PendingDisputeRow),
        what: 'a Recover candidate',
      );
      final candidate =
          tester
              .widget<PendingDisputeRow>(find.byType(PendingDisputeRow).first)
              .dispute
              .disputeId;
      await tester.tap(find.byType(PendingDisputeRow).first);
      await _until(tester, find.text('Recover dispute'));
      await tester.tap(find.text('Recover dispute'));
      final recovered = find.text('Dispute recovered. It is in Your disputes.');
      final refused = find.text('Another solver holds this dispute');
      await _until(
        tester,
        find.byWidgetPredicate(
          (_) =>
              recovered.evaluate().isNotEmpty || refused.evaluate().isNotEmpty,
        ),
        what: 'the recover outcome',
      );
      debugPrint(
        '[e2e] 3. recover $candidate: '
        '${recovered.evaluate().isNotEmpty ? 'recovered' : 'cannot take over'}',
      );
      expect(recovered, findsOneWidget);
      // Back on Your disputes, it is listed with the one taken in step 2.
      await tester.pageBack();
      await _until(
        tester,
        find.byWidgetPredicate(
          (w) => w is InProgressDisputeRow && w.dispute.disputeId == candidate,
        ),
        what: 'the recovered dispute in Your disputes',
      );
      debugPrint(
        '[e2e] Your disputes: '
        '${find.byType(InProgressDisputeRow).evaluate().length} rows',
      );
    },
    skip:
        _relay.isEmpty || _node.isEmpty || _stranger.isEmpty || _solver.isEmpty,
  );
}
