import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/labeled_icon_action.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';

/// Above Pending once the node refused this key a dispute waiting for a
/// solver: the key is no solver here. The icon is red (amendment 3 keeps red
/// for this banner), and the words say it all (DS-COL-10). The fix is
/// switching to the solver's own node.
class NotSolverBanner extends StatelessWidget {
  const NotSolverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.gpp_bad_outlined,
                    size: 20,
                    color: pal.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notSolverTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: pal.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.notSolverBody,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: pal.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LabeledIconAction(
              icon: Icons.swap_horiz_rounded,
              label: l10n.switchNodeAction,
              onPressed: () => context.push(AppRoute.settingsNode),
            ),
          ),
        ],
      ),
    );
  }
}
