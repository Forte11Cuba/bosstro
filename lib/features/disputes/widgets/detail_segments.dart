import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';

/// One option of [DetailSegments].
class DetailSegment<T> {
  const DetailSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// The pill segmented control of the dispute detail (Info / Buyer / Seller),
/// after ../app's `PillSegmented`, on the disputes palette: every option
/// always visible, the chosen one tinted lime and named as selected, each a
/// 48-dp target (DS-CMP-6).
///
/// The segments share the width equally when their labels fit. When they do
/// not (large text in a long locale on a narrow phone), they keep their
/// natural width and wrap onto a second line, every one still in view: a
/// label is never shrunk, cut or scrolled away (DS-TYP-7).
class DetailSegments<T> extends StatelessWidget {
  const DetailSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    required this.semanticLabel,
  });

  final List<DetailSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// What the group is, for a screen reader.
  final String semanticLabel;

  static const double _gap = 4;
  static const double _hPad = 12;
  static const double _fontSize = 13;

  @override
  Widget build(BuildContext context) {
    final pal = DisputesPalette.of(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inner = constraints.maxWidth - 2 * _gap;
          final fits =
              !constraints.hasBoundedWidth || _naturalWidth(context) <= inner;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: pal.segmentTrack,
              // Two lines of pills read as a card, not as one pill.
              borderRadius: BorderRadius.circular(
                fits ? AppRadius.pill : AppRadius.block,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_gap),
              child:
                  fits
                      ? Row(
                        children: [
                          for (var i = 0; i < segments.length; i++) ...[
                            if (i > 0) const SizedBox(width: _gap),
                            Expanded(child: _tab(segments[i])),
                          ],
                        ],
                      )
                      : Wrap(
                        spacing: _gap,
                        runSpacing: _gap,
                        children: [for (final s in segments) _tab(s)],
                      ),
            ),
          );
        },
      ),
    );
  }

  Widget _tab(DetailSegment<T> segment) => _SegmentTab(
    label: segment.label,
    isSelected: segment.value == selected,
    onTap: () => onSelected(segment.value),
    horizontalPadding: _hPad,
    fontSize: _fontSize,
  );

  /// The width every label needs at the current text scale, with padding and
  /// gaps, in the selected (heavier) weight.
  double _naturalWidth(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var total = _gap * (segments.length - 1);
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(
          text: segment.label,
          style: DefaultTextStyle.of(
            context,
          ).style.copyWith(fontSize: _fontSize, fontWeight: FontWeight.w600),
        ),
        textScaler: scaler,
        textDirection: direction,
        maxLines: 1,
      )..layout();
      total += painter.width + 2 * _hPad + 2;
      painter.dispose();
    }
    return total;
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.horizontalPadding,
    required this.fontSize,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double horizontalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final pal = DisputesPalette.of(context);
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: DecoratedBox(
        // Both states carry the border (transparent when off), so a switch
        // never moves the height.
        decoration: BoxDecoration(
          color: isSelected ? pal.segmentActiveFill : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? pal.segmentActiveBorder : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? pal.segmentActiveInk : pal.segmentInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
