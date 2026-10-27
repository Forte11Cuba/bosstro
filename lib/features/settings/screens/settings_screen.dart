import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/settings/models/languages.dart';
import 'package:bosstro/features/settings/providers/language_provider.dart';
import 'package:bosstro/features/settings/widgets/language_sheet.dart';
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

/// Settings tab: the app's language and About; the active node and its relays,
/// whether this key is a solver there and its permission (once the node's
/// answers told); the solver key (npub, backup, and log out, the one
/// destructive row, last); and the app's version as a quiet line at the
/// end. Trusted senders arrive with phase 5b.
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
    final standing = ref.watch(solverStandingProvider).valueOrNull;
    final solverValue = switch (standing?.status) {
      SolverStatus.yes => l10n.settingsSolverYes,
      SolverStatus.no => l10n.settingsSolverNo,
      _ => null,
    };
    final permissionValue = switch (standing?.permission) {
      SolverPermission.read => l10n.permissionRead,
      SolverPermission.readWrite => l10n.permissionReadWrite,
      _ => null,
    };

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
                  title: l10n.settingsGroupApp,
                  color: settings.groupHeader,
                ),
                const SizedBox(height: 8),
                OrderDataCard(
                  rows: [
                    SettingsRow(
                      icon: Icons.language_rounded,
                      label: l10n.settingsLanguage,
                      value: switch (ref.watch(languageProvider)) {
                        null => l10n.languageSystem,
                        final code => languageName(code),
                      },
                      onTap: () => showLanguageSheet(context),
                    ),
                    SettingsRow(
                      icon: Icons.info_outline_rounded,
                      label: l10n.aboutScreenTitle,
                      onTap: () => context.push(AppRoute.about),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                      valueIsData: true,
                      onTap: () => context.push(AppRoute.relays),
                    ),
                    // Known only from the node's answers (D12).
                    if (active != null && solverValue != null)
                      OrderDataRow(
                        icon: Icons.gavel_rounded,
                        label: l10n.settingsSolverStatus,
                        value: OrderDataValue(solverValue),
                      ),
                    if (active != null && permissionValue != null)
                      OrderDataRow(
                        icon: Icons.verified_user_outlined,
                        label: l10n.settingsPermission,
                        value: OrderDataValue(permissionValue),
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
                        valueIsData: true,
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
                // The version is not a setting, so it sits outside the
                // cards, last and small, as MostroP2P/app shows it: there when
                // support asks for it, and nothing to tap.
                const SizedBox(height: 4),
                const _VersionLine(),
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

/// "Bosstro 0.1.0" in small grey text, outside the cards: the version is a
/// fact for support, not a setting, so it neither looks nor acts like a row.
class _VersionLine extends ConsumerWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = ShellPalette.of(context);
    final style = TextStyle(fontSize: 11, color: pal.textTertiary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: AppLocalizations.of(context).appName),
            const TextSpan(text: ' '),
            TextSpan(
              text: ref.watch(appVersionProvider),
              style: const TextStyle(fontFamily: AppFonts.figures),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}
