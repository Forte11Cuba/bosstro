import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/chat/widgets/chat_composer.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/features/observer/widgets/observer_card.dart';
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';

import '../../support/screen_harness.dart';

/// Opened 2023-11-14 22:13:20 UTC, taken an hour later; the tests' clock is
/// two hours after the opening.
const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
const _b = '1f2e3d4c-5b6a-4978-8695-a4b3c2d1e0f9';

/// A dispute this key holds, with a conversation on each side.
(FakeDisputesCore, FakeChatCore) _held({
  DisputeStatus status = DisputeStatus.inProgress,
  String? sellerPubkey =
      'd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeef',
}) {
  final disputes =
      FakeDisputesCore()
        ..held = [
          sampleTaken(id: _a),
          sampleTaken(id: _b, openedAt: 1700000500),
        ]
        ..details[_a] = sampleDetail(
          id: _a,
          status: status,
          sellerPubkey: sellerPubkey,
        )
        ..details[_b] = sampleDetail(id: _b);
  final closed = status != DisputeStatus.inProgress;
  final chat =
      FakeChatCore()
        ..set(
          _a,
          ChatParty.buyer,
          state: closed ? ChatChannelState.closed : ChatChannelState.open,
          messages: [
            sampleMessage(
              id: 'm1',
              content: 'No me ha llegado el pago, llevo una hora esperando.',
            ),
            sampleMessage(
              id: 'm2',
              sender: ChatSender.you,
              content: 'Envíame el comprobante, por favor.',
              createdAt: 1700005100,
            ),
            sampleMessage(
              id: 'm3',
              sender: ChatSender.you,
              content: '¿Sigues ahí?',
              createdAt: 1700005200,
              delivery: ChatDelivery.failed,
            ),
          ],
        )
        ..set(
          _a,
          ChatParty.seller,
          state:
              closed
                  ? ChatChannelState.closed
                  : sellerPubkey == null
                  ? ChatChannelState.noPartyKey
                  : ChatChannelState.open,
        )
        ..set(_b, ChatParty.buyer)
        ..set(_b, ChatParty.seller);
  return (disputes, chat);
}

Future<void> _pump(
  WidgetTester tester,
  (FakeDisputesCore, FakeChatCore) cores, {
  String location = AppRoute.inProgress,
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('es'),
  double textScale = 2,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: location,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    overrides: fakeCoreOverrides(disputes: cores.$1, chat: cores.$2),
  ),
);

/// Lets the providers' coalescing timers run, then the frame settle.
Future<void> _afterUpdates(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

Future<void> _openSegment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DetailSegments<DetailSection>),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

/// What the visible part of the detail shows: the IndexedStack keeps the
/// other parts built, so a plain finder would see them too.
Finder _shown(Finder finder) => find.descendant(
  of: find.byWidgetPredicate((w) => w is IndexedStack),
  matching: finder,
  skipOffstage: true,
);

/// Scroll the Info list until [finder] is built and on screen.
Future<void> _scrollInfoTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
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

/// The send button of the conversation on screen.
Finder _sendButton() => _shown(
  find.ancestor(
    of: find.byTooltip('Enviar'),
    matching: find.byType(IconButton),
  ),
);

void main() {
  // DS-A11Y-4: the detail and both chats at 320 dp (and a wide window),
  // 2× text, Spanish, in both themes, with no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('the detail fits: Info, Buyer and Seller, $theme', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(
        tester,
        _held(),
        location: AppRoute.disputeDetail(_a),
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Disputa'), findsOneWidget);
      // Folded until the solver opens it.
      expect(find.text('Información de la disputa'), findsOneWidget);
      expect(find.text('ID de la disputa'), findsNothing);
      await openDisputeFacts(tester);
      expect(find.text('ID de la disputa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Every row, down to the last, fits.
      for (final text in [
        '75.000 sats',
        '50 EUR',
        'Comisión del nodo',
        'Clave de trade del vendedor',
      ]) {
        await _scrollInfoTo(tester, find.text(text));
        final e = tester.takeException();
        expect(e, isNull, reason: 'down to $text');
      }

      await _openSegment(tester, 'Comprador');
      expect(tester.takeException(), isNull);
      // The newest at the bottom; the oldest further up, also fitting.
      expect(find.text('No enviado'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('No me ha llegado el pago'),
        // Reversed: older messages lie further along the scroll.
        200,
        scrollable: _shown(find.byType(Scrollable)).first,
      );
      expect(tester.takeException(), isNull);
      expect(_shown(find.byType(ChatComposer)), findsOneWidget);

      await _openSegment(tester, 'Vendedor');
      expect(tester.takeException(), isNull);
      expect(find.text('Sin mensajes con el vendedor'), findsOneWidget);
    });

    testWidgets('a closed dispute\'s chat fits, read only, $theme', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(
        tester,
        _held(status: DisputeStatus.settled),
        location: AppRoute.disputeDetail(_a),
        brightness: brightness,
      );
      const note = 'Esta disputa está cerrada. El chat es solo de lectura.';
      await _openSegment(tester, 'Comprador');
      expect(tester.takeException(), isNull);
      expect(find.text(note), findsOneWidget);
      expect(find.byType(ChatComposer, skipOffstage: false), findsNothing);
      // No retry on a closed dispute.
      expect(find.text('Reintentar'), findsNothing);
      await _openSegment(tester, 'Vendedor');
      expect(tester.takeException(), isNull);
      expect(find.text(note), findsOneWidget);
    });

    testWidgets('a wide window opens the detail full screen, $theme', (
      tester,
    ) async {
      setSurface(tester, width: 1280, height: 900);
      await _pump(tester, _held(), brightness: brightness);
      // No split view: the list alone, then the dispute on its own screen.
      expect(find.byType(DisputeDetailView), findsNothing);
      await tester.tap(find.byType(InProgressDisputeRow).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DisputeDetailScreen), findsOneWidget);
      expect(find.byType(InProgressDisputeRow), findsNothing);
      await _openSegment(tester, 'Comprador');
      expect(tester.takeException(), isNull);
      expect(find.byType(ChatBubble), findsWidgets);
    });
  }

  group('System navigation bar', () {
    testWidgets('the end of Info clears it', (tester) async {
      setSurface(tester, padding: systemBars);
      await _pump(tester, _held(), location: AppRoute.disputeDetail(_a));
      await expectClearOfNavBar(
        tester,
        scrollable:
            find
                .descendant(
                  of: find.byType(IndexedStack),
                  matching: find.byType(Scrollable),
                )
                .first,
        last: _shown(find.byType(ResolutionCard)),
      );
    });

    testWidgets('the composer clears it', (tester) async {
      setSurface(tester, padding: systemBars);
      await _pump(tester, _held(), location: AppRoute.disputeDetail(_a));
      await _openSegment(tester, 'Comprador');
      // The composer's own box reaches the edge (its SafeArea pads inside
      // it); its field is what must clear the bar.
      final field = find.descendant(
        of: _shown(find.byType(ChatComposer)),
        matching: find.byType(TextField),
      );
      expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(640 - 48));
    });
  });

  group('In progress', () {
    testWidgets('a tap on a phone pushes the detail', (tester) async {
      setSurface(tester);
      await _pump(tester, _held(), textScale: 1);
      await tester.tap(find.byType(InProgressDisputeRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(DisputeDetailScreen), findsOneWidget);
      expect(find.text('Información de la disputa'), findsOneWidget);
    });

    testWidgets('a row says it opens the dispute', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _held(), textScale: 1);
      final data =
          tester
              .getSemantics(find.byType(InProgressDisputeRow).first)
              .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hint, 'Abrir la disputa');
      semantics.dispose();
    });
  });

  group('Info', () {
    testWidgets('a dispute no longer this key\'s says so', (tester) async {
      final cores = _held();
      cores.$1.details.remove(_a);
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      expect(find.text('Esta disputa ya no es tuya'), findsOneWidget);
    });

    testWidgets('the facts come first, the resolution last', (tester) async {
      // Tall enough that the whole list is built.
      setSurface(tester, width: 600, height: 3000);
      await _pump(
        tester,
        _held(),
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await openDisputeFacts(tester);
      double top(Finder finder) => tester.getTopLeft(finder).dy;
      // One card holds the dispute, the order and the parties' keys.
      expect(_shown(find.byType(CollapsibleDataCard)), findsOneWidget);
      expect(_shown(find.byType(OrderDataCard)), findsNothing);
      expect(
        top(find.text('ID de la disputa')),
        lessThan(top(find.text('ID de la orden'))),
      );
      expect(
        top(find.text('Comisión del nodo')),
        lessThan(top(find.text('Clave de trade del comprador'))),
      );
      expect(
        top(find.text('Moneda')),
        lessThan(top(find.text('Monto en fiat'))),
      );
      expect(
        top(find.text('Clave de trade del comprador')),
        lessThan(top(_shown(find.byType(ObserverCard)))),
      );
      expect(
        top(_shown(find.byType(ObserverCard))),
        lessThan(top(_shown(find.byType(ResolutionCard)))),
      );
    });

    testWidgets('ids and keys copy whole', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await _pump(
        tester,
        _held(),
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await openDisputeFacts(tester);
      await _scrollInfoTo(tester, find.text('ID de la orden'));
      await tester.tap(find.text('ID de la orden'));
      await tester.pump();
      expect(copied, '5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d');
      await _scrollInfoTo(tester, find.text('Clave de trade del comprador'));
      await tester.tap(find.text('Clave de trade del comprador'));
      await tester.pump();
      expect(copied, startsWith('b0b1b2'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('Chat', () {
    testWidgets('every message names its sender in words', (tester) async {
      await _pump(
        tester,
        _held(),
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      final bubbles = find.byType(ChatBubble);
      expect(
        find.descendant(of: bubbles, matching: find.text('Comprador')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bubbles, matching: find.text('Tú')),
        findsNWidgets(2),
      );
    });

    testWidgets('a party\'s text is plain: no link, no markup', (tester) async {
      const text = 'Paga aquí: https://evil.example/pay **urgente** [ok](x)';
      final cores = _held();
      cores.$2.set(
        _a,
        ChatParty.buyer,
        messages: [sampleMessage(id: 'x', content: text)],
      );
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      final shown = find.text(text);
      expect(shown, findsOneWidget, reason: 'the text as written');
      // Nothing in it is tappable.
      final rich = tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.byType(RichText),
        ),
      );
      for (final r in rich) {
        r.text.visitChildren((span) {
          expect(span is TextSpan && span.recognizer != null, isFalse);
          return true;
        });
      }
    });

    testWidgets('a message is sent, trimmed, and shows as sending', (
      tester,
    ) async {
      final cores = _held();
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      final field = _shown(find.byType(TextField));
      // Nothing to send yet: the button is off.
      final send = _sendButton();
      expect(tester.widget<IconButton>(send).onPressed, isNull);
      await tester.enterText(field, '  Ya lo reviso.  ');
      await tester.pump();
      await tester.tap(send);
      await _afterUpdates(tester);
      expect(cores.$2.sent, ['Ya lo reviso.']);
      expect(find.textContaining('Enviando…'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    });

    testWidgets('a draft to one party survives a look at the other', (
      tester,
    ) async {
      await _pump(
        tester,
        _held(),
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      await tester.enterText(_shown(find.byType(TextField)), 'borrador');
      await _openSegment(tester, 'Info');
      await _openSegment(tester, 'Comprador');
      expect(find.text('borrador'), findsOneWidget);
    });

    testWidgets('a refused message says why and keeps the text', (
      tester,
    ) async {
      final cores = _held();
      cores.$2.error = ChatError.tooLong;
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      await tester.enterText(_shown(find.byType(TextField)), 'texto largo');
      await tester.pump();
      await tester.tap(_sendButton());
      await tester.pumpAndSettle();
      expect(
        find.text('El mensaje es demasiado largo. Divídelo en dos.'),
        findsOneWidget,
      );
      expect(find.text('texto largo'), findsOneWidget);

      cores.$2.error = ChatError.noRelays;
      await tester.tap(_sendButton());
      await tester.pumpAndSettle();
      expect(
        find.text('Sin conexión a ningún relay. Revisa tu conexión.'),
        findsOneWidget,
      );
    });

    testWidgets('a message not sent offers a retry, by hand', (tester) async {
      final cores = _held();
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Comprador');
      expect(find.text('No enviado'), findsOneWidget);
      expect(cores.$2.retried, isEmpty, reason: 'never by itself');
      await tester.tap(find.text('Reintentar'));
      await _afterUpdates(tester);
      expect(cores.$2.retried, ['m3']);
      expect(find.text('No enviado'), findsNothing);
      expect(find.textContaining('Enviando…'), findsOneWidget);
    });

    testWidgets('a new message from the core shows', (tester) async {
      final cores = _held();
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Vendedor');
      expect(find.text('Sin mensajes con el vendedor'), findsOneWidget);
      cores.$2.set(
        _a,
        ChatParty.seller,
        messages: [
          sampleMessage(
            id: 's1',
            sender: ChatSender.seller,
            content: 'Ya liberé.',
          ),
        ],
      );
      cores.$2.push(_a, ChatParty.seller);
      await _afterUpdates(tester);
      expect(find.text('Ya liberé.'), findsOneWidget);
    });

    testWidgets('an update for another conversation reads nothing new', (
      tester,
    ) async {
      final cores = _held();
      await _pump(
        tester,
        cores,
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Vendedor');
      cores.$2.set(
        _a,
        ChatParty.seller,
        messages: [sampleMessage(id: 's1', content: 'oculto')],
      );
      cores.$2.push(_b, ChatParty.seller);
      await _afterUpdates(tester);
      expect(find.text('oculto'), findsNothing);
    });

    testWidgets('a party whose key the node did not name has no chat', (
      tester,
    ) async {
      await _pump(
        tester,
        _held(sellerPubkey: null),
        location: AppRoute.disputeDetail(_a),
        textScale: 1,
      );
      await _openSegment(tester, 'Vendedor');
      expect(find.text('Sin chat con esta parte'), findsOneWidget);
      expect(_shown(find.byType(ChatComposer)), findsNothing);
    });

    testWidgets('times read today without a date, another day with it', (
      tester,
    ) async {
      final today = DateTime(2026, 10, 23, 14, 5);
      final at = today.millisecondsSinceEpoch ~/ 1000;
      expect(chatTimeLabel(at, today, 'es'), '14:05');
      expect(
        chatTimeLabel(at - 86400, today, 'es'),
        isNot('14:05'),
        reason: 'yesterday carries its date',
      );
      expect(chatTimeLabel(at - 86400, today, 'es'), contains('14:05'));
    });
  });
}
