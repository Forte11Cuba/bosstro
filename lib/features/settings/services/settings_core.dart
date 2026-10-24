import 'package:bosstro/src/rust/api/settings.dart' as settings_api;

/// The app's settings the Rust core keeps (`rust/src/api/settings.rs`). An
/// interface so widget tests, which run without the native library, drive a
/// fake.
abstract interface class SettingsCore {
  /// The language chosen for the app, or null to follow the system's.
  Future<String?> language();

  /// Keep [code] as the app's language, or follow the system's with null.
  Future<void> setLanguage(String? code);
}

class RustSettingsCore implements SettingsCore {
  const RustSettingsCore();

  @override
  Future<String?> language() => settings_api.getLanguage();

  @override
  Future<void> setLanguage(String? code) =>
      settings_api.setLanguage(code: code);
}
