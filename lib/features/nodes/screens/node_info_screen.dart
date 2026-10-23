import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/settings_palette.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/features/nodes/widgets/node_avatar.dart';
import 'package:bosstro/features/settings/widgets/settings_row.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// A node's identity and instance info: what Mostrix's Mostro Info tab shows
/// (`src/ui/tabs/mostro_info_tab.rs`), from the node's kind 38385 event —
/// protocol, the daemon's settings, its Lightning node, the fiat currencies
/// it accepts — under its kind 0 profile.
///
/// The info last seen shows at once; the relays are asked again on every
/// visit and on a pull. A node that is not active can be chosen from here
/// (the screen pops with `true`); one the solver added can be removed.
class NodeInfoScreen extends ConsumerWidget {
  const NodeInfoScreen({super.key, required this.pubkey});

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final nodes = ref.watch(nodeRegistryProvider).valueOrNull ?? const [];
    final entry =
        nodes.where((n) => n.pubkey == pubkey).firstOrNull ??
        MostroNodeEntry(
          pubkey: pubkey,
          isTrusted: false,
          isActive: ref.watch(activeNodeProvider) == pubkey,
        );
    final view = ref.watch(nodeInfoProvider(pubkey));

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.nodeInfoTitle,
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: pal.lime,
        onRefresh: () => ref.read(nodeInfoProvider(pubkey).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            redesignSidePadding,
            4,
            redesignSidePadding,
            24,
          ),
          children: [
            _Identity(entry: entry),
            const SizedBox(height: 20),
            ..._instanceInfo(context, view.valueOrNull),
            if (!entry.isTrusted && !entry.isActive) ...[
              const SizedBox(height: 20),
              OrderDataCard(
                rows: [
                  SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.removeNodeAction,
                    opens: false,
                    danger: true,
                    onTap: () => _remove(context, ref, entry),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          entry.isActive
              ? null
              : ActionBar(
                child: PrimaryButton(
                  label: l10n.nodeInfoUse,
                  onPressed: () => context.pop(true),
                ),
              ),
    );
  }

  List<Widget> _instanceInfo(BuildContext context, NodeInfoView? view) {
    final l10n = AppLocalizations.of(context);
    final info = view?.info;
    if (info == null) {
      if (view == null || view.refreshing) {
        return [
          ListSkeleton(
            label: l10n.loadingNodeInfo,
            count: 3,
            rowHeight: 120,
            padding: EdgeInsets.zero,
          ),
        ];
      }
      return [_NoInfo()];
    }
    return [
      if (view!.failed) ...[
        WarningNote(
          text: l10n.nodeInfoRefreshFailed,
          icon: Icons.cloud_off_rounded,
        ),
        const SizedBox(height: 12),
      ],
      if (info.protocolSupport == ProtocolSupport.unsupported) ...[
        WarningNote(
          text: l10n.nodeInfoUnsupported(info.protocolVersion ?? 0),
          icon: Icons.block_rounded,
        ),
        const SizedBox(height: 12),
      ],
      if (info.isStale) ...[
        WarningNote(text: l10n.nodeInfoStale),
        const SizedBox(height: 12),
      ],
      Text(
        updatedAgo(l10n, info.lastUpdated.toInt(), clock.now()),
        style: TextStyle(
          fontSize: 12,
          color: ShellPalette.of(context).textSecondary,
        ),
      ),
      const SizedBox(height: 16),
      ..._InfoSections(info: info).build(context),
    ];
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    MostroNodeEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showMostroDialog<bool>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            icon: Icons.delete_outline_rounded,
            iconTone: ModalTone.destructive,
            title: l10n.removeNodeTitle,
            body: l10n.removeNodeBody,
            secondary: ModalAction(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
            primary: ModalAction(
              label: l10n.removeNodeAnswer,
              tone: ModalTone.destructive,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
          ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(nodeRegistryProvider.notifier).removeNode(entry.pubkey);
      if (!context.mounted) return;
      showMostroSnackBar(context, l10n.nodeRemoved);
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      await showMostroDialog<void>(
        context: context,
        builder:
            (dialog) => MostroDialog(
              icon: Icons.error_outline_rounded,
              iconTone: ModalTone.destructive,
              title: localizedNodeError(l10n, e),
              primary: ModalAction(
                label: MaterialLocalizations.of(dialog).okButtonLabel,
                onPressed: () => Navigator.of(dialog).pop(),
              ),
            ),
      );
    }
  }
}

/// The node's face, name and kind 0 profile, and its public key to copy.
class _Identity extends StatelessWidget {
  const _Identity({required this.entry});

  final MostroNodeEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final region = entry.region;
    final about = entry.about;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NodeAvatar(entry: entry, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  nodeDisplayName(entry),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: pal.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (about != null) ...[
          const SizedBox(height: 12),
          Text(
            about,
            style: TextStyle(fontSize: 14, height: 1.5, color: pal.textBody),
          ),
        ],
        const SizedBox(height: 16),
        OrderDataCard(
          rows: [
            Semantics(
              hint: l10n.copyIdHint,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: OrderDataRow(
                  icon: Icons.key_rounded,
                  label: l10n.nodeInfoPubkey,
                  onTap: () => copyId(context, entry.pubkey),
                  value: OrderIdValue(id: entry.pubkey),
                ),
              ),
            ),
            if (region != null)
              OrderDataRow(
                icon: Icons.place_outlined,
                label: l10n.nodeInfoRegion,
                value: OrderDataValue(region),
              ),
            if (entry.website case final website?)
              OrderDataRow(
                icon: Icons.language_rounded,
                label: l10n.nodeInfoWebsite,
                value: _WrappedValue(website, mono: true),
              ),
          ],
        ),
      ],
    );
  }
}

/// No kind 38385 event was found and none is cached.
class _NoInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.nodeInfoEmptyTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: pal.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.nodeInfoEmptyBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: pal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostrix's sections, in its order. A row the node does not publish is
/// left out, as in Mostrix; the version, commit and Lightning identity say
/// "Unknown" instead.
class _InfoSections {
  const _InfoSections({required this.info});

  final NodeInfo info;

  List<Widget> build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final percent = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 2;
    final header = SettingsPalette.of(context).groupHeader;

    String sats(int? v) => l10n.unitSats(number.format(v));
    Widget value(String text, {bool figures = false}) =>
        OrderDataValue(text, figures: figures);
    OrderDataRow row(IconData icon, String label, Widget v) =>
        OrderDataRow(icon: icon, label: label, value: v);
    final unknown = l10n.nodeInfoUnknown;

    final daemon = <Widget>[
      row(
        Icons.dns_outlined,
        l10n.nodeInfoVersion,
        value(info.mostroVersion ?? unknown),
      ),
      row(
        Icons.commit_rounded,
        l10n.nodeInfoCommit,
        _WrappedValue(info.mostroCommitHash ?? unknown, mono: true),
      ),
      if (info.maxOrderAmount case final v?)
        row(
          Icons.arrow_upward_rounded,
          l10n.nodeInfoMaxOrder,
          value(sats(v.toInt()), figures: true),
        ),
      if (info.minOrderAmount case final v?)
        row(
          Icons.arrow_downward_rounded,
          l10n.nodeInfoMinOrder,
          value(sats(v.toInt()), figures: true),
        ),
      if (info.expirationHours case final v?)
        row(
          Icons.schedule_rounded,
          l10n.nodeInfoExpirationHours,
          value(l10n.unitHours(v.toInt()), figures: true),
        ),
      if (info.expirationSeconds case final v?)
        row(
          Icons.timer_outlined,
          l10n.nodeInfoExpirationSeconds,
          value(l10n.unitSeconds(v.toInt()), figures: true),
        ),
      if (info.holdInvoiceExpirationWindow case final v?)
        row(
          Icons.hourglass_bottom_rounded,
          l10n.nodeInfoHoldWindow,
          value(l10n.unitSeconds(v.toInt()), figures: true),
        ),
      if (info.holdInvoiceCltvDelta case final v?)
        row(
          Icons.view_week_outlined,
          l10n.nodeInfoHoldCltv,
          value(l10n.unitBlocks(v), figures: true),
        ),
      if (info.invoiceExpirationWindow case final v?)
        row(
          Icons.receipt_long_outlined,
          l10n.nodeInfoInvoiceWindow,
          value(l10n.unitSeconds(v.toInt()), figures: true),
        ),
      if (info.maxOrdersPerResponse case final v?)
        row(
          Icons.format_list_numbered_rounded,
          l10n.nodeInfoMaxOrders,
          value(number.format(v), figures: true),
        ),
      if (info.fee case final v?)
        row(
          Icons.percent_rounded,
          l10n.nodeInfoFee,
          // The tag is a fraction (0.006); shown as a percentage (0.6 %).
          value(l10n.unitPercent(percent.format(v * 100)), figures: true),
        ),
      if (info.pow case final v?)
        row(
          Icons.memory_rounded,
          l10n.nodeInfoPow,
          value(l10n.unitBits(v), figures: true),
        ),
      if (info.powFirstContact case final v?)
        row(
          Icons.memory_rounded,
          l10n.nodeInfoPowFirst,
          value(l10n.unitBits(v), figures: true),
        ),
      row(
        Icons.shield_outlined,
        l10n.nodeInfoBonds,
        value(switch (info.bondEnabled) {
          true => l10n.nodeInfoEnabled,
          false => l10n.nodeInfoDisabled,
          null => unknown,
        }),
      ),
    ];

    final lightning = <Widget>[
      row(
        Icons.bolt_rounded,
        l10n.nodeInfoAlias,
        value(info.lndNodeAlias ?? unknown),
      ),
      row(
        Icons.key_outlined,
        l10n.nodeInfoLnPubkey,
        _WrappedValue(info.lndNodePubkey ?? unknown, mono: true),
      ),
      row(
        Icons.dns_outlined,
        l10n.nodeInfoLndVersion,
        value(info.lndVersion ?? unknown),
      ),
      row(
        Icons.commit_rounded,
        l10n.nodeInfoCommit,
        _WrappedValue(info.lndCommitHash ?? unknown, mono: true),
      ),
      if (info.lndChains.isNotEmpty)
        row(
          Icons.link_rounded,
          l10n.nodeInfoChains,
          value(info.lndChains.join(', ')),
        ),
      if (info.lndNetworks.isNotEmpty)
        row(
          Icons.hub_outlined,
          l10n.nodeInfoNetworks,
          value(info.lndNetworks.join(', ')),
        ),
      for (final uri in info.lndUris)
        row(
          Icons.public_rounded,
          l10n.nodeInfoUri,
          _WrappedValue(uri, mono: true),
        ),
    ];

    final fiat =
        info.fiatCurrenciesAccepted.isEmpty
            ? l10n.nodeInfoFiatAll
            : info.fiatCurrenciesAccepted.join(', ');

    return [
      GroupHeader(title: l10n.nodeInfoGroupProtocol, color: header),
      const SizedBox(height: 8),
      OrderDataCard(
        rows: [
          row(
            Icons.swap_horiz_rounded,
            l10n.nodeInfoProtocolVersion,
            value(info.protocolVersion?.toString() ?? unknown, figures: true),
          ),
          // Bosstro speaks transport v2 only: NIP-44 in a signed kind 14.
          row(
            Icons.lock_outline_rounded,
            l10n.nodeInfoTransport,
            value('NIP-44'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      GroupHeader(title: l10n.nodeInfoGroupDaemon, color: header),
      const SizedBox(height: 8),
      OrderDataCard(rows: daemon),
      const SizedBox(height: 20),
      GroupHeader(title: l10n.nodeInfoGroupLightning, color: header),
      const SizedBox(height: 8),
      OrderDataCard(rows: lightning),
      const SizedBox(height: 20),
      GroupHeader(title: l10n.nodeInfoGroupFiat, color: header),
      const SizedBox(height: 8),
      SurfaceCard(
        child: Text(
          fiat,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: ShellPalette.of(context).textBody,
          ),
        ),
      ),
    ];
  }
}

/// A row value that must be read whole (a hash, a URI): wrapped, never cut
/// (DS-CMP-22's "full id where it must be read whole").
class _WrappedValue extends StatelessWidget {
  const _WrappedValue(this.text, {this.mono = false});

  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.end,
      style: TextStyle(
        fontFamily: mono ? AppFonts.mono : null,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ShellPalette.of(context).textStrong,
      ),
    );
  }
}
