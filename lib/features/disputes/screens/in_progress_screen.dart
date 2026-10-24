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
/// one that has waited longest first (Mostrix's Disputes Management), and
/// under them the ones it held that closed, read only. Recover
/// a dispute opens from its header (Mostrix's Shift+R) and from its empty
/// state. A tap on a dispute opens its detail and chats on a screen of its
/// own, at any width: on a wide window too the detail needs the room (the
/// chat, the files, the resolution), so there is no split view.
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
      AsyncData(:final value?)
          when value.disputes.isNotEmpty || value.closed.isNotEmpty =>
        _InProgressList(
          disputes: value.disputes,
          closed: value.closed,
          onOpen: (id) => context.push(AppRoute.disputeDetail(id)),
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
    required this.closed,
    required this.onOpen,
  });

  final List<TakenDisputeSummary> disputes;

  /// The disputes this key held that closed, after a heading.
  final List<TakenDisputeSummary> closed;
  final ValueChanged<String> onOpen;

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

  Widget _row(TakenDisputeSummary dispute) => InProgressDisputeRow(
    key: ValueKey(dispute.disputeId),
    dispute: dispute,
    now: _now,
    onTap: () => widget.onOpen(dispute.disputeId),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final items = <Widget>[
      for (final dispute in widget.disputes) _row(dispute),
      if (widget.closed.isNotEmpty) ...[
        if (widget.disputes.isEmpty)
          Text(
            l10n.inProgressNoneOpen,
            style: TextStyle(fontSize: 14, color: pal.textSecondary),
          ),
        Padding(
          padding: EdgeInsets.only(top: widget.disputes.isEmpty ? 4 : 12),
          child: Semantics(
            header: true,
            child: Text(
              l10n.inProgressClosedHeading,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: pal.textSecondary,
              ),
            ),
          ),
        ),
        for (final dispute in widget.closed) _row(dispute),
      ],
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        24,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => items[i],
    );
  }
}
