import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/boxed_field.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// Settings → Relays (from ../app's `relays_screen.dart`): every relay in
/// use with its status in words, where it came from, a remove button, and
/// "Add relay" under the list. Updates live as relays connect and drop.
///
/// The relays a node announced and the solver removed are not listed: they
/// are kept only so the node's list cannot bring them back.
class RelaysScreen extends ConsumerWidget {
  const RelaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final relays = ref.watch(relaysProvider);

    final Widget body;
    if (relays.hasError) {
      body = ListEmptyState(
        sticker: 'confused',
        title: l10n.relaysNotRunningTitle,
        body: l10n.relaysNotRunningBody,
      );
    } else {
      final list = relays.valueOrNull?.where((r) => !r.isBlacklisted).toList();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          redesignSidePadding,
          4,
          redesignSidePadding,
          24,
        ),
        children: [
          Text(
            l10n.relaysBody,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: pal.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (list == null)
            ListSkeleton(
              label: l10n.loadingRelays,
              count: 3,
              padding: EdgeInsets.zero,
            )
          else ...[
            for (final relay in list) ...[
              _RelayCard(
                key: ValueKey(relay.url),
                relay: relay,
                onRemove: () => _remove(context, ref, relay),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            SecondaryButton(
              label: l10n.relayAdd,
              onPressed: () => _add(context),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.relaysTitle,
        onBack: () => context.pop(),
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  Future<void> _add(BuildContext context) => showMostroDialog<void>(
    context: context,
    builder: (_) => const _AddRelayDialog(),
  );

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    RelayInfo relay,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showMostroDialog<bool>(
      context: context,
      builder:
          (dialog) => MostroDialog(
            icon: Icons.delete_outline_rounded,
            iconTone: ModalTone.destructive,
            title: l10n.removeRelayTitle,
            body: l10n.removeRelayBody,
            secondary: ModalAction(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
            primary: ModalAction(
              label: l10n.removeRelayAnswer,
              tone: ModalTone.destructive,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
          ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(relaysProvider.notifier).remove(relay.url);
    } catch (e) {
      if (!context.mounted) return;
      await showMostroDialog<void>(
        context: context,
        builder:
            (dialog) => MostroDialog(
              icon: Icons.error_outline_rounded,
              iconTone: ModalTone.destructive,
              title: localizedRelayError(l10n, e),
              primary: ModalAction(
                label: MaterialLocalizations.of(dialog).okButtonLabel,
                onPressed: () => Navigator.of(dialog).pop(),
              ),
            ),
      );
    }
  }
}

/// One relay: its address, its status as a dot and a word (DS-COL-10), where
/// it came from, and the remove button.
class _RelayCard extends StatelessWidget {
  const _RelayCard({super.key, required this.relay, required this.onRemove});

  final RelayInfo relay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final (word, ink, dot) = switch (relay.status) {
      RelayStatus.connected => (
        l10n.relayStatusConnected,
        pal.limeInk,
        pal.limeDot,
      ),
      RelayStatus.connecting => (
        l10n.relayStatusConnecting,
        pal.textSecondary,
        pal.neutralDot,
      ),
      RelayStatus.disconnected => (
        l10n.relayStatusDisconnected,
        pal.textSecondary,
        pal.neutralDot,
      ),
      RelayStatus.error => (l10n.relayStatusError, pal.dangerText, pal.danger),
    };
    final source = switch (relay.source) {
      RelaySource.default_ => l10n.relaySourceDefault,
      RelaySource.mostroDiscovered => l10n.relaySourceNode,
      RelaySource.userAdded => l10n.relaySourceUser,
    };
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relay.url,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 13,
                    color: pal.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ink,
                      ),
                    ),
                    Text(
                      '· $source',
                      style: TextStyle(fontSize: 12, color: pal.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.relayRemoveTooltip,
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: pal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Add a relay by address. The core normalises and checks it; an error
/// stays in the dialog, under the field.
class _AddRelayDialog extends ConsumerStatefulWidget {
  const _AddRelayDialog();

  @override
  ConsumerState<_AddRelayDialog> createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends ConsumerState<_AddRelayDialog> {
  final _url = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(relaysProvider.notifier).add(_url.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = localizedRelayError(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MostroDialog(
      title: l10n.addRelayTitle,
      content: BoxedField(
        controller: _url,
        label: l10n.addRelayLabel,
        hint: 'wss://…',
        mono: true,
        autofocus: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        errorText: _error,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _add(),
      ),
      secondary: ModalAction(
        label: l10n.cancel,
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
      ),
      primary: ModalAction(
        label: l10n.addRelayAnswer,
        busy: _busy,
        onPressed: _add,
      ),
    );
  }
}
