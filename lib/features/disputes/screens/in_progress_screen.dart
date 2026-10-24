import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';
import 'package:bosstro/features/disputes/widgets/in_progress_dispute_row.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/labeled_icon_action.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/tab_app_bar.dart';

/// The two parts of My disputes.
enum MyDisputesSection { open, closed }

/// The part of My disputes on screen. Kept for the session (not
/// auto-disposed), so a look at a closed dispute comes back to Closed; the
/// app always starts on the open ones.
final myDisputesSectionProvider = StateProvider<MyDisputesSection>(
  (ref) => MyDisputesSection.open,
);

/// My disputes tab: the disputes this solver holds on the active node, the
/// one that has waited longest first (Mostrix's Disputes Management), and in
/// a segment of their own the ones it held that closed, read only, the one
/// closed last first. Recover a dispute opens from the header of the open
/// ones (Mostrix's Shift+R) and from their empty state. A tap on a dispute
/// opens its detail and chats on a screen of its own, at any width: on a
/// wide window too the detail needs the room (the chat, the files, the
/// resolution), so there is no split view.
class InProgressScreen extends ConsumerWidget {
  const InProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final section = ref.watch(myDisputesSectionProvider);
    return ColoredBox(
      color: ShellPalette.of(context).bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(
            title: l10n.inProgressTitle,
            // Recover brings back an open dispute: not a closed one's job.
            action:
                section == MyDisputesSection.open
                    ? LabeledIconAction(
                      icon: Icons.history_rounded,
                      label: l10n.recoverAction,
                      onPressed: () => context.push(AppRoute.recover),
                    )
                    : null,
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
      AsyncData(:final value?) => _MyDisputes(
        disputes: value.disputes,
        closed: value.closed,
      ),
      AsyncData() => const _OpenEmpty(),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ListSkeleton(label: l10n.loadingDisputes, rowHeight: 160),
      ),
    };
  }
}

/// The open ones' empty state, with the way to recover a lost take.
class _OpenEmpty extends StatelessWidget {
  const _OpenEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListEmptyState(
      sticker: 'thinking',
      title: l10n.inProgressEmptyTitle,
      body: l10n.inProgressEmptyBody,
      action: TextLink(
        label: l10n.recoverTitle,
        onPressed: () => context.push(AppRoute.recover),
      ),
    );
  }
}

/// The segments (In progress · N / Closed · N) and the chosen part, with
/// the ages counted to a clock that moves every minute; the same tick reads
/// the list again (a dispute past its expiration leaves).
class _MyDisputes extends ConsumerStatefulWidget {
  const _MyDisputes({required this.disputes, required this.closed});

  final List<TakenDisputeSummary> disputes;

  /// The disputes this key held that closed, the one closed last first.
  final List<TakenDisputeSummary> closed;

  @override
  ConsumerState<_MyDisputes> createState() => _MyDisputesState();
}

class _MyDisputesState extends ConsumerState<_MyDisputes> {
  late DateTime _now;
  late final Timer _tick = Timer.periodic(const Duration(minutes: 1), (_) {
    setState(() => _now = clock.now());
    unawaited(ref.read(inProgressDisputesProvider.notifier).refresh());
  });

  @override
  void initState() {
    super.initState();
    // Read now, not on first use: an empty part shows no age, and the clock
    // must still be the one of the moment the list appeared.
    _now = clock.now();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  void _open(String id) => context.push(AppRoute.disputeDetail(id));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final section = ref.watch(myDisputesSectionProvider);
    // Fixed above the list, so switching to an empty part never moves them.
    final segments = Padding(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        4,
      ),
      child: DetailSegments<MyDisputesSection>(
        semanticLabel: l10n.myDisputesSegmentsLabel,
        selected: section,
        onSelected:
            (value) =>
                ref.read(myDisputesSectionProvider.notifier).state = value,
        segments: [
          DetailSegment(
            value: MyDisputesSection.open,
            label: l10n.myDisputesOpenSegment(widget.disputes.length),
          ),
          DetailSegment(
            value: MyDisputesSection.closed,
            label: l10n.myDisputesClosedSegment(widget.closed.length),
          ),
        ],
      ),
    );

    final rows = switch (section) {
      MyDisputesSection.open => [
        for (final dispute in widget.disputes)
          InProgressDisputeRow(
            key: ValueKey(dispute.disputeId),
            dispute: dispute,
            now: _now,
            onTap: () => _open(dispute.disputeId),
          ),
      ],
      MyDisputesSection.closed => [
        for (final dispute in widget.closed)
          ClosedDisputeRow(
            key: ValueKey(dispute.disputeId),
            dispute: dispute,
            now: _now,
            onTap: () => _open(dispute.disputeId),
          ),
      ],
    };
    final Widget part = switch (section) {
      _ when rows.isNotEmpty => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          redesignSidePadding,
          8,
          redesignSidePadding,
          24,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => rows[i],
      ),
      MyDisputesSection.open => const _OpenEmpty(),
      MyDisputesSection.closed => ListEmptyState(
        sticker: 'thinking',
        title: l10n.closedEmptyTitle,
        body: l10n.closedEmptyBody,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [segments, Expanded(child: part)],
    );
  }
}
