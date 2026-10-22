import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';

/// What a status chip says about the solver's turn (Bosstro amendment 3).
enum StatusChipKind {
  /// The solver can act: take it, or it is theirs. Lime.
  turn,

  /// Not the solver's, or done. Neutral.
  neutral,
}

/// The status chip (DS-CMP-9): a pill with a 6-px dot and an upper-case
/// 10-sp label, padded 8 × 4, 6 between dot and label, tinted from the
/// disputes palette. The label is always there: color is never the only
/// signal (DS-COL-10).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.kind});

  final String label;
  final StatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final pal = DisputesPalette.of(context);
    final (bg, border, ink, dot) = switch (kind) {
      StatusChipKind.turn => (
        pal.chipTurnBg,
        pal.chipTurnBorder,
        pal.chipTurnInk,
        pal.chipTurnDot,
      ),
      StatusChipKind.neutral => (
        pal.chipNeutralBg,
        pal.chipNeutralBorder,
        pal.chipNeutralInk,
        pal.chipNeutralDot,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
