import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/utils/short_id.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// Label → value facts (DS-CMP-24) and the copyable id row (DS-CMP-22),
/// ported from ../app's `order_detail_cards.dart` and kept under the names
/// the design guide cites.

/// A block on the page: surface fill, hairline border, radius 18, no
/// elevation (DS-CMP-8). With [onTap] it is `Material` + `InkWell`, so the
/// ripple follows the radius.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// The hairline's color when it says something (the row open beside a
  /// list); the palette's `border` otherwise.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    if (onTap case final tap?) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.block),
        side: BorderSide(color: borderColor ?? pal.border),
      );
      return Material(
        color: pal.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tap,
          customBorder: shape,
          child: Container(
            width: double.infinity,
            padding: padding,
            child: child,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppRadius.block),
        border: Border.all(color: borderColor ?? pal.border),
      ),
      child: child,
    );
  }
}

/// Stacked `label → value` rows separated by hairlines.
class OrderDataCard extends StatelessWidget {
  const OrderDataCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final pal = DisputesPalette.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, thickness: 1, color: pal.rowDivider),
          ],
        ],
      ),
    );
  }
}

/// An [OrderDataCard] folded under a titled header, closed until [expanded]
/// opens it: facts the solver reads when needed, not every time. The header
/// is the 48-dp tap target and says whether it is open (DS-A11Y-1, DS-CMP-6);
/// the rows appear without an animation (DS-MOT-1).
class CollapsibleDataCard extends StatefulWidget {
  const CollapsibleDataCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
    this.expanded = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> rows;

  /// Whether it opens unfolded.
  final bool expanded;

  @override
  State<CollapsibleDataCard> createState() => _CollapsibleDataCardState();
}

class _CollapsibleDataCardState extends State<CollapsibleDataCard> {
  late bool _open = widget.expanded;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final rowPal = DisputesPalette.of(context);
    final header = Semantics(
      button: true,
      expanded: _open,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: pal.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: pal.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 24,
                  color: pal.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (_open)
            for (final row in widget.rows) ...[
              Divider(height: 1, thickness: 1, color: rowPal.rowDivider),
              row,
            ],
        ],
      ),
    );
  }
}

/// One row of the data card: a 16-dp icon, the label, and the value flush
/// right, 14 above and below.
class OrderDataRow extends StatelessWidget {
  const OrderDataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;

  /// When set, the whole row is the tap target.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      // Label and value each get up to half the row, so a long label (Spanish
      // at 2×) wraps instead of overflowing, and spaceBetween keeps the
      // value flush right whatever the label leaves unused.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: pal.textTertiary),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: pal.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: value),
        ],
      ),
    );
    if (onTap == null) return row;
    // A custom tappable is announced as a button (DS-A11Y-1).
    return Semantics(
      button: true,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: row,
      ),
    );
  }
}

/// Plain value text of a data row: in the figures face when [figures] (an
/// amount or a count).
class OrderDataValue extends StatelessWidget {
  const OrderDataValue(this.text, {super.key, this.figures = false});

  final String text;
  final bool figures;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: TextStyle(
        fontFamily: figures ? AppFonts.figures : null,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: pal.textStrong,
      ),
    );
  }
}

/// `09150348…99b5` with a copy icon; the whole row copies the full id
/// (DS-CMP-22). At least 48 high (DS-CMP-6).
class OrderIdRow extends StatelessWidget {
  const OrderIdRow({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      hint: l10n.copyIdHint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: OrderDataRow(
          icon: Icons.link_rounded,
          label: l10n.idLabel,
          onTap: () => copyId(context, id),
          value: OrderIdValue(id: id),
        ),
      ),
    );
  }
}

/// The value side of an id row: the short id in figures and the copy icon.
class OrderIdValue extends StatelessWidget {
  const OrderIdValue({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            shortOrderId(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.figures,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: pal.textBody,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.copy_rounded, size: 16, color: pal.limeIcon),
      ],
    );
  }
}

/// Copies the full [id] and confirms it (DS-CMP-22, DS-CMP-15).
void copyId(BuildContext context, String id) {
  Clipboard.setData(ClipboardData(text: id));
  HapticFeedback.selectionClick();
  showMostroSnackBar(context, AppLocalizations.of(context).copied);
}
