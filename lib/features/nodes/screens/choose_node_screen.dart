import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/features/nodes/widgets/add_node_dialog.dart';
import 'package:bosstro/features/nodes/widgets/node_card.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// The node selector (D5): Mostro first, then the trusted communities, then
/// the solver's own nodes, and "Add your own node" under them.
///
/// Two ways in. Right after Log in or Create new account ([onboarding]),
/// with nowhere to go back to: choosing a node leads to the tabs. From
/// Settings → Node: choosing one switches to it and returns.
///
/// Tapping a card chooses it; there is no confirm button (MostroP2P/app). Each
/// card's info button opens the node's instance info, which can choose it
/// too.
class ChooseNodeScreen extends ConsumerStatefulWidget {
  const ChooseNodeScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<ChooseNodeScreen> createState() => _ChooseNodeScreenState();
}

class _ChooseNodeScreenState extends ConsumerState<ChooseNodeScreen> {
  /// The card just tapped: its radio fills while the switch runs.
  String? _selecting;

  /// Set before the first await of a tap, so two quick taps cannot race two
  /// selections or push two info screens.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Names and pictures may have changed since the registry was built.
    if (ref.exists(nodeRegistryProvider)) {
      Future.microtask(
        () => ref.read(nodeRegistryProvider.notifier).refreshMetadata(),
      );
    }
  }

  Future<void> _choose(MostroNodeEntry entry) async {
    if (_busy) return;
    if (entry.isActive) {
      if (widget.onboarding) context.go(AppRoute.pending);
      return;
    }
    _busy = true;
    final l10n = AppLocalizations.of(context);
    setState(() => _selecting = entry.pubkey);
    try {
      await ref.read(activeNodeProvider.notifier).select(entry.pubkey);
      if (!mounted) return;
      if (widget.onboarding) {
        context.go(AppRoute.pending);
      } else {
        showMostroSnackBar(context, l10n.nodeSwitched(nodeDisplayName(entry)));
        context.pop();
      }
    } catch (e) {
      debugPrint('[nodes] select failed: $e');
      if (!mounted) return;
      setState(() => _selecting = null);
      await showMostroDialog<void>(
        context: context,
        builder:
            (dialog) => MostroDialog(
              icon: Icons.error_outline_rounded,
              iconTone: ModalTone.destructive,
              title: l10n.nodeSelectFailed,
              primary: ModalAction(
                label: MaterialLocalizations.of(dialog).okButtonLabel,
                onPressed: () => Navigator.of(dialog).pop(),
              ),
            ),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _openInfo(MostroNodeEntry entry) async {
    if (_busy) return;
    _busy = true;
    try {
      final use = await context.push<bool>(AppRoute.nodeInfo(entry.pubkey));
      if (use != true || !mounted) return;
    } finally {
      _busy = false;
    }
    final fresh =
        ref
            .read(nodeRegistryProvider)
            .valueOrNull
            ?.where((n) => n.pubkey == entry.pubkey)
            .firstOrNull;
    if (fresh != null) unawaited(_choose(fresh));
  }

  Future<void> _addNode() async {
    if (_busy) return;
    _busy = true;
    try {
      await showAddNodeDialog(context);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final nodes = ref.watch(nodeRegistryProvider);

    final Widget list;
    if (nodes.hasValue) {
      final entries = nodes.requireValue;
      list = ListView(
        padding: const EdgeInsets.fromLTRB(
          redesignSidePadding,
          0,
          redesignSidePadding,
          24,
        ),
        children: [
          _Header(),
          for (final entry in entries) ...[
            NodeCard(
              key: ValueKey(entry.pubkey),
              entry: entry,
              // One radio at a time: while a switch runs the tapped node
              // owns it, not the one still active underneath.
              selected:
                  _selecting == null
                      ? entry.isActive
                      : entry.pubkey == _selecting,
              onSelect: () => _choose(entry),
              onInfo: () => _openInfo(entry),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          SecondaryButton(label: l10n.nodeAddOwn, onPressed: _addNode),
        ],
      );
    } else if (nodes.hasError) {
      list = ListEmptyState(
        sticker: 'confused',
        title: l10n.nodeErrorGeneric,
        body: l10n.nodeListFailed,
      );
    } else {
      list = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: redesignSidePadding,
              ),
              child: _Header(),
            ),
            ListSkeleton(label: l10n.loadingNodes),
          ],
        ),
      );
    }

    return PopScope(
      // From onboarding there is nowhere to go back to.
      canPop: !widget.onboarding,
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: l10n.chooseNodeAppBar,
          onBack: widget.onboarding ? null : () => context.pop(),
        ),
        body: SafeArea(top: false, child: list),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.chooseNodeTitle,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: pal.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.chooseNodeBody,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: pal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
