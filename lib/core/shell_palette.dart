import 'package:flutter/material.dart';

/// The base palette: page, cards, the bottom bar, app bars, modals and the
/// text roles every area shares. The area palettes ([DisputesPalette],
/// [ResolutionPalette], [SettingsPalette]) add their own tokens on top of it,
/// as `OrderBookPalette` is the base in ../app.
///
/// Values are the canonical ones of the design guide (§2.3), which ../app's
/// `OrderBookPalette` already holds. `ThemeData` is built from this palette
/// (`app_theme.dart`), so a widget that leaves a value to the theme still
/// gets it from here. Every text role / surface pair is locked by
/// `test/core/shell_palette_contrast_test.dart`.
@immutable
class ShellPalette {
  const ShellPalette({
    required this.bg,
    required this.surface,
    required this.surfaceNav,
    required this.inset,
    required this.border,
    required this.navBorder,
    required this.pressed,
    required this.lime,
    required this.onLime,
    required this.limeText,
    required this.limeInk,
    required this.limeIcon,
    required this.limeDot,
    required this.danger,
    required this.onDanger,
    required this.dangerText,
    required this.warnText,
    required this.neutralText,
    required this.neutralDot,
    required this.textPrimary,
    required this.textStrong,
    required this.textBody,
    required this.textSecondary,
    required this.textTertiary,
    required this.textFaint,
    required this.divider,
    required this.notif,
    required this.scrim,
    required this.ctaShadow,
  });

  /// Page background.
  final Color bg;

  /// Cards, rows, dialogs and sheets.
  final Color surface;

  /// Bottom bar and action bar.
  final Color surfaceNav;

  /// A well inside a card (translucent over [surface]).
  final Color inset;

  /// Card hairline.
  final Color border;

  /// Top edge of the bottom bar and the action bar.
  final Color navBorder;

  /// Ink highlight of a pressed row.
  final Color pressed;

  /// The one accent (DS-COL-3), and the ink that goes on it (DS-COL-4).
  final Color lime;
  final Color onLime;

  /// Lime as text on a surface; darkened in light, where lime is 1.76:1.
  final Color limeText;

  /// Soft accent ink: text on lime tints, chips.
  final Color limeInk;

  /// Lime icons on a surface (the copy glyph of an id row).
  final Color limeIcon;

  /// Lime dots and strokes.
  final Color limeDot;

  /// Danger fill (the destructive answer of a modal) and its ink.
  final Color danger;
  final Color onDanger;

  /// Danger and error text.
  final Color dangerText;

  /// Waiting and warning text.
  final Color warnText;

  /// Neutral, closed and inactive text, and its dot.
  final Color neutralText;
  final Color neutralDot;

  final Color textPrimary;
  final Color textStrong;
  final Color textBody;
  final Color textSecondary;
  final Color textTertiary;

  /// Meta text: times, captions.
  final Color textFaint;

  /// Sheet grabber, separators.
  final Color divider;

  /// Unread dot on a bottom-bar destination.
  final Color notif;

  /// Behind every dialog and sheet.
  final Color scrim;

  /// The primary call to action's glow, the one shadow allowed (DS-SHP-3).
  final List<BoxShadow> ctaShadow;

  static const dark = ShellPalette(
    bg: Color(0xFF12161F),
    surface: Color(0xFF1A2030),
    surfaceNav: Color(0xFF151A24),
    inset: Color(0x0AFFFFFF), // white 4%
    border: Color(0x0FFFFFFF), // white 6%
    navBorder: Color(0x12FFFFFF), // white 7%
    pressed: Color(0x0DFFFFFF), // white 5%
    lime: Color(0xFF92D64F),
    onLime: Color(0xFF12161F),
    limeText: Color(0xFF92D64F),
    limeInk: Color(0xFFC6F09A),
    limeIcon: Color(0xFFB7E38A),
    limeDot: Color(0xFF92D64F),
    danger: Color(0xFFFF8B8B),
    onDanger: Color(0xFF2A1015),
    dangerText: Color(0xFFFF8B8B),
    warnText: Color(0xFFF7DE72),
    neutralText: Color(0xFFA6B0C2),
    neutralDot: Color(0xFF5D6879),
    textPrimary: Color(0xFFEEF1F6),
    textStrong: Color(0xFFE4E9F2),
    textBody: Color(0xFFD6DCE8),
    textSecondary: Color(0xFF8B97AD),
    textTertiary: Color(0xFF7E899E),
    // ../app's handoff #6B7589 is 3.5:1 on the card — lightened to pass AA.
    textFaint: Color(0xFF808A9E),
    divider: Color(0xFF4A5364),
    notif: Color(0xFFFF6B6B),
    scrim: Color(0xD1080B10), // rgba(8,11,16,0.82)
    ctaShadow: [
      BoxShadow(
        color: Color(0x5992D64F), // lime 35%
        offset: Offset(0, 8),
        blurRadius: 22,
        spreadRadius: -8,
      ),
    ],
  );

  static const light = ShellPalette(
    bg: Color(0xFFF4F6F4),
    surface: Color(0xFFFFFFFF),
    surfaceNav: Color(0xFFFFFFFF),
    inset: Color(0x0A12161F), // ink 4%
    border: Color(0x1412161F), // ink 8%
    navBorder: Color(0x1412161F), // ink 8%
    pressed: Color(0x0A12161F), // ink 4%
    lime: Color(0xFF92D64F),
    onLime: Color(0xFF12161F),
    limeText: Color(0xFF3E6B1C),
    limeInk: Color(0xFF3E6B1C),
    limeIcon: Color(0xFF4E7D28),
    limeDot: Color(0xFF5C9130),
    danger: Color(0xFFFF8B8B),
    onDanger: Color(0xFF2A1015),
    dangerText: Color(0xFFC2403A),
    warnText: Color(0xFF7A5D00),
    neutralText: Color(0xFF3F4756),
    neutralDot: Color(0xFF8A94A6),
    textPrimary: Color(0xFF12161F),
    textStrong: Color(0xFF1E2430),
    textBody: Color(0xFF2A303C),
    textSecondary: Color(0xFF5A6474),
    textTertiary: Color(0xFF5F6979),
    textFaint: Color(0xFF636D7D),
    divider: Color(0xFFC3CAD6),
    notif: Color(0xFFE5484D),
    scrim: Color(0xD1080B10),
    ctaShadow: [
      BoxShadow(
        color: Color(0x4092D64F), // lime 25%
        offset: Offset(0, 8),
        blurRadius: 22,
        spreadRadius: -8,
      ),
    ],
  );

  static ShellPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
