import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/settings/models/languages.dart';
import 'package:bosstro/features/settings/widgets/language_sheet.dart';
import 'package:bosstro/l10n/app_localizations.dart';

import '../../support/screen_harness.dart';

Future<void> _settings(
  WidgetTester tester, {
  FakeSettingsCore? core,
  List<Locale> system = const [Locale('es')],
  Brightness brightness = Brightness.dark,
  double textScale = 1,
}) => pumpApp(
  tester,
  location: AppRoute.settings,
  systemLocales: system,
  brightness: brightness,
  textScale: textScale,
  overrides: fakeCoreOverrides(settings: core),
);

/// Settings' title and tab, in the language on screen.
Finder _settingsIn(String language) => find.text(switch (language) {
  'en' => 'Settings',
  _ => 'Configuración',
});

Future<void> _openSheet(WidgetTester tester, String rowLabel) async {
  final row = find.text(rowLabel);
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  // Clear of the bottom bar, which would take the tap.
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(LanguageSheet), findsOneWidget);
}

Future<void> _pick(WidgetTester tester, String option) async {
  await tester.tap(
    find.descendant(
      of: find.byType(LanguageSheet),
      matching: find.text(option),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the languages the app ships', () {
    test('every one has its name, and English leads the fallback', () {
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          languageNames.keys,
          contains(locale.languageCode),
          reason: 'add ${locale.languageCode} to languageNames',
        );
      }
      // Flutter falls back to the first supported locale (l10n.yaml).
      expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    });

    test('a stored or device code reads as a shipped language, or none', () {
      expect(normalizeLanguage('es'), 'es');
      expect(normalizeLanguage('es-MX'), 'es');
      expect(normalizeLanguage('es_AR'), 'es');
      expect(normalizeLanguage('EN'), 'en');
      expect(normalizeLanguage('ja'), isNull);
      expect(normalizeLanguage(''), isNull);
      expect(normalizeLanguage(null), isNull);
    });

    test('the system gives its first shipped language, else English', () {
      expect(systemLanguage(const [Locale('ja'), Locale('es')]), 'es');
      expect(systemLanguage(const [Locale('es', 'MX')]), 'es');
      expect(systemLanguage(const [Locale('ja')]), 'en');
      expect(systemLanguage(const []), 'en');
    });
  });

  group('the system language, by default', () {
    testWidgets('a device in Spanish shows Spanish', (tester) async {
      await _settings(tester);
      expect(_settingsIn('es'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Idioma del sistema'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Idioma'), findsOneWidget);
    });

    testWidgets('the first language the app ships wins', (tester) async {
      await _settings(tester, system: const [Locale('ja'), Locale('es')]);
      expect(_settingsIn('es'), findsWidgets);
    });

    testWidgets('none shipped: English, never the first one alphabetically', (
      tester,
    ) async {
      await _settings(tester, system: const [Locale('ja')]);
      expect(_settingsIn('en'), findsWidgets);
    });
  });

  group('a chosen language', () {
    testWidgets('a saved one applies from the first frame', (tester) async {
      await _settings(tester, core: FakeSettingsCore(saved: 'en'));
      expect(_settingsIn('en'), findsWidgets);
    });

    testWidgets('a saved one the app no longer ships reads as the system\'s', (
      tester,
    ) async {
      await _settings(tester, core: FakeSettingsCore(saved: 'xx'));
      expect(_settingsIn('es'), findsWidgets);
    });

    testWidgets('choosing one applies at once and is kept; the system\'s '
        'comes back', (tester) async {
      final core = FakeSettingsCore();
      await _settings(tester, core: core);

      await _openSheet(tester, 'Idioma del sistema');
      // The system's language is named under its choice.
      expect(find.text('El de tu dispositivo: Español'), findsOneWidget);
      await _pick(tester, 'English');
      expect(find.byType(LanguageSheet), findsNothing);
      expect(_settingsIn('en'), findsWidgets);
      expect(core.writes, ['en']);

      await _openSheet(tester, 'English');
      await _pick(tester, 'System language');
      expect(_settingsIn('es'), findsWidgets);
      expect(core.writes, ['en', null]);
    });

    testWidgets('the language in use again changes nothing', (tester) async {
      final core = FakeSettingsCore(saved: 'es');
      await _settings(tester, core: core);
      await _openSheet(tester, 'Español');
      await _pick(tester, 'Español');
      expect(find.byType(LanguageSheet), findsNothing);
      expect(core.writes, isEmpty);
    });
  });

  // DS-A11Y-4: the row and the sheet at 320 dp, 2× text, Spanish, both
  // themes, with no overflow.
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('the language sheet fits, $theme', (tester) async {
      setSurface(tester);
      await _settings(tester, brightness: brightness, textScale: 2);
      expect(tester.takeException(), isNull);
      await _openSheet(tester, 'Idioma del sistema');
      expect(tester.takeException(), isNull);
      for (final code in appLanguages) {
        await tester.scrollUntilVisible(
          find.text(languageName(code)),
          100,
          scrollable:
              find
                  .descendant(
                    of: find.byType(LanguageSheet),
                    matching: find.byType(Scrollable),
                  )
                  .first,
        );
        expect(tester.takeException(), isNull, reason: code);
      }
    });
  }
}
