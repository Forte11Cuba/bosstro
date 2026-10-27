import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/settings/widgets/settings_row.dart';

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

  testWidgets('About is a row of the App group, after the language', (
    tester,
  ) async {
    // Arrange
    await _settings(tester);
    final language = _top(tester, find.text('Language'));
    final about = _top(tester, find.text('About'));
    final node = _top(tester, find.text('NODE'));

    // Act
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    // Assert
    expect(about, greaterThan(language));
    expect(about, lessThan(node));
    expect(find.text('Source code'), findsOneWidget, reason: 'About opened');
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
  testWidgets('every row ends at the same place: values flush right, then '
      'the chevron', (tester) async {
    await _settings(tester);
    final chevrons = find.byIcon(Icons.chevron_right_rounded);
    expect(chevrons, findsWidgets);
    final ends = {
      for (final element in chevrons.evaluate())
        tester.getTopRight(find.byWidget(element.widget)).dx,
    };
    expect(ends, hasLength(1), reason: 'one column of chevrons');

    // A value sits against its chevron, whatever its length.
    for (final value in ['System language', 'npub10elfc…zvjptg']) {
      final row = find.ancestor(
        of: find.text(value),
        matching: find.byType(SettingsRow),
      );
      expect(row, findsOneWidget, reason: value);
      final chevron = find.descendant(of: row, matching: chevrons);
      expect(
        tester.getTopLeft(chevron).dx - tester.getTopRight(find.text(value)).dx,
        lessThanOrEqualTo(12),
        reason: value,
      );
    }
  });

  testWidgets('a value reads in the interface face; a key, in the figures '
      'face', (tester) async {
    await _settings(tester);
    String? family(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontFamily;
    expect(family('System language'), anyOf(isNull, AppFonts.ui));
    expect(family('npub10elfc…zvjptg'), AppFonts.figures);
  });
}
