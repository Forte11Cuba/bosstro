import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/settings/models/languages.dart';
import 'package:bosstro/features/settings/services/settings_core.dart';

final settingsCoreProvider = Provider<SettingsCore>(
  (ref) => const RustSettingsCore(),
);

/// The language chosen for the app (`es`, `de`, …), or null while it follows
/// the system's. `main` reads the saved one before the first frame and
/// overrides the initial value, so the app never opens in one language and
/// turns to another.
final languageProvider = NotifierProvider<LanguageNotifier, String?>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<String?> {
  LanguageNotifier([this._initial]);

  final String? _initial;

  /// A saved language the app no longer ships reads as the system's.
  @override
  String? build() => normalizeLanguage(_initial);

  /// Show the app in [code], or in the system's language with null, and
  /// keep the choice. It applies at once; one the core could not save lasts
  /// until the app stops.
  Future<void> choose(String? code) async {
    final language = normalizeLanguage(code);
    state = language;
    try {
      await ref.read(settingsCoreProvider).setLanguage(language);
    } catch (e) {
      debugPrint('[settings] language not saved: $e');
    }
  }
}
