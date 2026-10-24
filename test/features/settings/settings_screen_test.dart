import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';

import '../../support/screen_harness.dart';

Future<void> _settings(WidgetTester tester) async {
  setSurface(tester, width: 400, height: 1600);
  await pumpApp(
    tester,
    location: AppRoute.settings,
    locale: const Locale('en'),
    textScale: 1,
  );
}

double _top(WidgetTester tester, Finder finder) => tester.getTopLeft(finder).dy;

Finder _version() => find.text('Bosstro $fakeAppVersion', findRichText: true);

void main() {
  testWidgets('the language first, the node, then the key with log out last', (
    tester,
  ) async {
    await _settings(tester);
    final app = _top(tester, find.text('APP'));
    final node = _top(tester, find.text('NODE'));
    final key = _top(tester, find.text('SOLVER KEY'));
    expect(app, lessThan(node));
    expect(node, lessThan(key));
    // The one destructive row closes the cards.
    expect(
      _top(tester, find.text('Log out')),
      greaterThan(_top(tester, find.text('Back up secret key'))),
    );
  });

  testWidgets('the version is a quiet line at the end, not a row', (
    tester,
  ) async {
    await _settings(tester);
    expect(_version(), findsOneWidget);
    expect(find.text('Version'), findsNothing, reason: 'no row label');
    expect(find.text('ABOUT'), findsNothing, reason: 'no group of its own');
    expect(
      _top(tester, _version()),
      greaterThan(_top(tester, find.text('Log out'))),
    );
    // Nothing to tap: no ink, no button.
    expect(
      find.ancestor(of: _version(), matching: find.byType(InkWell)),
      findsNothing,
    );
    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(_version())
          .getSemanticsData()
          .flagsCollection
          .isButton,
      isFalse,
    );
    semantics.dispose();
  });
}
