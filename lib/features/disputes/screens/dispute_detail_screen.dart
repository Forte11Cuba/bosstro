import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/chat/services/chat_core.dart';
import 'package:bosstro/features/chat/widgets/chat_pane.dart';
import 'package:bosstro/features/disputes/providers/detail_providers.dart';
import 'package:bosstro/features/disputes/widgets/detail_segments.dart';
import 'package:bosstro/features/disputes/widgets/dispute_info_pane.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// A dispute this solver holds, pushed from In progress on a phone
/// (Mostrix's Disputes Management): its data and the chats with the buyer
/// and the seller. On a tablet the same [DisputeDetailView] sits beside the
/// list instead.
class DisputeDetailScreen extends StatelessWidget {
  const DisputeDetailScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: redesignAppBar(
        context,
        title: AppLocalizations.of(context).disputeDetailTitle,
        onBack: () => context.pop(),
      ),
      // Over the shell, with no bottom bar: Android draws the app behind the
      // system navigation bar, so the SafeArea keeps the end of Info clear of
      // it (../app #267).
      body: SafeArea(
        top: false,
        child: DisputeDetailView(disputeId: disputeId),
      ),
    );
  }
}

/// Which part of the detail shows.
enum DetailSection { info, buyer, seller }

/// The detail's body: the Info / Buyer / Seller control over the chosen
/// part. The three stay built while another shows, so a message half
/// written to one party is still there after a look at the other.
class DisputeDetailView extends ConsumerStatefulWidget {
  const DisputeDetailView({super.key, required this.disputeId});

  final String disputeId;

  @override
  ConsumerState<DisputeDetailView> createState() => _DisputeDetailViewState();
}

class _DisputeDetailViewState extends ConsumerState<DisputeDetailView> {
  DetailSection _section = DetailSection.info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(disputeDetailProvider(widget.disputeId));
    return switch (detail) {
      AsyncData(value: null) => ListEmptyState(
        sticker: 'thinking',
        title: l10n.detailNotYoursTitle,
        body: l10n.detailNotYoursBody,
      ),
      AsyncError() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.pendingLoadErrorTitle,
        body: l10n.pendingLoadErrorBody,
      ),
      AsyncData(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              redesignSidePadding,
              4,
              redesignSidePadding,
              4,
            ),
            child: DetailSegments<DetailSection>(
              semanticLabel: l10n.detailSegmentsLabel,
              selected: _section,
              onSelected: (section) => setState(() => _section = section),
              segments: [
                DetailSegment(
                  value: DetailSection.info,
                  label: l10n.detailSegmentInfo,
                ),
                DetailSegment(
                  value: DetailSection.buyer,
                  label: l10n.detailSegmentBuyer,
                ),
                DetailSegment(
                  value: DetailSection.seller,
                  label: l10n.detailSegmentSeller,
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _section.index,
              children: [
                DisputeInfoPane(detail: value),
                ChatPane(
                  chat: (disputeId: widget.disputeId, party: ChatParty.buyer),
                ),
                ChatPane(
                  chat: (disputeId: widget.disputeId, party: ChatParty.seller),
                ),
              ],
            ),
          ),
        ],
      ),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ListSkeleton(label: l10n.loadingDisputes, rowHeight: 160),
      ),
    };
  }
}
