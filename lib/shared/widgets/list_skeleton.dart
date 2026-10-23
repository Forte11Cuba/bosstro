import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The shimmer skeleton of a list that loads (DS-CMP-13), never a centered
/// spinner: [count] placeholder blocks of [rowHeight], with the card radius
/// and list spacing, in the inset tone pulsing one step lighter. From
/// ../app's `OrderListSkeleton`.
///
/// The pulse stops when the platform asks for no animations (DS-MOT-3).
/// Read as one [label] by screen readers.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    required this.label,
    this.count = 4,
    this.rowHeight = 76,
    this.padding = const EdgeInsets.symmetric(horizontal: redesignSidePadding),
  });

  final String label;
  final int count;
  final double rowHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          enabled: !MediaQuery.disableAnimationsOf(context),
          baseColor: Color.alphaBlend(pal.inset, pal.bg),
          highlightColor: Color.alphaBlend(pal.border, pal.bg),
          period: const Duration(milliseconds: 1800),
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius: BorderRadius.circular(AppRadius.block),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
