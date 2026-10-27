import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';

/// A row of a settings group card that opens or does something: a 16-dp
/// icon, the label, an optional neutral value, and a trailing
/// `chevron_right` when it opens another screen or sheet (DS-CMP-27). The
/// whole row is the target, at least 48 tall (DS-CMP-6, DS-A11Y-1).
///
/// [danger] paints the icon and label in the danger ink, for an action that
/// removes something (log out); it always asks first (DS-CMP-20).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.valueIsData = false,
    this.opens = true,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;

  /// Keys, URLs and counts are set in the figures face, so they line up from
  /// row to row (DS-TYP-2); any other value is interface text.
  final bool valueIsData;

  /// Whether the row leads to another screen or sheet (the chevron).
  final bool opens;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    final settings = SettingsPalette.of(context);
    final ink = danger ? pal.dangerText : pal.textBody;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: danger ? pal.dangerText : pal.textTertiary,
                ),
                const SizedBox(width: 10),
                // As OrderDataRow, the read-only rows of the same cards: label
                // and value each get up to half the row, and spaceBetween
                // keeps the value flush right, against the chevron, whatever
                // the label leaves unused.
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 13, color: ink),
                        ),
                      ),
                      if (value case final text?) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily:
                                  valueIsData ? AppFonts.figures : AppFonts.ui,
                              fontSize: 12,
                              fontWeight:
                                  valueIsData
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                              color: pal.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (opens) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: settings.chevron,
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
