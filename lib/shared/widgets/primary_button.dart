import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The one primary call to action of a screen state (DS-CMP-3): filled lime,
/// `onLime` ink, radius 16, 15/w600, vertical padding 14. The label stays on
/// one line and shrinks to fit rather than breaking a word (DS-TYP-7).
///
/// [busy] shows the button's own spinner and keeps its size (DS-CMP-13).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final enabled = onPressed != null && !busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pageCta),
        boxShadow: enabled ? pal.ctaShadow : const [],
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: pal.lime,
          foregroundColor: pal.onLime,
          disabledBackgroundColor: pal.lime.withValues(alpha: 0.35),
          disabledForegroundColor: pal.onLime.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pageCta),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child:
            busy
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: pal.onLime,
                  ),
                )
                : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1),
                ),
      ),
    );
  }
}

/// The outlined secondary of a page (DS-CMP-4): the primary's shape, the
/// `border` token and `textBody` ink, 15/w500. For a second path, not a way
/// out — leaving without consequence is a [TextLink] (DS-CMP-20).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: pal.textBody,
        side: BorderSide(color: pal.border),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pageCta),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }
}

/// A way out that undoes nothing (DS-CMP-20): a centred text link in
/// `textSecondary` under the screen's actions, at least 48 tall (DS-CMP-6).
class TextLink extends StatelessWidget {
  const TextLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: pal.textSecondary,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// The bar pinned under a screen (DS-SPC-5): nav surface, hairline on top,
/// padding 12 / 18 / 18, inside the bottom safe area. It holds actions only.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pal.surfaceNav,
        border: Border(top: BorderSide(color: pal.navBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            redesignSidePadding,
            12,
            redesignSidePadding,
            redesignSidePadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
