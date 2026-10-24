import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/observer/screens/observer_screen.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/features/observer/widgets/observed_bubble.dart';
import 'package:bosstro/features/observer/widgets/paste_key_dialog.dart';

import '../../support/screen_harness.dart';

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

/// Shared by the buyer on 14 Nov 2023 23:00 (local time of the test run).
const _sharedAt = 1700002800;

/// A key the test pastes (never a real one).
const _pastedKey =
    '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0';

/// The parties' chat, as the core would have read it.
List<ObservedMessage> _talk() => [
  observedMessage(
    id: 'o1',
    content: 'Te hice la transferencia hace una hora, mira el comprobante.',
    createdAt: _opened - 3600,
  ),
  observedMessage(
    id: 'o2',
    sender: ChatParty.seller,
    content: 'En mi banco no aparece nada todavía.',
    createdAt: _opened - 3000,
  ),
  observedMessage(
    id: 'o3',
    content: '{"type":"file_encrypted"}',
    createdAt: _opened - 2400,
    attachment: const ChatAttachment(
      kind: ChatAttachmentKind.file,
      fileName: 'comprobante-transferencia-bancaria.pdf',
      mimeType: 'application/pdf',
      size: 1468006,
    ),
  ),
];

/// A dispute this key holds; its observed chat as [chat] says.
FakeObserverCore _observer(ObservedChat chat) =>
    FakeObserverCore()..chats[_a] = chat;

ObservedChat _sharedByBuyer({List<ObservedMessage>? messages}) =>
    sampleObserved(
      disclosures: [
        const KeyDisclosure(party: ChatParty.buyer, sharedAt: _sharedAt),
      ],
      messages: messages ?? _talk(),
    );

Future<FakeDeviceSecurity> _pumpDetail(
  WidgetTester tester,
  FakeObserverCore observer, {
  Brightness brightness = Brightness.dark,
}) async {
  setSurface(tester);
  final device = FakeDeviceSecurity();
  final disputes =
      FakeDisputesCore()
        ..held = [sampleTaken(id: _a)]
        ..details[_a] = sampleDetail(id: _a);
  final chat =
      FakeChatCore()
        ..set(_a, ChatParty.buyer)
        ..set(_a, ChatParty.seller);
  await withClock(
    Clock.fixed(_now),
    () => pumpApp(
      tester,
      location: AppRoute.disputeDetail(_a),
      brightness: brightness,
      overrides: fakeCoreOverrides(
        disputes: disputes,
        chat: chat,
        observer: observer,
        device: device,
      ),
    ),
  );
  return device;
}

/// Scroll the Info list until [finder] is on screen, and let it settle
/// there (the last step animates).
Future<void> _scrollInfoTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable:
        find
            .descendant(
              of: find.byType(IndexedStack),
              matching: find.byType(Scrollable),
            )
            .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openObserver(WidgetTester tester) async {
  final read = find.text('Leer el chat entre las partes');
  await _scrollInfoTo(tester, read);
  await tester.tap(read);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('Info says who shared the chat key and when, $theme', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        _observer(_sharedByBuyer()),
        brightness: brightness,
      );
      await _scrollInfoTo(tester, find.text('Pegar una clave del chat'));
      expect(tester.takeException(), isNull);
      expect(find.text('Chat entre las partes'), findsOneWidget);
      expect(
        find.textContaining('El comprador compartió la clave del chat el'),
        findsOneWidget,
      );
      expect(find.text('Leer el chat entre las partes'), findsOneWidget);
    });

    testWidgets('without a key, Info offers only the paste, $theme', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        _observer(sampleObserved()),
        brightness: brightness,
      );
      await _scrollInfoTo(tester, find.text('Pegar una clave del chat'));
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Ninguna de las partes ha compartido'),
        findsOneWidget,
      );
      expect(find.text('Leer el chat entre las partes'), findsNothing);
    });

    testWidgets('the transcript: both sides, read only, secure, $theme', (
      tester,
    ) async {
      final observer = _observer(_sharedByBuyer());
      final device = await _pumpDetail(
        tester,
        observer,
        brightness: brightness,
      );
      await _openObserver(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ObserverScreen), findsOneWidget);
      // The relays are asked once, as the screen opens with a key known.
      expect(observer.reads, [_a]);
      expect(device.calls, contains('secure:true'));
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('Solo lectura, con la clave que compartió el comprador.'),
        findsOneWidget,
      );
      // The newest, a file: it shows, and cannot be opened.
      expect(
        find.text('comprobante-transferencia-bancaria.pdf'),
        findsOneWidget,
      );
      expect(find.textContaining('PDF'), findsOneWidget);
      expect(
        find.text('No se puede abrir con la clave del chat.'),
        findsOneWidget,
      );
      expect(
        find.text('Pide al comprador que te lo envíe en su chat contigo.'),
        findsOneWidget,
      );
      // Further up, the seller's and the buyer's, each named in words; they
      // fit too.
      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('En mi banco no aparece nada todavía.'),
        200,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Vendedor'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Te hice la transferencia'),
        200,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Comprador'), findsWidgets);

      // Refresh asks again.
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();
      expect(observer.reads, [_a, _a]);

      // Leaving lifts the secure flag.
      Navigator.of(tester.element(find.byType(ObserverScreen))).pop();
      await tester.pumpAndSettle();
      expect(device.calls.last, 'secure:false');
    });

    testWidgets('no key yet: the screen explains and offers the paste, '
        '$theme', (tester) async {
      final observer = _observer(sampleObserved());
      await _pumpDetail(tester, observer, brightness: brightness);
      final context = tester.element(find.byType(IndexedStack));
      openObserverScreen(context, _a);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Todavía no hay clave del chat'), findsOneWidget);
      expect(find.text('Pegar una clave del chat'), findsOneWidget);
      expect(observer.reads, isEmpty, reason: 'nothing to read with');
    });

    testWidgets('a key that opens nothing says so, with the date, $theme', (
      tester,
    ) async {
      final observer = _observer(_sharedByBuyer(messages: const []))
        ..readAnswer = ObserverError.keyOpensNothing;
      await _pumpDetail(tester, observer, brightness: brightness);
      await _openObserver(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.text('La clave no abre ningún mensaje de esta disputa'),
        findsOneWidget,
      );
      expect(find.textContaining('desde el 7 nov 2023'), findsOneWidget);
      // Not an empty chat shown as if it were one.
      expect(find.byType(ObservedBubble), findsNothing);
    });

    testWidgets('the paste dialog: hidden, checked, then read, $theme', (
      tester,
    ) async {
      final observer = _observer(sampleObserved())
        ..pasteAnswer = ObserverError.invalidKey;
      final device = await _pumpDetail(
        tester,
        observer,
        brightness: brightness,
      );
      final paste = find.text('Pegar una clave del chat');
      await _scrollInfoTo(tester, paste);
      await tester.tap(paste);
      await tester.pumpAndSettle();
      expect(find.byType(PasteKeyDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(device.calls, contains('secure:true'));

      // Obscured, with no way to show it back (so never selectable).
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
      expect(find.byTooltip('Mostrar la clave'), findsNothing);

      await tester.enterText(find.byType(TextField), 'no es una clave');
      await tester.tap(find.text('Leer el chat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Eso no es una clave del chat'),
        findsOneWidget,
      );
      // What crossed was wiped right after.
      expect(observer.pasted, ['no es una clave']);
      expect(observer.pastedBuffers.single.every((b) => b == 0), isTrue);

      observer.pasteAnswer = ObserverError.keyOpensNothing;
      await tester.enterText(find.byType(TextField), _pastedKey);
      await tester.tap(find.text('Leer el chat'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'La clave no abre ningún mensaje de esta disputa desde el '
          '7 nov 2023.',
        ),
        findsOneWidget,
      );

      observer.pasteAnswer = sampleObserved(
        hasPastedKey: true,
        messages: _talk(),
      );
      await tester.tap(find.text('Leer el chat'));
      await tester.pumpAndSettle();
      expect(find.byType(PasteKeyDialog), findsNothing);
      expect(find.byType(ObserverScreen), findsOneWidget);
      expect(
        find.text('Solo lectura, con una clave que pegaste.'),
        findsOneWidget,
      );
      expect(observer.pasted.last, _pastedKey);
    });

    testWidgets('a refresh that fails keeps what was read, $theme', (
      tester,
    ) async {
      final observer = _observer(_sharedByBuyer())
        ..readAnswer = ObserverError.fetchFailed;
      await _pumpDetail(tester, observer, brightness: brightness);
      await _openObserver(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ObservedBubble), findsWidgets);
      // Above the oldest message, in the same scroll.
      final banner = find.text(
        'No se pudo consultar a los relays. '
        'Revisa la conexión e inténtalo de nuevo.',
      );
      await tester.scrollUntilVisible(
        banner,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(banner, findsOneWidget);
    });
  }

  testWidgets('Paste fills the field from the clipboard', (tester) async {
    final observer = _observer(sampleObserved());
    await _pumpDetail(tester, observer);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData'
              ? <String, dynamic>{'text': '  Shared key: $_pastedKey  '}
              : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final paste = find.text('Pegar una clave del chat');
    await _scrollInfoTo(tester, paste);
    await tester.tap(paste);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pegar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pegar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Leer el chat'));
    await tester.pumpAndSettle();
    observer.pasteAnswer = sampleObserved(
      hasPastedKey: true,
      messages: _talk(),
    );
    await tester.tap(find.text('Leer el chat'));
    await tester.pumpAndSettle();
    expect(observer.pasted, ['Shared key: $_pastedKey']);
  });
}
