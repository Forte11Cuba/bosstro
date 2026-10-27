import 'package:flutter/material.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/utils/short_id.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/status_chip.dart';

/// One dispute of the Pending list (or of Recover a dispute): its status
/// (color and word, DS-COL-10), who opened it, how long ago, and its short
/// id, which copies the full one (DS-CMP-22). No amount: the public event
/// carries none; In progress shows it once the dispute is taken.
///
/// The row is a button when [onTap] is set: Pending takes the dispute,
/// Recover asks for it again. [hint] says which to a screen reader.
class PendingDisputeRow extends StatelessWidget {
  const PendingDisputeRow({
    super.key,
    required this.dispute,
    required this.now,
    this.onTap,
    this.hint,
  });

  final DisputeSummary dispute;

  /// The time the age is counted to.
  final DateTime now;

  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return Semantics(
      button: onTap != null,
      hint: hint,
      child: SurfaceCard(
        padding: disputeCardPadding,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: disputeStatusLabel(l10n, dispute.status),
              // Whose turn it is (amendment 3): a dispute waiting is the
              // solver's to take; one in progress here is not known to be
              // theirs.
              kind: statusChipKindOf(dispute.status),
            ),
            const SizedBox(height: 10),
            Text(
              disputeInitiatorLabel(l10n, dispute.initiator),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: pal.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: pal.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    disputeAgeLabel(l10n, dispute.openedAt?.toInt(), now),
                    style: TextStyle(fontSize: 13, color: pal.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CopyableDisputeId(id: dispute.disputeId),
          ],
        ),
      ),
    );
  }
}

/// The padding of a dispute card, which a [CopyableDisputeId] closes: none
/// under it, as the id's 48-dp target already leaves 16 under its line,
/// about the 14 over the card's chip.
const disputeCardPadding = EdgeInsets.fromLTRB(14, 14, 14, 0);

/// The short id and its copy icon, a 48-dp target that copies the full id.
class CopyableDisputeId extends StatelessWidget {
  const CopyableDisputeId({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Its own node: merged into the card, the whole card would read as the
    // copy button.
    return Semantics(
      container: true,
      button: true,
      label: l10n.disputeRowLabel(shortOrderId(id)),
      hint: l10n.copyIdHint,
      child: InkWell(
        onTap: () => copyId(context, id),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            // The label above says it whole; the cut id would read worse.
            child: ExcludeSemantics(child: OrderIdValue(id: id)),
          ),
        ),
      ),
    );
  }
}

/// The status as a word (glossary: solver, pay the buyer, refund the seller).
String disputeStatusLabel(AppLocalizations l10n, DisputeStatus status) =>
    switch (status) {
      DisputeStatus.initiated => l10n.disputeStatusInitiated,
      DisputeStatus.inProgress => l10n.disputeStatusInProgress,
      DisputeStatus.settled => l10n.disputeStatusSettled,
      DisputeStatus.sellerRefunded => l10n.disputeStatusSellerRefunded,
      DisputeStatus.released => l10n.disputeStatusReleased,
      DisputeStatus.cooperativelyCanceled =>
        l10n.disputeStatusCooperativelyCanceled,
    };

/// The chip's tone follows the solver's turn (Bosstro amendment 3): lime
/// while a dispute waits for a solver, or when it is [mine] and in progress;
/// neutral when it is another solver's, or closed.
StatusChipKind statusChipKindOf(DisputeStatus status, {bool mine = false}) =>
    switch (status) {
      DisputeStatus.initiated => StatusChipKind.turn,
      DisputeStatus.inProgress when mine => StatusChipKind.turn,
      _ => StatusChipKind.neutral,
    };

String disputeInitiatorLabel(
  AppLocalizations l10n,
  DisputeInitiator initiator,
) => switch (initiator) {
  DisputeInitiator.buyer => l10n.disputeOpenedByBuyer,
  DisputeInitiator.seller => l10n.disputeOpenedBySeller,
  DisputeInitiator.unknown => l10n.disputeOpenedByUnknown,
};

/// How long ago a dispute was opened ([openedAt], Unix seconds), counted to
/// [now]: minutes under an hour, hours under a day, days after. A time ahead
/// of the phone's clock reads as just now.
String disputeAgeLabel(AppLocalizations l10n, int? openedAt, DateTime now) {
  if (openedAt == null) return l10n.disputeOpenedUnknown;
  final opened = DateTime.fromMillisecondsSinceEpoch(openedAt * 1000);
  final age = now.difference(opened);
  if (age.inMinutes < 1) return l10n.disputeOpenedJustNow;
  if (age.inHours < 1) return l10n.disputeOpenedMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return l10n.disputeOpenedHoursAgo(age.inHours);
  return l10n.disputeOpenedDaysAgo(age.inDays);
}

/// How long ago this solver took a dispute ([takenAt], Unix seconds),
/// counted to [now], in the steps of [disputeAgeLabel].
String disputeTakenLabel(AppLocalizations l10n, int takenAt, DateTime now) {
  final taken = DateTime.fromMillisecondsSinceEpoch(takenAt * 1000);
  final age = now.difference(taken);
  if (age.inMinutes < 1) return l10n.disputeTakenJustNow;
  if (age.inHours < 1) return l10n.disputeTakenMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return l10n.disputeTakenHoursAgo(age.inHours);
  return l10n.disputeTakenDaysAgo(age.inDays);
}
