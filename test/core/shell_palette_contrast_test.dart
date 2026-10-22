import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/shell_palette.dart';

import '../support/contrast.dart';

/// Every text role of the base palette against the surfaces it renders on,
/// in both themes (DS-COL-6).
void main() {
  for (final (mode, pal) in [
    ('dark', ShellPalette.dark),
    ('light', ShellPalette.light),
  ]) {
    group('ShellPalette.$mode', () {
      for (final (surface, bg) in [
        ('page', pal.bg),
        ('card', pal.surface),
        ('nav', pal.surfaceNav),
      ]) {
        test('text roles on the $surface', () {
          expectAA('textPrimary', pal.textPrimary, bg);
          expectAA('textStrong', pal.textStrong, bg);
          expectAA('textBody', pal.textBody, bg);
          expectAA('textSecondary', pal.textSecondary, bg);
          expectAA('textTertiary', pal.textTertiary, bg);
          expectAA('textFaint', pal.textFaint, bg);
          expectAA('limeText', pal.limeText, bg);
          expectAA('limeInk', pal.limeInk, bg);
          expectAA('dangerText', pal.dangerText, bg);
          expectAA('warnText', pal.warnText, bg);
          expectAA('neutralText', pal.neutralText, bg);
        });
      }

      test('accent and danger fills carry their dark inks (DS-COL-4)', () {
        expectAA('onLime on lime', pal.onLime, pal.lime);
        expectAA('onDanger on danger', pal.onDanger, pal.danger);
      });
    });
  }

  test('there is exactly one accent (DS-COL-3)', () {
    const lime = Color(0xFF92D64F);
    expect(ShellPalette.dark.lime, lime);
    expect(ShellPalette.light.lime, lime);
    expect(ShellPalette.dark.onLime, const Color(0xFF12161F));
  });
}
