import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/detail_providers.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/screens/dispute_detail_screen.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/labeled_icon_action.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// In progress tab: the disputes this solver holds on the active node, the
/// one that has waited longest first (Mostrix's Disputes Management). Recover
/// a dispute opens from its header (Mostrix's Shift+R) and from its empty
/// state. A tap on a dispute opens its detail and chats: pushed on a phone,
/// beside the list from [AppBreakpoints.tablet] on.
class InProgressScreen extends ConsumerWidget {
  const InProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: ShellPalette.of(context).bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(
            title: l10n.inProgressTitle,
            action: LabeledIconAction(
              icon: Icons.history_rounded,
              label: l10n.recoverAction,
              onPressed: () => context.push(AppRoute.recover),
            ),
          ),
          const Expanded(child: _InProgressBody()),
        ],
      ),
    );
  }
}

class _InProgressBody extends ConsumerWidget {
  const _InProgressBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final held = ref.watch(inProgressDisputesProvider);
    return switch (held) {
      AsyncError() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.pendingLoadErrorTitle,
        body: l10n.pendingLoadErrorBody,
      ),
      AsyncData(:final value?) when value.disputes.isNotEmpty => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppBreakpoints.tablet) {
            return _InProgressList(
              disputes: value.disputes,
              onOpen: (id) => context.push(AppRoute.disputeDetail(id)),
            );
          }
          return _SplitView(
            disputes: value.disputes,
            width: constraints.maxWidth,
          );
        },
      ),
      AsyncData() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.inProgressEmptyTitle,
        body: l10n.inProgressEmptyBody,
        action: TextLink(
          label: l10n.recoverTitle,
          onPressed: () => context.push(AppRoute.recover),
        ),
      ),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ListSkeleton(label: l10n.loadingDisputes, rowHeight: 160),
      ),
    };
  }
}

/// The list, with the ages counted to a clock that moves every minute; the
/// same tick reads the list again (a dispute past its expiration leaves).
class _InProgressList extends ConsumerStatefulWidget {
  const _InProgressList({
    required this.disputes,
    required this.onOpen,
    this.selected,
  });

  final List<TakenDisputeSummary> disputes;
  final ValueChanged<String> onOpen;

  /// The dispute open beside the list (tablet).
  final String? selected;

  @override
  ConsumerState<_InProgressList> createState() => _InProgressListState();
}

class _InProgressListState extends ConsumerState<_InProgressList> {
  late DateTime _now = clock.now();
  late final Timer _tick = Timer.periodic(const Duration(minutes: 1), (_) {
    setState(() => _now = clock.now());
    unawaited(ref.read(inProgressDisputesProvider.notifier).refresh());
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        24,
      ),
      itemCount: widget.disputes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder:
          (context, i) => InProgressDisputeRow(
            key: ValueKey(widget.disputes[i].disputeId),
            dispute: widget.disputes[i],
            now: _now,
            selected: widget.disputes[i].disputeId == widget.selected,
            onTap: () => widget.onOpen(widget.disputes[i].disputeId),
          ),
    );
  }
}

/// The tablet layout: the list on the left, the chosen dispute's detail on
/// the right. A dispute that leaves the list (it closed) stays open there,
/// read only, until another is chosen.
class _SplitView extends ConsumerWidget {
  const _SplitView({required this.disputes, required this.width});

  final List<TakenDisputeSummary> disputes;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final selected = ref.watch(selectedDisputeProvider);
    final listWidth = (width * 0.4).clamp(300.0, 420.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidth,
          child: _InProgressList(
            disputes: disputes,
            selected: selected,
            onOpen:
                (id) => ref.read(selectedDisputeProvider.notifier).state = id,
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: pal.border),
        Expanded(
          child:
              selected == null
                  ? ListEmptyState(
                    sticker: 'dispute',
                    title: l10n.detailSelectTitle,
                    body: l10n.detailSelectBody,
                  )
                  : DisputeDetailView(
                    key: ValueKey(selected),
                    disputeId: selected,
                  ),
        ),
      ],
    );
  }
}
