import 'package:bosstro/features/settings/services/settings_core.dart';

/// [SettingsCore] in Dart: the language kept in a field.
class FakeSettingsCore implements SettingsCore {
  FakeSettingsCore({this.saved});

  /// The language the core holds; null: the system's.
  String? saved;

  /// Every language written, in order.
  final List<String?> writes = [];

  @override
  Future<String?> language() async => saved;

  @override
  Future<void> setLanguage(String? code) async {
    writes.add(code);
    saved = code;
  }
}
