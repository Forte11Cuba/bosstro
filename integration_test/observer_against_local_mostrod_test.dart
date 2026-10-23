// The phase 5c screens against a real mostrod and relay, on Linux, by hand:
// the buyer and the seller of a dispute write to each other in their own
// chat, as ../app does (one sends a file), the seller shares the chat key
// with the solver, and the app reads that chat, read only: the file shows
// and cannot be opened. Then a wrong key and the right one are pasted.
// The parties are played by `rust/examples/chat_party.rs` with their trade
// keys; files go to a local Blossom server (`blossom_server`). Never against
// a real node. Skipped unless the dart-defines below are set (README.md
// here).
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/features/observer/screens/observer_screen.dart';
import 'package:bosstro/features/observer/widgets/observed_bubble.dart';
import 'package:bosstro/features/observer/widgets/paste_key_dialog.dart';

import 'e2e_support.dart';

const _relay = String.fromEnvironment('E2E_RELAY');
const _node = String.fromEnvironment('E2E_NODE');
const _solver = String.fromEnvironment('E2E_SOLVER');
const _solverPubkey = String.fromEnvironment('E2E_SOLVER_PUBKEY');
const _dispute = String.fromEnvironment('E2E_DISPUTE');
const _buyer = String.fromEnvironment('E2E_BUYER');
const _seller = String.fromEnvironment('E2E_SELLER');
const _party = String.fromEnvironment('E2E_PARTY_BIN');
const _blossom = String.fromEnvironment('E2E_BLOSSOM');
const _files = String.fromEnvironment('E2E_FILES');

/// The party simulator, run while the app keeps pumping frames; fails the
/// test when it fails.
Future<String> _partyRun(
  WidgetTester tester,
  String secret,
  List<String> args,
) async {
  final run = await partyRun(
    tester,
    bin: _party,
    relay: _relay,
    solverPubkey: _solverPubkey,
    secret: secret,
    args: args,
  );
  expect(run.exitCode, 0, reason: run.stderr.toString());
  return run.stdout as String;
}

/// What the party simulator printed after [label].
String _printed(String out, String label) => out
    .split('\n')
    .firstWhere((line) => line.startsWith('$label: '))
    .substring(label.length + 2)
    .trim();

/// A bubble of the observed chat that says [text].
Finder _observed(String text) =>
    find.descendant(of: find.byType(ObservedBubble), matching: find.text(text));

/// Paste [key] in the dialog (typed through its controller: the desktop
/// binding has no test text input) and ask for the chat.
Future<void> _paste(WidgetTester tester, String key) async {
  await until(tester, find.byType(PasteKeyDialog), what: 'the paste dialog');
  final field = find.descendant(
    of: find.byType(PasteKeyDialog),
    matching: find.byType(TextField),
  );
  tester.widget<TextField>(field).controller!.text = key;
  await tester.pump();
  await tester.tap(find.text('Read the chat'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'read the chat between the parties with the key one shared, '
    'against a local mostrod',
    (tester) async {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final buyerSaid = 'Buyer to seller: the fiat went out at 10:00 ($stamp)';
      final sellerSaid = 'Seller to buyer: nothing on my side yet ($stamp)';

      // ── 0. Their own chat, before the solver is involved ───────────────
      final buyerPubkey = _printed(
        await _partyRun(tester, _buyer, ['--print-pubkey']),
        'pubkey',
      );
      final sellerPubkey = _printed(
        await _partyRun(tester, _seller, ['--print-pubkey']),
        'pubkey',
      );
      await _partyRun(tester, _buyer, [
        '--peer',
        sellerPubkey,
        '--say',
        buyerSaid,
      ]);
      await _partyRun(tester, _seller, [
        '--peer',
        buyerPubkey,
        '--say',
        sellerSaid,
      ]);
      await _partyRun(tester, _seller, [
        '--peer',
        buyerPubkey,
        '--blossom',
        _blossom,
        '--send-file',
        '$_files/bank-statement.pdf',
      ]);
      final key = _printed(
        await _partyRun(tester, _buyer, [
          '--peer',
          sellerPubkey,
          '--print-key',
        ]),
        'key',
      );
      debugPrint('[e2e] 0. the parties wrote to each other, one file');

      // ── 1. Take the dispute; the seller shares the key ─────────────────
      await startApp(tester, relay: _relay, node: _node, solver: _solver);
      await takeDispute(tester, _dispute);
      await openDispute(tester, _dispute);
      await _partyRun(tester, _seller, ['--peer', buyerPubkey, '--share-key']);
      final shared = find.textContaining('The seller shared their chat key on');
      await until(tester, shared, what: 'the disclosure in Info');
      debugPrint('[e2e] 1. the app saw the seller share the key');

      // ── 2. Read: both sides, the file locked, nothing to write with ────
      final read = find.text('Read the chat between the parties');
      await tester.ensureVisible(read);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(read);
      await until(tester, find.byType(ObserverScreen), what: 'the screen');
      await until(tester, _observed(buyerSaid), what: 'the buyer\'s message');
      await until(tester, _observed(sellerSaid), what: 'the seller\'s');
      await until(
        tester,
        find.text('bank-statement.pdf'),
        what: 'the seller\'s file',
      );
      expect(
        find.text('It cannot be opened with a chat key.'),
        findsOneWidget,
      );
      expect(
        find.text('Read only, with the key the seller shared.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ObserverScreen),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      debugPrint('[e2e] 2. read both sides; the file shows, locked');

      // ── 3. A wrong key opens nothing and says so ───────────────────────
      final random = Random.secure();
      final wrong = List.generate(
        32,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await tester.tap(find.byTooltip('Paste a chat key'));
      await _paste(tester, wrong);
      await until(
        tester,
        find.textContaining('The key opens no message of this dispute since'),
        what: 'the wrong key refused',
      );
      debugPrint('[e2e] 3. a wrong key opens nothing, and says so');

      // ── 4. The right key, pasted, reads ─────────────────────────────────
      final field = find.descendant(
        of: find.byType(PasteKeyDialog),
        matching: find.byType(TextField),
      );
      tester.widget<TextField>(field).controller!.text = '  $key\n';
      await tester.pump();
      await tester.tap(find.text('Read the chat'));
      await untilTrue(
        tester,
        () => find.byType(PasteKeyDialog).evaluate().isEmpty,
        what: 'the right key accepted',
      );
      expect(_observed(buyerSaid), findsOneWidget);
      debugPrint('[e2e] 4. the pasted key reads the same chat');

      // ── 5. Refresh brings what they write next ──────────────────────────
      final later = 'Buyer to seller: any news? ($stamp)';
      await _partyRun(tester, _buyer, [
        '--peer',
        sellerPubkey,
        '--say',
        later,
      ]);
      await tester.tap(find.byTooltip('Refresh'));
      await until(tester, _observed(later), what: 'the new message');
      // Each message once, however many reads.
      expect(_observed(buyerSaid), findsOneWidget);
      debugPrint('[e2e] 5. a refresh read the new message, nothing twice');
    },
    skip:
        _relay.isEmpty ||
        _node.isEmpty ||
        _solver.isEmpty ||
        _solverPubkey.isEmpty ||
        _dispute.isEmpty ||
        _buyer.isEmpty ||
        _seller.isEmpty ||
        _party.isEmpty ||
        _blossom.isEmpty ||
        _files.isEmpty ||
        !Directory(_files).existsSync(),
  );
}
