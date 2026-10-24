import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';

import '../../support/screen_harness.dart';

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';

Future<void> _pump(
  WidgetTester tester,
  String? previous, {
  Brightness brightness = Brightness.dark,
}) => withClock(
  Clock.fixed(DateTime.fromMillisecondsSinceEpoch(1700007200000)),
  () => pumpApp(
    tester,
    location: AppRoute.disputeDetail(_a),
    brightness: brightness,
    overrides: fakeCoreOverrides(
      disputes:
          FakeDisputesCore()
            ..held = [sampleTaken(id: _a)]
            ..details[_a] = sampleDetail(id: _a, orderPreviousStatus: previous),
      chat:
          FakeChatCore()
            ..set(_a, ChatParty.buyer)
            ..set(_a, ChatParty.seller),
    ),
  ),
);

/// Scroll Info to its "Status before the dispute" row.
Future<void> _toRow(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Estado antes de la disputa'),
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

void main() {
  // DS-A11Y-4: at 320 dp, 2× text, Spanish, both themes, no overflow.
  for (final brightness in Brightness.values) {
    testWidgets('fiat sent before the dispute, ${brightness.name}', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(tester, 'fiat-sent', brightness: brightness);
      await _toRow(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Fiat enviado'), findsOneWidget);
    });
  }

  testWidgets('active before the dispute', (tester) async {
    await _pump(tester, 'active');
    await _toRow(tester);
    expect(find.text('Activa'), findsOneWidget);
  });

  testWidgets('a take that did not keep it reads not known', (tester) async {
    await _pump(tester, null);
    await _toRow(tester);
    expect(find.text('Fiat enviado'), findsNothing);
    expect(find.text('Activa'), findsNothing);
  });
}
