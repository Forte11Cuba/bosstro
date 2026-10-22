import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Settings tab. Phase 0 shows the version, read from the Rust core through
/// the bridge; node, relays, npub, backup and log out arrive with their
/// phases.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final settings = SettingsPalette.of(context);
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
}
