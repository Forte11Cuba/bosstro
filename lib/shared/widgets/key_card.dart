import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';

/// A key shown whole, in monospace, on a card: the place it must be read
/// whole (DS-CMP-22) — an nsec to write down, an npub to compare.
///
/// The whole card copies it when [onCopy] is set, with a visible copy icon
/// (DS-CMP-22) and button semantics (DS-A11Y-1).
class KeyCard extends StatelessWidget {
  const KeyCard({
    super.key,
    required this.label,
    required this.value,
    this.onCopy,
    this.copyLabel,
  });

  /// What the key is ("Secret key", "npub"), above it.
  final String label;
  final String value;
  final VoidCallback? onCopy;

  /// The copy action's name for a screen reader.
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: pal.textSecondary),
              ),
              const SizedBox(height: 6),
              SelectableText(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 13,
                  height: 1.45,
                  color: pal.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Icon(Icons.copy_rounded, size: 16, color: pal.limeIcon),
          ),
        ],
      ],
    );
    if (onCopy == null) return SurfaceCard(child: content);
    return Semantics(
      button: true,
      label: copyLabel,
      child: Material(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppRadius.block),
        child: InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(AppRadius.block),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.block),
              border: Border.all(color: pal.border),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
