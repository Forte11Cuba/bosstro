import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';

/// The version the fake Rust core reports.
const fakeAppVersion = '0.1.0';

/// Overrides for everything that would call into the native library, which
/// widget tests run without.
final fakeCoreOverrides = [
  appVersionProvider.overrideWithValue(fakeAppVersion),
];

/// Sets the test surface to [width] × [height] logical pixels.
void setSurface(
  WidgetTester tester, {
  double width = 320,
  double height = 640,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Pumps the whole app at [location], in [locale], [brightness] and
/// [textScale] — the DS-A11Y-4 conditions.
Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  Locale locale = const Locale('es'),
  Brightness brightness = Brightness.dark,
  double textScale = 2,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeCoreOverrides,
      child: BosstroApp(
        initialLocation: location,
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps [child] alone in a themed, localized app.
Future<void> pumpWidgetAlone(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeCoreOverrides,
      child: MaterialApp(
        theme:
            brightness == Brightness.dark
                ? buildDarkTheme()
                : buildLightTheme(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
