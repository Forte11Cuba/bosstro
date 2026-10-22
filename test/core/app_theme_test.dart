import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_theme.dart';

/// The theme is built from the palette (Bosstro amendment 1), so a widget
/// that leaves a value to it never shows a second design system.
void main() {
  for (final (mode, theme, pal) in [
    ('dark', buildDarkTheme(), ShellPalette.dark),
    ('light', buildLightTheme(), ShellPalette.light),
  ]) {
    group('$mode theme', () {
      test('surfaces come from the palette', () {
        expect(theme.scaffoldBackgroundColor, pal.bg);
        expect(theme.appBarTheme.backgroundColor, pal.bg);
        expect(theme.colorScheme.surface, pal.surface);
        expect(theme.dialogTheme.backgroundColor, pal.surface);
        expect(theme.dialogTheme.barrierColor, pal.scrim);
        expect(theme.bottomSheetTheme.backgroundColor, pal.surface);
      });

      test('the accent is lime with its dark ink', () {
        expect(theme.colorScheme.primary, pal.lime);
        expect(theme.colorScheme.onPrimary, pal.onLime);
      });

      test('Outfit is the default family', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.ui);
      });

      test('the modal radius is the guide\'s 24', () {
        final shape = theme.dialogTheme.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppRadius.modal));
      });
    });
  }
}
