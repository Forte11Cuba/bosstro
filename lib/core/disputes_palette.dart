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
    required this.segmentTrack,
    required this.segmentActiveFill,
    required this.segmentActiveBorder,
    required this.segmentActiveInk,
    required this.segmentInk,
    required this.bubbleMineFill,
    required this.bubbleMineBorder,
    required this.bubblePartyFill,
    required this.bubblePartyBorder,
    required this.bubbleInk,
    required this.bubbleMeta,
    required this.bubbleYouLabel,
    required this.observedBuyerFill,
    required this.observedBuyerBorder,
    required this.observedBuyerLabel,
    required this.observedSellerFill,
    required this.observedSellerBorder,
    required this.observedSellerLabel,
    required this.composerFill,
    required this.composerBorder,
    required this.composerFocusBorder,
    required this.composerPlaceholder,
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

  /// The Info / Buyer / Seller control of the dispute detail: a pill track,
  /// the chosen segment tinted lime (as MostroP2P/app's `PillSegmented`).
  final Color segmentTrack;
  final Color segmentActiveFill;
  final Color segmentActiveBorder;
  final Color segmentActiveInk;
  final Color segmentInk;

  /// Chat bubbles. The solver's own sit on a lime tint, the party's on the
  /// card surface; the sender is always named in words too (DS-COL-10). The
  /// legacy purple and hue bubbles of MostroP2P/app are not used (amendment 2).
  final Color bubbleMineFill;
  final Color bubbleMineBorder;
  final Color bubblePartyFill;
  final Color bubblePartyBorder;

  /// Message text, on either bubble.
  final Color bubbleInk;

  /// Time and delivery, on either bubble. "Not sent" is not on the bubble:
  /// it sits under it, on the page, in the shell's `dangerText`.
  final Color bubbleMeta;

  /// The "You" sender label, on the solver's bubble.
  final Color bubbleYouLabel;

  /// The chat between the parties, read with a chat key (phase 5c): the
  /// buyer's bubbles on a lime tint, the seller's on the sell tint, as
  /// MostroP2P/app colors the two sides of an order (amendment 8 to DS-COL-9:
  /// here lime and sell name a side, not the solver's turn or a danger). The
  /// side is always named in words too (DS-COL-10). Text and time are
  /// [bubbleInk] and [bubbleMeta].
  final Color observedBuyerFill;
  final Color observedBuyerBorder;
  final Color observedBuyerLabel;
  final Color observedSellerFill;
  final Color observedSellerBorder;
  final Color observedSellerLabel;

  /// The message field (DS-CMP-11): boxed, radius 14.
  final Color composerFill;
  final Color composerBorder;
  final Color composerFocusBorder;
  final Color composerPlaceholder;

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
    segmentTrack: Color(0x0AFFFFFF), // white 4%
    segmentActiveFill: Color(0x2492D64F), // lime 14%
    segmentActiveBorder: Color(0x4D92D64F), // lime 30%
    segmentActiveInk: Color(0xFFC6F09A),
    segmentInk: Color(0xFF8B97AD),
    bubbleMineFill: Color(0x1F92D64F), // lime 12%
    bubbleMineBorder: Color(0x3392D64F), // lime 20%
    bubblePartyFill: Color(0xFF1A2030),
    bubblePartyBorder: Color(0x0FFFFFFF), // white 6%
    bubbleInk: Color(0xFFEEF1F6),
    bubbleMeta: Color(0xFF8B97AD),
    bubbleYouLabel: Color(0xFFC6F09A),
    observedBuyerFill: Color(0x1F92D64F), // lime 12%
    observedBuyerBorder: Color(0x3392D64F), // lime 20%
    observedBuyerLabel: Color(0xFFC6F09A),
    observedSellerFill: Color(0x1FFF8B8B), // sell 12%
    observedSellerBorder: Color(0x33FF8B8B), // sell 20%
    observedSellerLabel: Color(0xFFFFB4B4),
    composerFill: Color(0xFF1A2030),
    composerBorder: Color(0x14FFFFFF), // white 8%
    composerFocusBorder: Color(0x8092D64F), // lime 50%
    composerPlaceholder: Color(0xFF8B97AD),
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
    segmentTrack: Color(0x0F12161F), // ink 6%
    segmentActiveFill: Color(0x3392D64F), // lime 20%
    segmentActiveBorder: Color(0x665C9130), // rgba(92,145,48,0.40)
    segmentActiveInk: Color(0xFF3E6B1C),
    segmentInk: Color(0xFF5A6474),
    bubbleMineFill: Color(0x2492D64F), // lime 14%
    bubbleMineBorder: Color(0x4D5C9130), // rgba(92,145,48,0.30)
    bubblePartyFill: Color(0xFFFFFFFF),
    bubblePartyBorder: Color(0x1412161F), // ink 8%
    bubbleInk: Color(0xFF12161F),
    bubbleMeta: Color(0xFF5A6474),
    bubbleYouLabel: Color(0xFF3E6B1C),
    observedBuyerFill: Color(0x2492D64F), // lime 14%
    observedBuyerBorder: Color(0x4D5C9130), // rgba(92,145,48,0.30)
    observedBuyerLabel: Color(0xFF3E6B1C),
    observedSellerFill: Color(0x24FF8B8B), // sell 14%
    observedSellerBorder: Color(0x4D9A2F2A), // rgba(154,47,42,0.30)
    observedSellerLabel: Color(0xFF9A2F2A),
    composerFill: Color(0xFFFFFFFF),
    composerBorder: Color(0x1F12161F), // ink 12%
    composerFocusBorder: Color(0xFF5C9130),
    composerPlaceholder: Color(0xFF5A6474),
  );

  static DisputesPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
