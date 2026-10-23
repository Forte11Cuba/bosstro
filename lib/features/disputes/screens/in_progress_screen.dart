import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
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
/// state. The detail and the chats arrive with phase 5.
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
      AsyncData(:final value?) when value.disputes.isNotEmpty =>
        _InProgressList(disputes: value.disputes),
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
  const _InProgressList({required this.disputes});

  final List<TakenDisputeSummary> disputes;

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
          ),
    );
  }
}
