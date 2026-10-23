import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Pending tab: the node's disputes waiting for a solver (kind 38386). The
/// list arrives in phase 3; until then it is the empty state. Before a node
/// is chosen it says so, with the way to choose one (D5).
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasNode = ref.watch(activeNodeProvider) != null;
    return ColoredBox(
      color: ShellPalette.of(context).bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(title: l10n.pendingTitle),
          Expanded(
            child:
                hasNode
                    ? ListEmptyState(
                      sticker: 'dispute',
                      title: l10n.pendingEmptyTitle,
                      body: l10n.pendingEmptyBody,
                    )
                    : ListEmptyState(
                      sticker: 'thinking',
                      title: l10n.pendingNoNodeTitle,
                      body: l10n.pendingNoNodeBody,
                      action: PrimaryButton(
                        label: l10n.pendingNoNodeAction,
                        onPressed: () => context.push(AppRoute.settingsNode),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
