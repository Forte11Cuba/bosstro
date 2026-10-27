// What the end-to-end runs against a local mostrod share (README.md here):
// the app on a temporary database with the key in memory, the waits, the
// party simulator, and taking and opening a dispute. Never a real node.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/src/rust/api.dart' as rust;
import 'package:bosstro/src/rust/api/nodes.dart' as nodes_api;
import 'package:bosstro/src/rust/api/relays.dart' as relays_api;
import 'package:bosstro/src/rust/frb_generated.dart';

/// The key in memory: the desktop keyring is never touched.
class MemoryStore implements SecretStore {
  final _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

/// Starts the real core on a temporary database, follows [node] over
/// [relay] alone, logs [solver] in (in memory) and pumps the app on Pending,
/// in English, with [overrides] on top.
Future<void> startApp(
  WidgetTester tester, {
  required String relay,
  required String node,
  required String solver,
  List<Override> overrides = const [],
}) async {
  tester.platformDispatcher.localesTestValue = [const Locale('en')];

  await RustLib.init();
  final dir = await Directory.systemTemp.createTemp('bosstro_e2e_');
  await rust.initDb(path: '${dir.path}/bosstro.db');
  await nodes_api.selectActiveNode(pubkey: node);
  await relays_api.initializeRelays();
  await relays_api.addRelay(url: relay);
  for (final known in await relays_api.getRelays()) {
    if (known.url != relay) {
      await relays_api.removeRelay(url: known.url);
    }
  }

  final service = SolverKeyService(store: MemoryStore());
  final key = await service.logIn(solver);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        solverKeyServiceProvider.overrideWithValue(service),
        solverKeyProvider.overrideWith(() => SolverKeyNotifier(key)),
        activeNodeProvider.overrideWith(() => ActiveNodeNotifier(node)),
        ...overrides,
      ],
      child: const BosstroApp(initialLocation: AppRoute.pending),
    ),
  );
}

/// Pump frames until [finder] finds something, or fail after [seconds].
Future<void> until(
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

/// Pump frames until [check] holds, or fail after [seconds].
Future<void> untilTrue(
  WidgetTester tester,
  bool Function() check, {
  int seconds = 30,
  required String what,
}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (check()) return;
  }
  fail('timed out waiting for $what');
}

/// The party simulator (`rust/examples/chat_party.rs`) at [bin], run with
/// [args] after its relay, secret and the solver's pubkey, while the app
/// keeps pumping frames.
Future<ProcessResult> partyRun(
  WidgetTester tester, {
  required String bin,
  required String relay,
  required String solverPubkey,
  required String secret,
  required List<String> args,
}) async {
  final run = Process.run(bin, [relay, secret, solverPubkey, ...args]);
  ProcessResult? result;
  run.then((r) => result = r);
  while (result == null) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  debugPrint('[e2e] party: ${(result!.stdout as String).trim()}');
  return result!;
}

/// The detail's segment named [label].
Finder detailSegment(String label) => find.descendant(
  of: find.byType(DetailSegments<DetailSection>),
  matching: find.text(label),
);

/// [finder] within the part of the detail on screen (the others stay built,
/// offstage).
Finder shown(Finder finder) =>
    find.descendant(of: find.byType(IndexedStack), matching: finder);

/// Take [dispute] from Pending.
Future<void> takeDispute(WidgetTester tester, String dispute) async {
  await tester.tap(find.text('Pending'));
  final row = find.byWidgetPredicate(
    (w) => w is PendingDisputeRow && w.dispute.disputeId == dispute,
  );
  await until(tester, row, what: 'dispute $dispute in Pending');
  await tester.ensureVisible(row);
  await tester.tap(row);
  await until(tester, find.text('Take dispute'));
  await tester.tap(find.text('Take dispute'));
  await until(
    tester,
    find.text('Dispute taken. It is in My disputes.'),
    what: 'the take of $dispute',
  );
  // The confirmation floats over the message field for its two seconds;
  // the tests type faster than that, so they wait it out.
  for (var i = 0; i < 40 && find.byType(SnackBar).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Open [dispute] from My disputes (pushed, or beside the list).
Future<void> openDispute(WidgetTester tester, String dispute) async {
  if (find.byType(DisputeDetailScreen).evaluate().isNotEmpty) {
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.tap(find.text('In progress'));
  final held = find.byWidgetPredicate(
    (w) => w is InProgressDisputeRow && w.dispute.disputeId == dispute,
  );
  await until(tester, held, what: 'dispute $dispute in My disputes');
  await tester.ensureVisible(held);
  await tester.tap(held);
  await until(
    tester,
    find.byWidgetPredicate(
      (w) => w is DisputeDetailView && w.disputeId == dispute,
    ),
    what: 'the detail of $dispute',
  );
  await until(tester, find.text('Dispute ID'), what: 'the Info rows');
}
