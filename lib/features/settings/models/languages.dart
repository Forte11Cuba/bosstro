import 'dart:ui';

import 'package:bosstro/l10n/app_localizations.dart';

/// The name of every language the app ships, in its own language, in the
/// order the language sheet lists them.
///
/// Only the names live here: which languages exist comes from the ARB files
/// (`AppLocalizations.supportedLocales`), and a test fails while a language
/// has no name here. Portuguese is Brazil's, as ../app's.
const Map<String, String> languageNames = {
  'en': 'English',
  'es': 'Español',
  'it': 'Italiano',
  'fr': 'Français',
  'de': 'Deutsch',
  'nl': 'Nederlands',
  'pt': 'Português (Brasil)',
};

/// The language codes the app ships, in [languageNames] order; one without a
/// name yet goes last, under its code.
final List<String> appLanguages = () {
  final shipped = {
    for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
  };
  return [
    for (final code in languageNames.keys)
      if (shipped.contains(code)) code,
    for (final code in shipped)
      if (!languageNames.containsKey(code)) code,
  ];
}();

/// [code]'s name in its own language, or the code itself.
String languageName(String code) => languageNames[code] ?? code;

/// [code] as a language the app ships (`es-MX` reads `es`), or null: the
/// system's language.
String? normalizeLanguage(String? code) {
  final base = (code ?? '').split(RegExp('[-_]')).first.toLowerCase();
  return appLanguages.contains(base) ? base : null;
}

/// The language the system's [preferred] locales give the app: the first one
/// it ships, else English. What Flutter picks when no language is chosen
/// (`preferred-supported-locales` in `l10n.yaml` puts English first).
String systemLanguage(List<Locale> preferred) {
  for (final locale in preferred) {
    if (appLanguages.contains(locale.languageCode)) return locale.languageCode;
  }
  return 'en';
}
