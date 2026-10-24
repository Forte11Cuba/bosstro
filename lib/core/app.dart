import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/settings/providers/language_provider.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/l10n/app_localizations.dart';

/// Root widget: router, both themes (dark is the default, DS-THM-1) and
/// localization.
class BosstroApp extends ConsumerStatefulWidget {
  const BosstroApp({
    super.key,
    this.initialLocation = AppRoute.pending,
    this.themeMode = ThemeMode.dark,
  });

  /// Where the router starts; the redirect sends a solver without a key to
  /// Welcome. Tests open a screen directly.
  final String initialLocation;

  /// Dark is the default (DS-THM-1). A theme setting arrives with Settings;
  /// tests pass light to check the other theme.
  final ThemeMode themeMode;

  @override
  ConsumerState<BosstroApp> createState() => _BosstroAppState();
}

class _BosstroAppState extends ConsumerState<BosstroApp> {
  /// Whether a key is loaded, as the router listens to it.
  late final ValueNotifier<bool> _signedIn = ValueNotifier(
    ref.read(solverKeyProvider) != null,
  );

  late final GoRouter _router = buildRouter(
    signedIn: _signedIn,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    _signedIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(solverKeyProvider, (_, next) => _signedIn.value = next != null);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: widget.themeMode,
      // None chosen: Flutter follows the system's languages (English when
      // it ships none of them, `l10n.yaml`).
      locale: switch (ref.watch(languageProvider)) {
        null => null,
        final code => Locale(code),
      },
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
