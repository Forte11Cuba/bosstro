// The phase 5 screens against a real mostrod and relay, on Linux, by hand:
// take two disputes, open them, and trade messages with their buyers and
// sellers, played by `rust/examples/chat_party.rs` with their trade keys.
// Never against a real node. Skipped unless the dart-defines below are set
// (README.md here).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';

import 'e2e_support.dart';

const _relay = String.fromEnvironment('E2E_RELAY');
const _node = String.fromEnvironment('E2E_NODE');
const _solver = String.fromEnvironment('E2E_SOLVER');
const _solverPubkey = String.fromEnvironment('E2E_SOLVER_PUBKEY');
const _dispute = String.fromEnvironment('E2E_DISPUTE');
const _buyer = String.fromEnvironment('E2E_BUYER');
const _seller = String.fromEnvironment('E2E_SELLER');
const _dispute2 = String.fromEnvironment('E2E_DISPUTE_2');
const _buyer2 = String.fromEnvironment('E2E_BUYER_2');
const _seller2 = String.fromEnvironment('E2E_SELLER_2');
const _party = String.fromEnvironment('E2E_PARTY_BIN');

/// The party simulator, run while the app keeps pumping frames.
Future<ProcessResult> _partyRun(
  WidgetTester tester,
  String secret,
  List<String> args,
) => partyRun(
  tester,
  bin: _party,
  relay: _relay,
  solverPubkey: _solverPubkey,
  secret: secret,
  args: args,
);

/// The message field and send button of the conversation on screen.
Finder _field() => shown(find.byType(TextField));
Finder _send() => shown(
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
  await tester.tap(detailSegment(segment));
  await tester.pump(const Duration(milliseconds: 500));

  final wrote = await _partyRun(tester, secret, ['--say', said]);
  expect(wrote.exitCode, 0, reason: wrote.stderr.toString());
  await until(
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
  await until(
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
      await startApp(tester, relay: _relay, node: _node, solver: _solver);

      final stamp = DateTime.now().millisecondsSinceEpoch;

      // ── 1. The first dispute: take it, talk with its buyer ─────────────
      await takeDispute(tester, _dispute);
      await openDispute(tester, _dispute);
      debugPrint(
        '[e2e] 1. took and opened $_dispute '
        '(${find.byType(DisputeDetailScreen).evaluate().isEmpty ? 'beside the list' : 'pushed'})',
      );
      await _exchange(
        tester,
        segment: 'Buyer',
        secret: _buyer,
        said: 'Buyer 1: the fiat went out at 10:00 ($stamp)',
        answer: 'Thanks, buyer 1. Send the receipt ($stamp)',
      );
      debugPrint('[e2e] 1. dispute 1, buyer: both ways');

      // ── 2. A second dispute: the shared REQ is rebuilt ──────────────────
      await takeDispute(tester, _dispute2);
      await openDispute(tester, _dispute2);
      debugPrint('[e2e] 2. took and opened $_dispute2');
      await _exchange(
        tester,
        segment: 'Buyer',
        secret: _buyer2,
        said: 'Buyer 2: I paid by SEPA ($stamp)',
        answer: 'Thanks, buyer 2 ($stamp)',
      );
      await _exchange(
        tester,
        segment: 'Seller',
        secret: _seller2,
        said: 'Seller 2: nothing arrived ($stamp)',
        answer: 'Please check again, seller 2 ($stamp)',
      );
      debugPrint('[e2e] 2. dispute 2, buyer and seller: both ways');

      // ── 3. Back on the first, over the rebuilt REQ ──────────────────────
      await openDispute(tester, _dispute);
      await _exchange(
        tester,
        segment: 'Seller',
        secret: _seller,
        said: 'Seller 1: still waiting ($stamp)',
        answer: 'Noted, seller 1 ($stamp)',
      );
      debugPrint('[e2e] 3. dispute 1, seller: both ways after the rebuild');

      // Nothing crossed: dispute 1's buyer chat has only its own messages.
      await tester.tap(detailSegment('Buyer'));
      await tester.pump(const Duration(milliseconds: 500));
      final bubbles =
          find
              .descendant(
                of: find.byType(IndexedStack),
                matching: find.byType(ChatBubble),
              )
              .evaluate()
              .map((e) => (e.widget as ChatBubble).message.content)
              .toList();
      debugPrint('[e2e] dispute 1, buyer chat: $bubbles');
      expect(bubbles.toSet(), {
        'Buyer 1: the fiat went out at 10:00 ($stamp)',
        'Thanks, buyer 1. Send the receipt ($stamp)',
      });
    },
    skip:
        _relay.isEmpty ||
        _node.isEmpty ||
        _solver.isEmpty ||
        _solverPubkey.isEmpty ||
        _dispute.isEmpty ||
        _buyer.isEmpty ||
        _seller.isEmpty ||
        _dispute2.isEmpty ||
        _buyer2.isEmpty ||
        _seller2.isEmpty ||
        _party.isEmpty,
  );
}
