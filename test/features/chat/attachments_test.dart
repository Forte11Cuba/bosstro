import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/attachments/attachment_picker.dart';
import 'package:bosstro/features/chat/attachments/attachment_saver.dart';
import 'package:bosstro/features/chat/screens/attachment_viewer_screen.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/attachment_content.dart';
import 'package:bosstro/features/chat/widgets/upload_bubble.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';

import '../../support/screen_harness.dart';

const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);
const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';

/// A 1 × 1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

final _pdf = Uint8List.fromList(utf8.encode('%PDF-1.4\n%%EOF'));

/// Picks what the test says, without a platform picker.
class _FakePicker extends AttachmentPicker {
  _FakePicker(this.outcome);

  final PickOutcome outcome;
  final List<AttachmentSource> asked = [];

  @override
  bool get supportsCamera => true;

  @override
  Future<PickOutcome> pick(AttachmentSource source) async {
    asked.add(source);
    return outcome;
  }
}

/// Records what would reach the system's save dialog.
class _FakeSaver extends AttachmentSaver {
  final List<(String, int)> saved = [];

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    saved.add((fileName, bytes.length));
    return true;
  }
}

/// A dispute this key holds, whose buyer sent an image and a PDF, and the
/// solver an image of its own.
(FakeDisputesCore, FakeChatCore) _held({
  Map<String, Object> opened = const {},
}) {
  final disputes =
      FakeDisputesCore()
        ..held = [sampleTaken(id: _a)]
        ..details[_a] = sampleDetail(id: _a);
  final chat =
      FakeChatCore()
        ..set(
          _a,
          ChatParty.buyer,
          messages: [
            sampleMessage(
              id: 'img',
              content: '{}',
              attachment: sampleImage(name: 'comprobante-de-transferencia.jpg'),
            ),
            sampleMessage(
              id: 'pdf',
              content: '{}',
              createdAt: 1700005100,
              attachment: samplePdf(
                name: 'extracto-bancario-de-octubre-con-un-nombre-largo.pdf',
              ),
            ),
            sampleMessage(
              id: 'mine',
              sender: ChatSender.you,
              content: '{}',
              createdAt: 1700005200,
              attachment: sampleImage(name: 'captura.png', w: 400, h: 1600),
            ),
          ],
        )
        ..set(_a, ChatParty.seller);
  chat.opened.addAll(opened);
  return (disputes, chat);
}

OpenedAttachment _image(String name) => OpenedAttachment(
  bytes: _png,
  fileName: name,
  mimeType: 'image/png',
  isImage: true,
);

OpenedAttachment _file(String name) => OpenedAttachment(
  bytes: _pdf,
  fileName: name,
  mimeType: 'application/pdf',
  isImage: false,
);

Map<String, Object> _allOpen() => {
  'img': _image('comprobante-de-transferencia.jpg'),
  'pdf': _file('extracto-bancario-de-octubre-con-un-nombre-largo.pdf'),
  'mine': _image('captura.png'),
};

Future<void> _pump(
  WidgetTester tester,
  (FakeDisputesCore, FakeChatCore) cores, {
  Brightness brightness = Brightness.dark,
  List<Override> extra = const [],
  FakeDeviceSecurity? device,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: AppRoute.disputeDetail(_a),
    brightness: brightness,
    overrides: [
      ...fakeCoreOverrides(disputes: cores.$1, chat: cores.$2, device: device),
      ...extra,
    ],
    settle: false,
  ),
);

/// Settles what can settle: a loading image shimmers for ever.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openBuyer(WidgetTester tester) async {
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(DetailSegments<DetailSection>, skipOffstage: false),
      matching: find.text('Comprador'),
    ),
  );
  await _settle(tester);
}

Finder _shown(Finder finder) => find.descendant(
  of: find.byWidgetPredicate((w) => w is IndexedStack),
  matching: finder,
  skipOffstage: true,
);

/// Scroll the conversation until [finder] is wholly in view.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: _shown(find.byType(Scrollable)).first,
  );
  await tester.ensureVisible(finder);
  await _settle(tester);
}

void main() {
  // DS-A11Y-4: 320 dp, 2× text, Spanish, both themes, no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('image and PDF bubbles fit, previewed once verified, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final cores = _held(opened: _allOpen());
      await _pump(tester, cores, brightness: brightness);
      await _openBuyer(tester);
      expect(tester.takeException(), isNull);
      expect(_shown(find.byType(AttachmentImage)), findsWidgets);
      await _scrollTo(tester, find.byType(AttachmentFileCard));
      expect(tester.takeException(), isNull);
      // The PDF says what it is, and is not opened until saved.
      expect(find.textContaining('1,4 MB · PDF'), findsOneWidget);
      expect(find.byTooltip('Guardar el archivo'), findsOneWidget);
      expect(cores.$2.openedIds, isNot(contains('pdf')));
      // The oldest, further up.
      await _scrollTo(
        tester,
        find.byWidgetPredicate(
          (w) => w is AttachmentImage && w.reference.messageId == 'img',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(cores.$2.openedIds, containsAll(['img', 'mine']));
    });

    testWidgets('a file that fails its checks says so, $theme', (tester) async {
      setSurface(tester);
      await _pump(
        tester,
        _held(
          opened: {
            'img': ChatError.notVerified,
            'mine': ChatError.downloadFailed,
            'pdf': ChatError.notVerified,
          },
        ),
        brightness: brightness,
      );
      await _openBuyer(tester);
      expect(tester.takeException(), isNull);
      // The newest (a download that failed) offers a retry; a file that is
      // not the one named does not.
      expect(find.text('No se pudo descargar el archivo.'), findsOneWidget);
      expect(_shown(find.text('Reintentar')), findsOneWidget);
      await _scrollTo(tester, find.text('El archivo no se pudo verificar.'));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the composer attaches, and an upload shows and fails, $theme',
      (tester) async {
        setSurface(tester);
        final cores = _held(opened: _allOpen());
        final picker = _FakePicker(
          Picked(
            PickedAttachment(
              name: 'recibo-del-banco.pdf',
              size: _pdf.length,
              read: () async => _pdf,
            ),
          ),
        );
        cores.$2
          ..uploadError = ChatError.uploadFailed
          ..holdUploads = Completer<void>();
        await _pump(
          tester,
          cores,
          brightness: brightness,
          extra: [attachmentPickerProvider.overrideWithValue(picker)],
        );
        await _openBuyer(tester);
        await tester.tap(_shown(find.byTooltip('Adjuntar un archivo')));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Hacer una foto'), findsOneWidget);
        await tester.tap(find.text('Documento PDF'));
        await _settle(tester);
        // The confirmation names the file and the party, and fits.
        expect(tester.takeException(), isNull);
        expect(find.text('¿Enviar este archivo?'), findsOneWidget);
        expect(
          find.textContaining('se envía cifrado al comprador'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Enviar').last);
        await _settle(tester);
        expect(picker.asked, [AttachmentSource.pdf]);
        expect(find.byType(UploadBubble), findsOneWidget);
        expect(find.text('Cifrando y enviando…'), findsOneWidget);
        expect(tester.takeException(), isNull);

        cores.$2.holdUploads!.complete();
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('No enviado'), findsOneWidget);
        expect(find.text('Descartar'), findsOneWidget);

        // A retry that succeeds replaces the bubble with the message.
        cores.$2
          ..uploadError = null
          ..holdUploads = null;
        await tester.tap(
          find.descendant(
            of: find.byType(UploadBubble),
            matching: find.text('Reintentar'),
          ),
        );
        await _settle(tester);
        expect(find.byType(UploadBubble), findsNothing);
        expect(cores.$2.filesSent, ['recibo-del-banco.pdf']);
      },
    );

    testWidgets('the viewer fits and keeps the window secure, $theme', (
      tester,
    ) async {
      setSurface(tester);
      final device = FakeDeviceSecurity();
      await _pump(
        tester,
        _held(opened: _allOpen()),
        brightness: brightness,
        device: device,
      );
      await _openBuyer(tester);
      final image = find.byWidgetPredicate(
        (w) => w is AttachmentImage && w.reference.messageId == 'img',
      );
      await _scrollTo(tester, image);
      await tester.tap(image);
      await _settle(tester);
      expect(find.byType(AttachmentViewerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(device.calls, ['secure:true']);
      expect(find.byTooltip('Guardar'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AttachmentViewerScreen),
          matching: find.byIcon(Icons.arrow_back),
        ),
      );
      await _settle(tester);
      expect(device.calls, ['secure:true', 'secure:false']);
    });
  }

  testWidgets('Save hands the decrypted file to the save dialog', (
    tester,
  ) async {
    setSurface(tester);
    final saver = _FakeSaver();
    await _pump(
      tester,
      _held(opened: _allOpen()),
      extra: [attachmentSaverProvider.overrideWithValue(saver)],
    );
    await _openBuyer(tester);
    await _scrollTo(tester, find.byType(AttachmentFileCard));
    await tester.tap(find.byTooltip('Guardar el archivo'));
    await _settle(tester);
    expect(saver.saved, [
      ('extracto-bancario-de-octubre-con-un-nombre-largo.pdf', _pdf.length),
    ]);
    expect(find.text('Guardado'), findsOneWidget);
  });

  testWidgets('a file over 25 MB is refused before it is read', (tester) async {
    setSurface(tester);
    var read = false;
    final picker = _FakePicker(
      checkPicked(
        PickedAttachment(
          name: 'video.pdf',
          size: kMaxAttachmentBytes + 1,
          read: () async {
            read = true;
            return _pdf;
          },
        ),
      ),
    );
    await _pump(
      tester,
      _held(opened: _allOpen()),
      extra: [attachmentPickerProvider.overrideWithValue(picker)],
    );
    await _openBuyer(tester);
    await tester.tap(_shown(find.byTooltip('Adjuntar un archivo')));
    await _settle(tester);
    await tester.tap(find.text('Documento PDF'));
    await _settle(tester);
    expect(find.text('El archivo pasa de 25 MB.'), findsOneWidget);
    expect(read, isFalse);
    expect(find.byType(UploadBubble), findsNothing);
  });

  test('sizes read in the locale', () {
    expect(formatAttachmentSize(1468006, 'es'), '1,4 MB');
    expect(formatAttachmentSize(1468006, 'en'), '1.4 MB');
    expect(formatAttachmentSize(2000, 'es'), '2 KB');
  });

  test('a declared shape is clamped', () {
    expect(imageBubbleAspectRatio(1, 10000), 0.5);
    expect(imageBubbleAspectRatio(null, 3), 4 / 3);
    expect(imageBubbleAspectRatio(1600, 900), closeTo(1.78, 0.01));
  });
}
