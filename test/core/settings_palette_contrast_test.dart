import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/core/shell_palette.dart';

import '../support/contrast.dart';

void main() {
  for (final (mode, pal, shell) in [
    ('dark', SettingsPalette.dark, ShellPalette.dark),
    ('light', SettingsPalette.light, ShellPalette.light),
  ]) {
    group('SettingsPalette.$mode', () {
      test('group headers sit on the page', () {
        expectAA('group header', pal.groupHeader, shell.bg);
      });
    });
  }
}
