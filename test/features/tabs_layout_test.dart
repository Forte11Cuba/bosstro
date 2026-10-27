import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

import '../support/screen_harness.dart';

/// DS-A11Y-4: every screen at 2× text, 320 dp wide, in the longest locale
/// (Spanish), in both themes, without overflow.
void main() {
  for (final location in AppRoute.tabs) {
    for (final brightness in Brightness.values) {
      testWidgets('$location fits at 320 dp, 2× text, es, ${brightness.name}', (
        tester,
      ) async {
        setSurface(tester);
        await pumpApp(tester, location: location, brightness: brightness);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the bottom bar switches tabs', (tester) async {
    setSurface(tester, width: 400, height: 800);
    await pumpApp(
      tester,
      location: AppRoute.pending,
      locale: const Locale('en'),
      textScale: 1,
    );
    expect(find.text('Pending disputes'), findsOneWidget);

    await tester.tap(find.text('My disputes'));
    await tester.pumpAndSettle();
    expect(find.text('Your disputes'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('every tab title sits at the same height, with an action '
      'beside it or not', (tester) async {
    // Wide enough for Recover to stay on the title's line in the test font.
    setSurface(tester, width: 600, height: 800);
    await pumpApp(
      tester,
      location: AppRoute.pending,
      locale: const Locale('en'),
      textScale: 1,
    );
    // The header's title is its first text, whatever the copy says.
    Rect title() => tester.getRect(
      find
          .descendant(of: find.byType(TabHeader), matching: find.byType(Text))
          .first,
    );
    expect(find.text('Pending disputes'), findsOneWidget);
    final pending = title();

    await tester.tap(find.text('My disputes'));
    await tester.pumpAndSettle();
    // Recover sits beside this title, a 48-dp target.
    final recover = tester.getCenter(find.text('Recover'));
    expect(recover.dy, closeTo(title().center.dy, 1));
    expect(title().top, pending.top);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(title().top, pending.top);
  });

  testWidgets('a data row puts its value flush right (DS-CMP-24)', (
    tester,
  ) async {
    setSurface(tester, width: 400, height: 800);
    await pumpApp(
      tester,
      location: AppRoute.settings,
      locale: const Locale('en'),
      textScale: 1,
      overrides: fakeCoreOverrides(
        disputes: FakeDisputesCore()..status = SolverStatus.yes,
      ),
    );
    // "Solver on this node: Yes". Side inset 18, the card's 1-px border,
    // card padding 14.
    expect(tester.getRect(find.text('Yes')).right, 400 - 18 - 1 - 14);
  });

  testWidgets('empty lists explain themselves (DS-CMP-14)', (tester) async {
    setSurface(tester, width: 400, height: 800);
    await pumpApp(
      tester,
      location: AppRoute.pending,
      locale: const Locale('en'),
      textScale: 1,
    );
    expect(find.text('No disputes waiting'), findsOneWidget);
    expect(find.textContaining('waiting for a solver'), findsOneWidget);
  });

  testWidgets('the app bar says no node is selected, in words', (tester) async {
    setSurface(tester, width: 400, height: 800);
    await pumpApp(
      tester,
      location: AppRoute.pending,
      locale: const Locale('en'),
      textScale: 1,
      overrides: fakeCoreOverrides(nodes: FakeNodesCore()),
    );
    expect(find.text('No node selected'), findsOneWidget);
  });
}
