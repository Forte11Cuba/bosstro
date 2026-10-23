import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/resolution/screens/resolution_screen.dart';
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';

import '../../support/screen_harness.dart';

const _opened = 1700000000;
final _now = DateTime.fromMillisecondsSinceEpoch((_opened + 7200) * 1000);

const _a = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c';

/// A dispute this key holds, open, on a node that uses bonds or not.
FakeDisputesCore _held({required bool bonds}) =>
    FakeDisputesCore()
      ..held = [sampleTaken(id: _a)]
      ..details[_a] = sampleDetail(id: _a, bondsEnabled: bonds);

Future<void> _pump(
  WidgetTester tester,
  FakeDisputesCore core, {
  Brightness brightness = Brightness.dark,
}) => withClock(
  Clock.fixed(_now),
  () => pumpApp(
    tester,
    location: AppRoute.disputeDetail(_a),
    brightness: brightness,
    overrides: fakeCoreOverrides(
      disputes: core,
      chat:
          FakeChatCore()
            ..set(_a, ChatParty.buyer)
            ..set(_a, ChatParty.seller),
    ),
  ),
);

Finder _info() =>
    find
        .descendant(
          of: find.byType(IndexedStack),
          matching: find.byType(Scrollable),
        )
        .first;

/// Open the confirmation of [action] from the Info segment.
Future<void> _open(WidgetTester tester, String action) async {
  final button = find.descendant(
    of: find.byType(ResolutionCard),
    matching: find.text(action),
  );
  await tester.scrollUntilVisible(button, 200, scrollable: _info());
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _scrollScreenTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable:
        find
            .descendant(
              of: find.byType(ResolutionScreen),
              matching: find.byType(Scrollable),
            )
            .first,
  );
  await tester.pumpAndSettle();
}

/// The confirmation's red answer.
Finder _answer(String label) => find.descendant(
  of: find.byType(ResolutionScreen),
  matching: find.widgetWithText(FilledButton, label),
);

/// The bond option row that says [label] (its radio, words and dots).
Finder _option(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell));

/// Whether [label]'s radio is the chosen one.
bool _chosen(WidgetTester tester, String label) =>
    find
        .descendant(
          of: _option(label),
          matching: find.byIcon(Icons.radio_button_checked_rounded),
        )
        .evaluate()
        .isNotEmpty;

void main() {
  testWidgets('a node without bonds offers no choice and sends none', (
    tester,
  ) async {
    final core = _held(bonds: false);
    await _pump(tester, core);
    await _open(tester, 'Pagar al comprador');
    expect(find.text('Fianzas'), findsNothing);
    expect(find.text('No penalizar'), findsNothing);
    await _scrollScreenTo(
      tester,
      find.textContaining('Las fianzas, si las hay'),
    );
    await tester.tap(_answer('Pagar al comprador'));
    await tester.pumpAndSettle();
    expect(core.bonds, [BondSlash.noSlash]);
  });

  // DS-A11Y-4: the new part of the screen at 320 dp, 2× text, Spanish, both
  // themes, with no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('a node with bonds: four choices, none by default, $theme', (
      tester,
    ) async {
      setSurface(tester);
      await _pump(tester, _held(bonds: true), brightness: brightness);
      await _open(tester, 'Devolver al vendedor');
      await _scrollScreenTo(tester, find.text('Penalizar a los dos'));
      expect(tester.takeException(), isNull);
      for (final label in [
        'No penalizar',
        'Penalizar al comprador',
        'Penalizar al vendedor',
        'Penalizar a los dos',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(_chosen(tester, 'No penalizar'), isTrue);
      expect(_chosen(tester, 'Penalizar al vendedor'), isFalse);
      // The old note gives way to the choice.
      expect(find.textContaining('Las fianzas, si las hay'), findsNothing);
    });
  }

  testWidgets('the chosen slash goes with the request and is told after', (
    tester,
  ) async {
    final core = _held(bonds: true)..resolveOutcome = ResolveOutcome.paidBuyer;
    await _pump(tester, core);
    await _open(tester, 'Pagar al comprador');
    await _scrollScreenTo(tester, find.text('Penalizar al vendedor'));
    await tester.tap(_option('Penalizar al vendedor'));
    await tester.pumpAndSettle();
    expect(_chosen(tester, 'Penalizar al vendedor'), isTrue);
    expect(_chosen(tester, 'No penalizar'), isFalse);
    await tester.tap(_answer('Pagar al comprador'));
    await tester.pumpAndSettle();

    expect(core.bonds, [BondSlash.seller]);
    expect(find.text('Resuelta: pagaste al comprador'), findsOneWidget);
    expect(find.text('Se penalizó la fianza del vendedor.'), findsOneWidget);
  });

  testWidgets('a party with no bond: nothing resolved, choose again', (
    tester,
  ) async {
    final core = _held(bonds: true)
      ..resolveOutcome = ResolveOutcome.bondNotPosted;
    await _pump(tester, core);
    await _open(tester, 'Devolver al vendedor');
    await _scrollScreenTo(tester, find.text('Penalizar a los dos'));
    await tester.tap(_option('Penalizar a los dos'));
    await tester.pumpAndSettle();
    await tester.tap(_answer('Devolver al vendedor'));
    await tester.pumpAndSettle();

    expect(core.bonds, [BondSlash.both]);
    expect(find.text('Esa parte no depositó fianza'), findsOneWidget);
    expect(find.text('Resuelta: devolviste al vendedor'), findsNothing);
    await tester.tap(find.text('Elegir otra opción'));
    await tester.pumpAndSettle();

    // Back on the confirmation, the choice as it was, to change it.
    await _scrollScreenTo(tester, find.text('Penalizar a los dos'));
    expect(_chosen(tester, 'Penalizar a los dos'), isTrue);
    await _scrollScreenTo(tester, find.text('Penalizar al comprador'));
    await tester.tap(_option('Penalizar al comprador'));
    await tester.pumpAndSettle();
    core.resolveOutcome = ResolveOutcome.refundedSeller;
    await tester.tap(_answer('Devolver al vendedor'));
    await tester.pumpAndSettle();
    expect(core.bonds, [BondSlash.both, BondSlash.buyer]);
    expect(find.text('Se penalizó la fianza del comprador.'), findsOneWidget);
  });

  testWidgets('a closed dispute tells which bonds were slashed', (
    tester,
  ) async {
    final core =
        FakeDisputesCore()
          ..closed = [
            sampleTaken(
              id: _a,
              status: DisputeStatus.settled,
              resolvedAs: ResolvedAs.paidBuyer,
            ),
          ]
          ..details[_a] = sampleDetail(
            id: _a,
            status: DisputeStatus.settled,
            resolvedAs: ResolvedAs.paidBuyer,
            bondSlash: BondSlash.seller,
            bondsEnabled: true,
          );
    await _pump(tester, core);
    await tester.scrollUntilVisible(
      find.text('Penalizar al vendedor'),
      200,
      scrollable: _info(),
    );
    expect(find.text('Fianzas'), findsOneWidget);
    expect(find.text('Penalizar al vendedor'), findsOneWidget);
  });

  testWidgets('screen readers hear one group of choices', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _held(bonds: true));
    await _open(tester, 'Pagar al comprador');
    await _scrollScreenTo(tester, find.text('Penalizar al comprador'));
    expect(
      tester.getSemantics(_option('Penalizar al comprador')),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
        isButton: true,
        hasTapAction: true,
        label:
            'Penalizar al comprador. El comprador pierde su fianza; el vendedor puede reclamar su parte.',
      ),
    );
    handle.dispose();
  });
}
