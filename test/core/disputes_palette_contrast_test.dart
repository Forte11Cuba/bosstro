import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/core/shell_palette.dart';

import '../support/contrast.dart';

void main() {
  for (final (mode, pal, shell) in [
    ('dark', DisputesPalette.dark, ShellPalette.dark),
    ('light', DisputesPalette.light, ShellPalette.light),
  ]) {
    group('DisputesPalette.$mode', () {
      test('group headers sit on the page', () {
        expectAA('group header', pal.groupHeader, shell.bg);
      });

      for (final (surface, bg) in [
        ('page', shell.bg),
        ('card', shell.surface),
      ]) {
        test('status chips over their own fill on the $surface', () {
          expectAA('turn', pal.chipTurnInk, flatten(pal.chipTurnBg, bg));
          expectAA(
            'neutral',
            pal.chipNeutralInk,
            flatten(pal.chipNeutralBg, bg),
          );
        });
      }
    });
  }
}
