import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/settings/widgets/settings_row.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/features/solver_key/widgets/key_widgets.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/utils/short_id.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Settings tab: the active node and its relays, the solver key (npub,
/// backup, log out) and the app's version. Permission and trusted senders
/// arrive with their phases.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final settings = SettingsPalette.of(context);
    final key = ref.watch(solverKeyProvider);
    final active = ref.watch(activeNodeProvider);
    final entry = ref.watch(activeNodeEntryProvider);
    final link = ref.watch(relayLinkProvider);

    return ColoredBox(
      color: pal.bg,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          TabHeader(title: l10n.settingsTitle),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: redesignSidePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GroupHeader(
                  title: l10n.settingsGroupNode,
                  color: settings.groupHeader,
                ),
                const SizedBox(height: 8),
                OrderDataCard(
                  rows: [
                    SettingsRow(
                      icon: Icons.dns_outlined,
                      label: l10n.settingsNode,
                      value:
                          active == null
                              ? l10n.settingsNodeNone
                              : entry != null
                              ? nodeDisplayName(entry)
                              : shortOrderId(active),
                      onTap: () => context.push(AppRoute.settingsNode),
                    ),
                    if (active != null)
                      SettingsRow(
                        icon: Icons.info_outline_rounded,
                        label: l10n.settingsNodeInfo,
                        onTap: () => context.push(AppRoute.nodeInfo(active)),
                      ),
                    SettingsRow(
                      icon: Icons.cell_tower_rounded,
                      label: l10n.settingsRelays,
                      value:
                          link == null
                              ? null
                              : l10n.settingsRelaysValue(
                                link.connected,
                                link.total,
                              ),
                      onTap: () => context.push(AppRoute.relays),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (key != null) ...[
                  GroupHeader(
                    title: l10n.settingsGroupKey,
                    color: settings.groupHeader,
                  ),
                  const SizedBox(height: 8),
                  OrderDataCard(
                    rows: [
                      SettingsRow(
                        icon: Icons.qr_code_rounded,
                        label: l10n.settingsNpub,
                        value: shortOrderId(key.npub, head: 10, tail: 6),
                        onTap: () => _showNpub(context, key.npub),
                      ),
                      SettingsRow(
                        icon: Icons.key_rounded,
                        label: l10n.settingsBackup,
                        onTap: () => _openBackup(context),
                      ),
                      SettingsRow(
                        icon: Icons.logout_rounded,
                        label: l10n.settingsLogOut,
                        opens: false,
                        danger: true,
                        onTap: () => _logOut(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                GroupHeader(
                  title: l10n.settingsGroupAbout,
                  color: settings.groupHeader,
                ),
                const SizedBox(height: 8),
                OrderDataCard(
                  rows: [
                    OrderDataRow(
                      icon: Icons.info_outline_rounded,
                      label: l10n.settingsVersion,
                      value: OrderDataValue(
                        ref.watch(appVersionProvider),
                        figures: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNpub(BuildContext context, String npub) {
    showMostroSheet<void>(
      context: context,
      builder:
          (context) => MostroSheet(
            title: AppLocalizations.of(context).settingsNpub,
            content: NpubShare(npub: npub),
          ),
    );
  }

  /// The secret key only behind a warning and a confirmation.
  Future<void> _openBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final show = await showMostroDialog<bool>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            icon: Icons.visibility_outlined,
            title: l10n.backupWarnTitle,
            body: l10n.backupWarnBody,
            secondary: ModalAction(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
            primary: ModalAction(
              label: l10n.backupWarnAnswer,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
          ),
    );
    if (show == true && context.mounted) context.push(AppRoute.backup);
  }

  /// Log out, after a destructive confirmation (DS-CMP-2, DS-CMP-26). The
  /// router leaves for Welcome once the key is gone.
  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showMostroDialog<bool>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            icon: Icons.logout_rounded,
            iconTone: ModalTone.destructive,
            title: l10n.logOutTitle,
            body: l10n.logOutBody,
            secondary: ModalAction(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
            primary: ModalAction(
              label: l10n.logOutAnswer,
              tone: ModalTone.destructive,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
          ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(solverKeyProvider.notifier).logOut();
    } catch (_) {
      if (!context.mounted) return;
      await showMostroDialog<void>(
        context: context,
        builder:
            (dialog) => MostroDialog(
              icon: Icons.error_outline_rounded,
              iconTone: ModalTone.destructive,
              title: l10n.logOutFailed,
              primary: ModalAction(
                label: MaterialLocalizations.of(dialog).okButtonLabel,
                onPressed: () => Navigator.of(dialog).pop(),
              ),
            ),
      );
    }
  }
}
