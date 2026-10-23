import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_bubble.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/observer/screens/observer_screen.dart';
import 'package:bosstro/features/observer/services/observer_core.dart';
import 'package:bosstro/features/observer/widgets/observed_bubble.dart';

import '../../support/screen_harness.dart';

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';
final _now = DateTime.fromMillisecondsSinceEpoch(1700007200 * 1000);

/// The bubble's box: its fill and border.
BoxDecoration _box(WidgetTester tester, Finder bubble) =>
    tester
            .widget<Container>(
              find
                  .descendant(of: bubble, matching: find.byType(Container))
                  .first,
            )
            .decoration!
        as BoxDecoration;

/// The color of [label] inside [bubble].
Color? _label(WidgetTester tester, Finder bubble, String label) =>
    tester
        .widget<Text>(
          find.descendant(of: bubble, matching: find.text(label)).first,
        )
        .style
        ?.color;

Future<void> _pump(WidgetTester tester, Brightness brightness) async {
  setSurface(tester);
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
            sampleMessage(id: 'b1', content: 'Pagué.'),
            sampleMessage(
              id: 'y1',
              sender: ChatSender.you,
              content: 'Gracias.',
              createdAt: 1700005100,
            ),
          ],
        )
        ..set(
          _a,
          ChatParty.seller,
          messages: [
            sampleMessage(
              id: 's1',
              sender: ChatSender.seller,
              content: 'No llegó.',
            ),
          ],
        );
  final observer =
      FakeObserverCore()
        ..chats[_a] = sampleObserved(
          disclosures: [
            const KeyDisclosure(party: ChatParty.seller, sharedAt: 1700002800),
          ],
          messages: [
            observedMessage(id: 'o1', content: 'Enviado.'),
            observedMessage(
              id: 'o2',
              sender: ChatParty.seller,
              content: 'Nada aún.',
              createdAt: 1699999100,
            ),
          ],
        );
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
      ),
    ),
  );
}

Future<void> _segment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DetailSegments<DetailSection>),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Amendment 8: one hue per role on every screen, as Mostrix. You lime,
  // the buyer teal, the seller magenta; never red; always in words too.
  for (final brightness in Brightness.values) {
    final pal =
        brightness == Brightness.dark
            ? DisputesPalette.dark
            : DisputesPalette.light;

    testWidgets('each role keeps its hue in every chat, ${brightness.name}', (
      tester,
    ) async {
      await _pump(tester, brightness);

      await _segment(tester, 'Comprador');
      expect(tester.takeException(), isNull);
      Finder bubble(String id) => find.byWidgetPredicate(
        (w) => w is ChatBubble && w.message.id == id,
        skipOffstage: true,
      );
      expect(_box(tester, bubble('b1')).color, pal.buyerFill);
      expect(_box(tester, bubble('b1')).border!.top.color, pal.buyerBorder);
      expect(_label(tester, bubble('b1'), 'Comprador'), pal.buyerLabel);
      expect(_box(tester, bubble('y1')).color, pal.bubbleMineFill);
      expect(_label(tester, bubble('y1'), 'Tú'), pal.bubbleYouLabel);

      await _segment(tester, 'Vendedor');
      expect(tester.takeException(), isNull);
      expect(_box(tester, bubble('s1')).color, pal.sellerFill);
      expect(_label(tester, bubble('s1'), 'Vendedor'), pal.sellerLabel);

      // The chat between the parties: the same hues, buyer left, seller
      // right.
      openObserverScreen(tester.element(find.byType(IndexedStack)), _a);
      await tester.pumpAndSettle();
      expect(find.byType(ObserverScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Built ahead of the viewport too: [ensureVisible] scrolls to it.
      Finder observed(String id) => find.byWidgetPredicate(
        (w) => w is ObservedBubble && w.message.id == id,
        skipOffstage: false,
      );
      for (final (id, label, fill, ink) in [
        ('o1', 'Comprador', pal.buyerFill, pal.buyerLabel),
        ('o2', 'Vendedor', pal.sellerFill, pal.sellerLabel),
      ]) {
        await tester.ensureVisible(observed(id));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_box(tester, observed(id)).color, fill);
        expect(_label(tester, observed(id), label), ink);
      }
      double boxAt(String id) =>
          tester
              .getCenter(
                find
                    .descendant(
                      of: observed(id),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .dx;
      final buyerAt = boxAt('o1');
      final sellerAt = boxAt('o2');
      expect(buyerAt, lessThan(sellerAt), reason: 'buyer left, seller right');
    });
  }
}
