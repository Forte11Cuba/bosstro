import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';

/// A note that warns, in the body after the content it is about (the shape
/// of DS-CMP-25's `ExplanatoryNote`, in the warning's amber): a 14-dp icon,
/// 8 before 12-sp text at height 1.45, on a tint with a hairline, radius 12,
/// padding 14 × 12. The icon is decoration; the text says it all
/// (DS-COL-10).
class WarningNote extends StatelessWidget {
  const WarningNote({
    super.key,
    required this.text,
    this.icon = Icons.warning_amber_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pal = SettingsPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: pal.warnBg,
        border: Border.all(color: pal.warnBorder),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(icon, size: 14, color: pal.warnInk),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, height: 1.45, color: pal.warnInk),
            ),
          ),
        ],
      ),
    );
  }
}
