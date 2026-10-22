import 'package:flutter/material.dart';

/// Tokens of the resolution confirmation — "Pay the buyer" / "Refund the
/// seller", the screen where sats move for good — added on top of
/// `ShellPalette`, whose `danger` / `onDanger` fill the destructive answer.
///
/// Red here is earned: the action cannot be undone (Bosstro amendment 3).
/// The banner that says so is a red tint, never a red fill behind body text.
/// `test/core/resolution_palette_contrast_test.dart` locks every text pair.
@immutable
class ResolutionPalette {
  const ResolutionPalette({
    required this.warningBg,
    required this.warningBorder,
    required this.warningInk,
    required this.recipientInk,
  });

  /// "This cannot be undone" banner.
  final Color warningBg;
  final Color warningBorder;
  final Color warningInk;

  /// Who gets the sats, named under the amount.
  final Color recipientInk;

  static const dark = ResolutionPalette(
    warningBg: Color(0x1FFF8B8B), // rgba(255,139,139,0.12)
    warningBorder: Color(0x47FF8B8B), // rgba(255,139,139,0.28)
    warningInk: Color(0xFFFF8B8B),
    recipientInk: Color(0xFFEEF1F6),
  );

  static const light = ResolutionPalette(
    warningBg: Color(0x1FC2403A), // rgba(194,64,58,0.12)
    warningBorder: Color(0x59C2403A), // rgba(194,64,58,0.35)
    // The canonical #C2403A is 4.4:1 over its own tint on white — darkened
    // just enough to pass AA there.
    warningInk: Color(0xFFA8262B),
    recipientInk: Color(0xFF12161F),
  );

  static ResolutionPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
