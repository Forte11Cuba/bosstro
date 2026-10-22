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
      final page = shell.bg;

      test('group headers sit on the page', () {
        expectAA('group header', pal.groupHeader, page);
      });

      test('the secret key field: text, placeholder and error', () {
        final field = flatten(pal.fieldFill, page);
        expectAA('typed key', shell.textPrimary, field);
        expectAA('placeholder', pal.placeholder, field);
        expectAA('error under the field', shell.dangerText, page);
      });

      test('Paste and Scan QR over their own fill on the page', () {
        expectAA('paste', shell.textBody, flatten(pal.buttonFill, page));
        expectAA('scan', shell.limeInk, flatten(pal.scanFill, page));
      });

      test('the warning note over its tint, on the page and on a card', () {
        expectAA('note on page', pal.warnInk, flatten(pal.warnBg, page));
        expectAA(
          'note on card',
          pal.warnInk,
          flatten(pal.warnBg, shell.surface),
        );
      });

      test('settings rows on a card', () {
        expectAA('row label', shell.textBody, shell.surface);
        expectAA('row value', shell.textSecondary, shell.surface);
        expectAA('log out', shell.dangerText, shell.surface);
      });
    });
  }
}
