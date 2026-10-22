import 'package:flutter/material.dart';

/// Tokens of the disputes area — the Pending and In progress lists, the
/// dispute detail and its chats — added on top of `ShellPalette`.
///
/// Status follows the solver's turn, not the dispute (Bosstro amendment 3 to
/// DS-COL-9): in Bosstro every item is a dispute, so red would lose its
/// meaning. Lime is "you can act" (take it, or it is yours and your move);
/// neutral is "not yours" or "done". Red stays for danger and errors.
/// `test/core/disputes_palette_contrast_test.dart` locks every text pair.
@immutable
class DisputesPalette {
  const DisputesPalette({
    required this.rowDivider,
    required this.groupHeader,
    required this.chipTurnBg,
    required this.chipTurnBorder,
    required this.chipTurnInk,
    required this.chipTurnDot,
    required this.chipNeutralBg,
    required this.chipNeutralBorder,
    required this.chipNeutralInk,
    required this.chipNeutralDot,
  });

  /// Hairline between the rows of a data card.
  final Color rowDivider;

  /// Upper-case group titles above a list.
  final Color groupHeader;

  /// The solver's turn: `initiated` (take it), or `in-progress` taken by
  /// this solver.
  final Color chipTurnBg;
  final Color chipTurnBorder;
  final Color chipTurnInk;
  final Color chipTurnDot;

  /// Not the solver's: taken by another solver, settled, refunded, closed.
  final Color chipNeutralBg;
  final Color chipNeutralBorder;
  final Color chipNeutralInk;
  final Color chipNeutralDot;

  static const dark = DisputesPalette(
    rowDivider: Color(0x0DFFFFFF), // white 5%
    groupHeader: Color(0xFF808A9E),
    chipTurnBg: Color(0x2492D64F), // rgba(146,214,79,0.14)
    chipTurnBorder: Color(0x4D92D64F), // rgba(146,214,79,0.30)
    chipTurnInk: Color(0xFFC6F09A),
    chipTurnDot: Color(0xFF92D64F),
    chipNeutralBg: Color(0x0DFFFFFF), // white 5%
    chipNeutralBorder: Color(0x14FFFFFF), // white 8%
    chipNeutralInk: Color(0xFFA6B0C2),
    chipNeutralDot: Color(0xFF5D6879),
  );

  static const light = DisputesPalette(
    rowDivider: Color(0x1212161F), // ink 7%
    groupHeader: Color(0xFF5F6979),
    chipTurnBg: Color(0x3392D64F), // lime 20%
    chipTurnBorder: Color(0x665C9130), // rgba(92,145,48,0.40)
    chipTurnInk: Color(0xFF3E6B1C),
    chipTurnDot: Color(0xFF5C9130),
    chipNeutralBg: Color(0x0F12161F), // ink 6%
    chipNeutralBorder: Color(0x1712161F), // ink 9%
    chipNeutralInk: Color(0xFF3F4756),
    chipNeutralDot: Color(0xFF8A94A6),
  );

  static DisputesPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
