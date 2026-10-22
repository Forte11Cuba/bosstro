import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Pending tab: the node's disputes waiting for a solver (kind 38386). The
/// list arrives in phase 3; until then it is the empty state.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: ShellPalette.of(context).bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(title: l10n.pendingTitle),
          Expanded(
            child: ListEmptyState(
              sticker: 'dispute',
              title: l10n.pendingEmptyTitle,
              body: l10n.pendingEmptyBody,
            ),
          ),
        ],
      ),
    );
  }
}
