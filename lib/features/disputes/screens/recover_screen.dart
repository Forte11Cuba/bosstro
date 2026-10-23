import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/disputes/widgets/take_dialog.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// Recover a dispute (Mostrix's Shift+R picker): the active node's disputes
/// in progress that are not among Your disputes here. The node does not say
/// who holds one, so the list mixes this solver's lost takes with other
/// solvers' disputes, and the screen says so. One at a time, each behind a
/// confirmation: never in bulk.
class RecoverScreen extends ConsumerWidget {
  const RecoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final candidates = ref.watch(recoverCandidatesProvider);
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: l10n.recoverTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: switch (candidates) {
        AsyncError() => ListEmptyState(
          sticker: 'thinking',
          title: l10n.pendingLoadErrorTitle,
          body: l10n.pendingLoadErrorBody,
        ),
        AsyncData(:final value?) when value.isNotEmpty => _RecoverList(
          disputes: value,
        ),
        AsyncData() => ListEmptyState(
          sticker: 'thinking',
          title: l10n.recoverEmptyTitle,
          body: l10n.recoverEmptyBody,
        ),
        _ => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ListSkeleton(label: l10n.loadingDisputes, rowHeight: 132),
        ),
      },
    );
  }
}

class _RecoverList extends ConsumerStatefulWidget {
  const _RecoverList({required this.disputes});

  final List<DisputeSummary> disputes;

  @override
  ConsumerState<_RecoverList> createState() => _RecoverListState();
}

class _RecoverListState extends ConsumerState<_RecoverList> {
  late DateTime _now = clock.now();
  late final Timer _tick = Timer.periodic(const Duration(minutes: 1), (_) {
    setState(() => _now = clock.now());
    unawaited(ref.read(recoverCandidatesProvider.notifier).refresh());
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        4,
        redesignSidePadding,
        24,
      ),
      children: [
        WarningNote(text: l10n.recoverNote, icon: Icons.info_outline_rounded),
        for (final dispute in widget.disputes) ...[
          const SizedBox(height: 12),
          PendingDisputeRow(
            key: ValueKey(dispute.disputeId),
            dispute: dispute,
            now: _now,
            hint: l10n.recoverDisputeHint,
            onTap:
                () => openTakeDialog(
                  context,
                  disputeId: dispute.disputeId,
                  kind: TakeKind.recover,
                ),
          ),
        ],
      ],
    );
  }
}
