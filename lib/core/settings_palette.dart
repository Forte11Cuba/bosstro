import 'package:flutter/material.dart';

/// Tokens of settings, the node selector and the solver key screens, added
/// on top of `ShellPalette`, which it shares for surfaces and text roles.
///
/// Values are ../app's `SettingsPalette` for the same roles.
/// `test/core/settings_palette_contrast_test.dart` locks every text pair.
@immutable
class SettingsPalette {
  const SettingsPalette({
    required this.rowDivider,
    required this.groupHeader,
    required this.chevron,
    required this.dotOnline,
    required this.dotOffline,
  });

  /// Hairline between two rows of the same group card.
  final Color rowDivider;

  /// `ABOUT` / `NODE` above each group card.
  final Color groupHeader;

  /// Trailing `chevron_right` of a row that opens another screen.
  final Color chevron;

  /// A node or relay that answers, and one that does not. Never alone: a
  /// word goes with the dot (DS-COL-10).
  final Color dotOnline;
  final Color dotOffline;

  static const dark = SettingsPalette(
    rowDivider: Color(0x0DFFFFFF), // white 5%
    groupHeader: Color(0xFF808A9E),
    chevron: Color(0xFF6C7789),
    dotOnline: Color(0xFF92D64F),
    dotOffline: Color(0xFF5D6879),
  );

  static const light = SettingsPalette(
    rowDivider: Color(0x1212161F), // ink 7%
    groupHeader: Color(0xFF5F6979),
    chevron: Color(0xFF8A94A6),
    dotOnline: Color(0xFF5C9130),
    dotOffline: Color(0xFF8A94A6),
  );

  static SettingsPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
