import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/not_solver_banner.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/take_dialog.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// Pending tab: the active node's disputes waiting for a solver (kind 38386
/// `initiated`, as Mostrix's Disputes Pending), the one that has waited
/// longest first. Before a node is chosen it says so, with the way to choose
/// one (D5). A tap on a row takes the dispute, after a confirmation; once
/// the node refused this key a waiting dispute, a banner says it is no
/// solver here.
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
                    ? const _PendingBody()
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

class _PendingBody extends ConsumerWidget {
  const _PendingBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingDisputesProvider);
    // Once the node refused this key a waiting dispute: above whatever
    // the list shows, in its scroll (it is tall at a large text scale).
    final banner =
        ref.watch(solverStandingProvider).valueOrNull?.status == SolverStatus.no
            ? const NotSolverBanner()
            : null;
    // Clipped rather than overflowing when the rows outgrow a short screen.
    final skeleton = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          if (banner case final top?)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                redesignSidePadding,
                0,
                redesignSidePadding,
                12,
              ),
              child: top,
            ),
          ListSkeleton(label: l10n.loadingDisputes, rowHeight: 132),
        ],
      ),
    );
    return switch (pending) {
      AsyncError() => ListEmptyState(
        header: banner,
        sticker: 'thinking',
        title: l10n.pendingLoadErrorTitle,
        body: l10n.pendingLoadErrorBody,
      ),
      AsyncData(:final value?) when value.disputes.isNotEmpty => _PendingList(
        disputes: value.disputes,
        header: banner,
      ),
      // Nothing stored and the relays not heard from yet: not known, not none.
      AsyncData(:final value?) when value.synced => ListEmptyState(
        header: banner,
        sticker: 'dispute',
        title: l10n.pendingEmptyTitle,
        body: l10n.pendingEmptyBody,
      ),
      _ => skeleton,
    };
  }
}

/// The list, with the ages counted to a clock that moves every minute. The
/// same tick reads the list again, so a dispute that expired (NIP-40) leaves
/// without waiting for the next update.
class _PendingList extends ConsumerStatefulWidget {
  const _PendingList({required this.disputes, this.header});

  final List<DisputeSummary> disputes;

  /// Shown above the rows, in the same scroll.
  final Widget? header;

  @override
  ConsumerState<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends ConsumerState<_PendingList> {
  late DateTime _now = clock.now();
  late final Timer _tick = Timer.periodic(const Duration(minutes: 1), (_) {
    setState(() => _now = clock.now());
    unawaited(ref.read(pendingDisputesProvider.notifier).refresh());
  });

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.disputes;
    final offset = widget.header == null ? 0 : 1;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        24,
      ),
      itemCount: rows.length + offset,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i < offset) return widget.header!;
        final dispute = rows[i - offset];
        return PendingDisputeRow(
          key: ValueKey(dispute.disputeId),
          dispute: dispute,
          now: _now,
          hint: AppLocalizations.of(context).takeDisputeHint,
          onTap:
              () => openTakeDialog(
                context,
                disputeId: dispute.disputeId,
                kind: TakeKind.take,
              ),
        );
      },
    );
  }
}
