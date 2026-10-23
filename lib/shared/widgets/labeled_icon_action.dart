import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';

/// An action that reads as a link with an icon: the icon and its label,
/// never the icon alone, in lime ink, a 48-dp target (DS-CMP-6, DS-CMP-7).
/// A screen's own action in its [TabHeader] (Recover a dispute), or the fix
/// a banner offers (Switch node).
class LabeledIconAction extends StatelessWidget {
  const LabeledIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: pal.limeIcon),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: pal.limeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
