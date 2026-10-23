// The phase 5 screens against a real mostrod and relay, on Linux, by hand:
// take a dispute, open it, and trade messages with its buyer and its seller,
// played by `rust/examples/chat_party.rs` with their trade keys. Never
// against a real node. Skipped unless the dart-defines below are set
// (README.md here).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
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

const _relay = String.fromEnvironment('E2E_RELAY');
const _node = String.fromEnvironment('E2E_NODE');
const _solver = String.fromEnvironment('E2E_SOLVER');
const _solverPubkey = String.fromEnvironment('E2E_SOLVER_PUBKEY');
const _dispute = String.fromEnvironment('E2E_DISPUTE');
const _buyer = String.fromEnvironment('E2E_BUYER');
const _seller = String.fromEnvironment('E2E_SELLER');
const _party = String.fromEnvironment('E2E_PARTY_BIN');

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

/// Pump frames until [finder] finds something, or fail after [seconds].
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

/// The party simulator, run while the app keeps pumping frames.
Future<ProcessResult> _partyRun(
  WidgetTester tester,
  String secret,
  List<String> args,
) async {
  final run = Process.run(_party, [_relay, secret, _solverPubkey, ...args]);
  ProcessResult? result;
  run.then((r) => result = r);
  while (result == null) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  debugPrint('[e2e] party: ${(result!.stdout as String).trim()}');
  return result!;
}

Finder _segment(String label) => find.descendant(
  of: find.byType(DetailSegments<DetailSection>),
  matching: find.text(label),
);

/// The message field and send button of the conversation on screen (the
/// detail keeps the other parts built, offstage).
Finder _shown(Finder finder) =>
    find.descendant(of: find.byType(IndexedStack), matching: finder);
Finder _field() => _shown(find.byType(TextField));
Finder _send() => _shown(
  find.ancestor(of: find.byTooltip('Send'), matching: find.byType(IconButton)),
);

/// One party writes, the solver reads it in the app and answers, and the
/// party reads the answer.
Future<void> _exchange(
  WidgetTester tester, {
  required String segment,
  required String secret,
  required String said,
  required String answer,
}) async {
  await tester.tap(_segment(segment));
  await tester.pump(const Duration(milliseconds: 500));

  final wrote = await _partyRun(tester, secret, ['--say', said]);
  expect(wrote.exitCode, 0, reason: wrote.stderr.toString());
  await _until(
    tester,
    find.descendant(of: find.byType(ChatBubble), matching: find.text(said)),
    what: 'the $segment\'s message',
  );
  debugPrint('[e2e] the app shows the $segment\'s message');

  // The desktop binding has no test text input: type through the
  // controller, which the composer listens to as it does to a keyboard.
  tester.widget<TextField>(_field()).controller!.text = answer;
  await tester.pump();
  await tester.tap(_send());
  await _until(
    tester,
    find.descendant(of: find.byType(ChatBubble), matching: find.text(answer)),
    what: 'the answer in the chat',
  );
  // Sent once a relay took it (it comes back too: K_sign is shared).
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.textContaining('Sending…').evaluate().isEmpty) break;
  }
  expect(find.textContaining('Sending…'), findsNothing);
  expect(find.text('Not sent'), findsNothing);

  final read = await _partyRun(tester, secret, ['--expect', answer]);
  expect(read.exitCode, 0, reason: read.stderr.toString());
  debugPrint('[e2e] the $segment read the answer');

  // The echo of the answer is the same message: shown once.
  await tester.pump(const Duration(seconds: 2));
  expect(
    find.descendant(of: find.byType(ChatBubble), matching: find.text(answer)),
    findsOneWidget,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'take a dispute and talk with its buyer and its seller, '
    'against a local mostrod',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('en')];

      await RustLib.init();
      final dir = await Directory.systemTemp.createTemp('bosstro_e2e_chat_');
      await rust.initDb(path: '${dir.path}/bosstro.db');
      await nodes_api.selectActiveNode(pubkey: _node);
      await relays_api.initializeRelays();
      await relays_api.addRelay(url: _relay);
      for (final relay in await relays_api.getRelays()) {
        if (relay.url != _relay) {
          await relays_api.removeRelay(url: relay.url);
        }
      }

      final service = SolverKeyService(store: _MemoryStore());
      final solver = await service.logIn(_solver);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            solverKeyServiceProvider.overrideWithValue(service),
            solverKeyProvider.overrideWith(() => SolverKeyNotifier(solver)),
            activeNodeProvider.overrideWith(() => ActiveNodeNotifier(_node)),
          ],
          child: const BosstroApp(initialLocation: AppRoute.pending),
        ),
      );

      // ── 1. Take the test dispute from Pending ───────────────────────────
      final row = find.byWidgetPredicate(
        (w) => w is PendingDisputeRow && w.dispute.disputeId == _dispute,
      );
      await _until(tester, row, what: 'the test dispute in Pending');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await _until(tester, find.text('Take dispute'));
      await tester.tap(find.text('Take dispute'));
      await _until(
        tester,
        find.text('Dispute taken. It is in Your disputes.'),
        what: 'the take',
      );
      debugPrint('[e2e] 1. taken $_dispute');
      // The take's confirmation floats over the message field for its two
      // seconds; this test types faster than that, so it waits it out.
      for (
        var i = 0;
        i < 40 && find.byType(SnackBar).evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // ── 2. Open it from Your disputes ───────────────────────────────────
      await tester.tap(find.text('In progress'));
      final held = find.byWidgetPredicate(
        (w) => w is InProgressDisputeRow && w.dispute.disputeId == _dispute,
      );
      await _until(tester, held, what: 'the dispute in Your disputes');
      await tester.ensureVisible(held);
      await tester.tap(held);
      await _until(tester, find.byType(DisputeDetailView), what: 'the detail');
      await _until(tester, find.text('Dispute ID'), what: 'the Info rows');
      debugPrint(
        '[e2e] 2. detail open '
        '(${find.byType(DisputeDetailScreen).evaluate().isEmpty ? 'beside the list' : 'pushed'})',
      );

      // ── 3. The buyer, then the seller ───────────────────────────────────
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await _exchange(
        tester,
        segment: 'Buyer',
        secret: _buyer,
        said: 'Buyer here: the fiat went out at 10:00 ($stamp)',
        answer: 'Thanks. Please send the bank receipt ($stamp)',
      );
      debugPrint('[e2e] 3. buyer: both ways');
      await _exchange(
        tester,
        segment: 'Seller',
        secret: _seller,
        said: 'Seller here: nothing arrived yet ($stamp)',
        answer: 'Please check again and send a statement ($stamp)',
      );
      debugPrint('[e2e] 3. seller: both ways');

      // The two conversations did not mix.
      await tester.tap(_segment('Buyer'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Seller here: nothing arrived yet ($stamp)').hitTestable(),
        findsNothing,
      );
      debugPrint('[e2e] the conversations stay apart');
    },
    skip:
        _relay.isEmpty ||
        _node.isEmpty ||
        _solver.isEmpty ||
        _solverPubkey.isEmpty ||
        _dispute.isEmpty ||
        _buyer.isEmpty ||
        _seller.isEmpty ||
        _party.isEmpty,
  );
}
