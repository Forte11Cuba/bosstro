import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/utils/short_id.dart';
import 'package:bosstro/shared/widgets/bottom_nav_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// The three-tab shell: the tab app bar on top, the active tab, and the
/// bottom bar (Pending · In progress · Settings).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ShellPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeNodeProvider);
    final entry = ref.watch(activeNodeEntryProvider);
    final link = ref.watch(relayLinkProvider);

    final (status, label) = switch ((active, link?.state)) {
      (null, _) => (NodeLinkStatus.none, null),
      (_, ConnectionState.online) => (
        NodeLinkStatus.online,
        l10n.linkOnline(link!.connected, link.total),
      ),
      (_, ConnectionState.offline) => (
        NodeLinkStatus.offline,
        l10n.linkOffline,
      ),
      // Reconnecting, or the relay list still loading.
      _ => (NodeLinkStatus.connecting, l10n.linkConnecting),
    };

    return Scaffold(
      backgroundColor: pal.bg,
      body: Column(
        children: [
          TabAppBar(
            nodeName:
                active == null
                    ? null
                    : entry != null
                    ? nodeDisplayName(entry)
                    : shortOrderId(active),
            status: status,
            statusLabel: label,
          ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: shell.currentIndex,
        onSelect:
            (index) => shell.goBranch(
              index,
              // A tap on the active tab returns it to its root.
              initialLocation: index == shell.currentIndex,
            ),
      ),
    );
  }
}
