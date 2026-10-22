import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/resolution_palette.dart';
import 'package:bosstro/core/shell_palette.dart';

import '../support/contrast.dart';

void main() {
  for (final (mode, pal, shell) in [
    ('dark', ResolutionPalette.dark, ShellPalette.dark),
    ('light', ResolutionPalette.light, ShellPalette.light),
  ]) {
    group('ResolutionPalette.$mode', () {
      for (final (surface, bg) in [
        ('page', shell.bg),
        ('card', shell.surface),
      ]) {
        test('the warning banner over its tint on the $surface', () {
          expectAA('warning', pal.warningInk, flatten(pal.warningBg, bg));
        });

        test('the recipient on the $surface', () {
          expectAA('recipient', pal.recipientInk, bg);
        });
      }
    });
  }
}
