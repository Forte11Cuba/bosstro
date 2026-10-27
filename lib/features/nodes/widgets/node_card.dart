import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/features/nodes/widgets/node_avatar.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/utils/short_id.dart';

/// One node of the selector, trimmed from MostroP2P/app's `NodeCard` to what a
/// solver picks a node by: its face and name, whether it is a trusted
/// community or one they added, its region, its short pubkey, and which one
/// is active. The order-book figures of MostroP2P/app's card (liquidity, fee,
/// currencies) are left out: a solver does not choose where to trade.
///
/// The whole card selects the node; the info button opens its instance info.
/// The active node has a lime border, a filled radio and an `ACTIVE` chip —
/// the word, never the color alone (DS-COL-10).
class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.entry,
    required this.selected,
    required this.onSelect,
    required this.onInfo,
  });

  final MostroNodeEntry entry;

  /// Painted as the chosen one: the active node, or the one just tapped.
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = ShellPalette.of(context);
    final pal = SettingsPalette.of(context);
    final name = nodeDisplayName(entry);
    final place = regionPlace(entry.region);
    final flag = regionFlag(entry.region);
    // The place is text; the short key a figure, as MostroP2P/app sets it.
    final where = [
      // Many kind 0 names carry the flag already (`Kmbalache 🇨🇺`).
      if (flag != null && !name.contains(flag)) flag,
      if (place != null && place != name) place,
    ];

    return Material(
      color: shell.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.block),
        side: BorderSide(
          color: selected ? pal.cardBorderSelected : pal.cardBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: InkWell(
                onTap: onSelect,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
                  child: Row(
                    children: [
                      _Radio(selected: selected),
                      const SizedBox(width: 12),
                      NodeAvatar(entry: entry),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: shell.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  for (final part in where)
                                    TextSpan(text: '$part · '),
                                  TextSpan(
                                    text: shortOrderId(entry.pubkey),
                                    style: const TextStyle(
                                      fontFamily: AppFonts.figures,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: shell.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Chip(
                                  label:
                                      entry.isTrusted
                                          ? l10n.nodeChipTrusted
                                          : l10n.nodeChipCustom,
                                  trusted: entry.isTrusted,
                                ),
                                if (entry.isActive)
                                  _Chip(
                                    label: l10n.nodeChipActive,
                                    trusted: true,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: l10n.nodeInfoTooltip,
              onPressed: onInfo,
              icon: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: shell.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selection ring: filled lime for the chosen node. Decorative — the
/// card's `selected` semantics and the `ACTIVE` chip say it.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final shell = ShellPalette.of(context);
    final pal = SettingsPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? shell.lime : pal.radioBorder,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child:
            selected
                ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: shell.lime,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
      ),
    );
  }
}

/// `TRUSTED`, `ADDED BY YOU`, `ACTIVE`: a pill with an upper-case 10-sp label.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.trusted});

  final String label;

  /// Lime-tinted (trusted, active) or neutral (the solver's own node).
  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final shell = ShellPalette.of(context);
    final pal = SettingsPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trusted ? pal.trustedBg : pal.buttonFill,
        border: Border.all(
          color: trusted ? pal.trustedBorder : pal.buttonBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: trusted ? pal.trustedInk : shell.textBody,
        ),
      ),
    );
  }
}
