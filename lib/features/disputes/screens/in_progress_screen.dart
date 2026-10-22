import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// In progress tab: the disputes this solver took. The list arrives in
/// phase 5; until then it is the empty state.
class InProgressScreen extends StatelessWidget {
  const InProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: ShellPalette.of(context).bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(title: l10n.inProgressTitle),
          Expanded(
            child: ListEmptyState(
              sticker: 'thinking',
              title: l10n.inProgressEmptyTitle,
              body: l10n.inProgressEmptyBody,
            ),
          ),
        ],
      ),
    );
  }
}
