// The phase 5 attachments against a real mostrod, relay and Blossom server,
// all local, on Linux, by hand (README.md here): a party sends the solver an
// image and a PDF, the solver sees and saves them, and the solver sends a
// photo the party decrypts. The party is `rust/examples/chat_party.rs`, which
// writes and reads MostroP2P/app's format on its own (it shares no code with
// the app). Never against a real node or a public Blossom server.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/features/chat/attachments/attachment_saver.dart';
import 'package:bosstro/features/chat/screens/attachment_viewer_screen.dart';
import 'package:bosstro/features/chat/widgets/attachment_content.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/chat/widgets/upload_bubble.dart';
import 'package:bosstro/src/rust/api/chat.dart';

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

/// A directory with `party-photo.jpg`, `bank-statement.pdf` and
/// `solver-photo.jpg` (the JPEGs carrying EXIF with a GPS position).
const _files = String.fromEnvironment('E2E_FILES');

/// The system's save dialog cannot be driven: what Save hands it is kept.
class _KeptSaver extends AttachmentSaver {
  final Map<String, Uint8List> saved = {};

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    saved[fileName] = bytes;
    return true;
  }
}

/// The photo gallery, answered with the solver's test photo.
class _Gallery extends AttachmentPicker {
  @override
  bool get supportsCamera => false;

  @override
  Future<PickOutcome> pick(AttachmentSource source) async {
    final file = File('$_files/solver-photo.jpg');
    return checkPicked(
      PickedAttachment(
        name: 'solver-photo.jpg',
        size: await file.length(),
        read: file.readAsBytes,
      ),
    );
  }
}

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

/// The bubble of the attachment named [name], on screen.
Finder _bubbleOf(String name) => shown(
  find.byWidgetPredicate(
    (w) => w is ChatBubble && w.message.attachment?.fileName == name,
  ),
);

bool _contains(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'files both ways with a party, through a local Blossom server',
    (tester) async {
      expect(
        Platform.environment['BOSSTRO_TEST_BLOSSOM_SERVER'],
        _blossom,
        reason: 'the app must upload to and fetch from the local server',
      );
      final saver = _KeptSaver();
      await startApp(
        tester,
        relay: _relay,
        node: _node,
        solver: _solver,
        overrides: [
          attachmentSaverProvider.overrideWithValue(saver),
          attachmentPickerProvider.overrideWithValue(_Gallery()),
        ],
      );

      await takeDispute(tester, _dispute);
      await openDispute(tester, _dispute);
      await tester.tap(detailSegment('Buyer'));
      await tester.pump(const Duration(milliseconds: 500));

      // ── 1. The buyer sends a photo: shown, verified, saved whole ─────────
      final photo = await File('$_files/party-photo.jpg').readAsBytes();
      var run = await _partyRun(tester, _buyer, [
        '--blossom',
        _blossom,
        '--send-file',
        '$_files/party-photo.jpg',
      ]);
      expect(run.exitCode, 0, reason: run.stderr.toString());
      final photoBubble = _bubbleOf('party-photo.jpg');
      await until(tester, photoBubble, what: 'the buyer\'s photo');
      final preview = find.descendant(
        of: photoBubble,
        matching: find.byType(Image),
      );
      await until(tester, preview, what: 'the photo, decrypted');
      expect(
        find.descendant(
          of: photoBubble,
          matching: find.byType(AttachmentProblem),
        ),
        findsNothing,
      );
      debugPrint('[e2e] 1. the buyer\'s photo shows');
      await tester.tap(preview);
      await until(tester, find.byType(AttachmentViewerScreen));
      await tester.tap(find.byTooltip('Save'));
      await untilTrue(
        tester,
        () => saver.saved.containsKey('party-photo.jpg'),
        what: 'the photo saved',
      );
      expect(saver.saved['party-photo.jpg'], photo, reason: 'byte for byte');
      await tester.tap(
        find.descendant(
          of: find.byType(AttachmentViewerScreen),
          matching: find.byIcon(Icons.arrow_back),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      debugPrint('[e2e] 1. the photo, saved from the viewer, is the original');

      // ── 2. The buyer sends a PDF: named, saved whole ─────────────────────
      final pdf = await File('$_files/bank-statement.pdf').readAsBytes();
      run = await _partyRun(tester, _buyer, [
        '--blossom',
        _blossom,
        '--send-file',
        '$_files/bank-statement.pdf',
      ]);
      expect(run.exitCode, 0, reason: run.stderr.toString());
      final pdfBubble = _bubbleOf('bank-statement.pdf');
      await until(tester, pdfBubble, what: 'the buyer\'s PDF');
      expect(
        find.descendant(
          of: pdfBubble,
          matching: find.text('bank-statement.pdf'),
        ),
        findsOneWidget,
      );
      final save = find.descendant(
        of: pdfBubble,
        matching: find.byTooltip('Save the file'),
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await untilTrue(
        tester,
        () => saver.saved.containsKey('bank-statement.pdf'),
        what: 'the PDF saved',
      );
      expect(saver.saved['bank-statement.pdf'], pdf, reason: 'byte for byte');
      debugPrint('[e2e] 2. the buyer\'s PDF, saved, is the original');

      // ── 3. The solver sends a photo to the seller, who decrypts it ───────
      // "Saved" floats over the composer for its two seconds.
      await untilTrue(
        tester,
        () => find.byType(SnackBar).evaluate().isEmpty,
        what: 'the confirmation to go',
      );
      await tester.tap(detailSegment('Seller'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(shown(find.byTooltip('Attach a file')));
      await until(tester, find.text('Photo from the gallery'));
      await tester.tap(find.text('Photo from the gallery'));
      await until(tester, find.text('Send this file?'));
      await tester.tap(find.widgetWithText(FilledButton, 'Send').last);
      final mine = _bubbleOf('solver-photo.jpg');
      await until(tester, mine, seconds: 60, what: 'the solver\'s photo sent');
      expect(find.byType(UploadBubble), findsNothing);
      await untilTrue(
        tester,
        () =>
            tester.widget<ChatBubble>(mine).message.delivery ==
            ChatDelivery.sent,
        what: 'the photo delivered',
      );
      final out = '${Directory.systemTemp.path}/bosstro_e2e_received.jpg';
      run = await _partyRun(tester, _seller, ['--expect-file', out]);
      expect(run.exitCode, 0, reason: run.stderr.toString());
      final received = await File(out).readAsBytes();
      final original = await File('$_files/solver-photo.jpg').readAsBytes();
      expect(received.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: 'a JPEG');
      expect(_contains(original, 'BosstroTestCam'.codeUnits), isTrue);
      expect(
        _contains(received, 'BosstroTestCam'.codeUnits) ||
            _contains(received, 'Exif'.codeUnits),
        isFalse,
        reason: 'the EXIF (camera, GPS) did not leave the device',
      );
      debugPrint(
        '[e2e] 3. the seller decrypted the solver\'s photo '
        '(${received.length} bytes, no EXIF; sent ${original.length})',
      );
      await File(out).delete();
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
        _files.isEmpty,
  );
}
