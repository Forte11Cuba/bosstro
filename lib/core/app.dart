import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// Root widget: router, both themes (dark is the default, DS-THM-1) and
/// localization.
class BosstroApp extends StatefulWidget {
  const BosstroApp({
    super.key,
    this.initialLocation = AppRoute.pending,
    this.themeMode = ThemeMode.dark,
  });

  /// Where the router starts; tests open a tab directly.
  final String initialLocation;

  /// Dark is the default (DS-THM-1). A theme setting arrives with Settings;
  /// tests pass light to check the other theme.
  final ThemeMode themeMode;

  @override
  State<BosstroApp> createState() => _BosstroAppState();
}

class _BosstroAppState extends State<BosstroApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: widget.themeMode,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
