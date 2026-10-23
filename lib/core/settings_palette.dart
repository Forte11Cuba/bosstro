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
    required this.fieldFill,
    required this.fieldBorder,
    required this.fieldFocusBorder,
    required this.placeholder,
    required this.buttonFill,
    required this.buttonBorder,
    required this.scanFill,
    required this.scanBorder,
    required this.warnBg,
    required this.warnBorder,
    required this.warnInk,
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

  /// The boxed field a key is pasted into (DS-CMP-11): ../app's invoice
  /// textarea.
  final Color fieldFill;
  final Color fieldBorder;
  final Color fieldFocusBorder;
  final Color placeholder;

  /// `Paste`, the neutral input action under a field.
  final Color buttonFill;
  final Color buttonBorder;

  /// `Scan QR`, the lime-tinted one.
  final Color scanFill;
  final Color scanBorder;

  /// The note that warns about the key: never the trading key, keep it
  /// private. Amber, a warning (DS-COL-9), never red: nothing failed.
  final Color warnBg;
  final Color warnBorder;
  final Color warnInk;

  static const dark = SettingsPalette(
    rowDivider: Color(0x0DFFFFFF), // white 5%
    groupHeader: Color(0xFF808A9E),
    chevron: Color(0xFF6C7789),
    dotOnline: Color(0xFF92D64F),
    dotOffline: Color(0xFF5D6879),
    fieldFill: Color(0xFF0F131C),
    fieldBorder: Color(0x0FFFFFFF), // white 6%
    fieldFocusBorder: Color(0x4792D64F), // rgba(146,214,79,0.28)
    placeholder: Color(0xFF7E899E),
    buttonFill: Color(0x0DFFFFFF), // white 5%
    buttonBorder: Color(0x1AFFFFFF), // white 10%
    scanFill: Color(0x1F92D64F), // rgba(146,214,79,0.12)
    scanBorder: Color(0x4792D64F), // rgba(146,214,79,0.28)
    warnBg: Color(0x12F2D14B), // rgba(242,209,75,0.07)
    warnBorder: Color(0x2EF2D14B), // rgba(242,209,75,0.18)
    warnInk: Color(0xFFF7DE72),
  );

  static const light = SettingsPalette(
    rowDivider: Color(0x1212161F), // ink 7%
    groupHeader: Color(0xFF5F6979),
    chevron: Color(0xFF8A94A6),
    dotOnline: Color(0xFF5C9130),
    dotOffline: Color(0xFF8A94A6),
    fieldFill: Color(0xFFFFFFFF),
    fieldBorder: Color(0x1412161F), // ink 8%
    fieldFocusBorder: Color(0x995C9130), // rgba(92,145,48,0.60)
    placeholder: Color(0xFF5F6979),
    buttonFill: Color(0x0A12161F), // ink 4%
    buttonBorder: Color(0x2412161F), // ink 14%
    scanFill: Color(0x3392D64F), // lime 20%
    scanBorder: Color(0x665C9130), // rgba(92,145,48,0.40)
    warnBg: Color(0x40F2D14B), // yellow 25%
    warnBorder: Color(0x73D8AF19), // rgba(216,175,25,0.45)
    warnInk: Color(0xFF7A5D00),
  );

  static SettingsPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
