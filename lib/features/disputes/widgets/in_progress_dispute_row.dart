import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/status_chip.dart';

/// One dispute this solver holds: its status (lime, the solver's move,
/// amendment 3), the amount in sats and fiat from the take's answer, who
/// opened it, how long ago it was taken, and its short id, which copies the
/// full one (DS-CMP-22). A tap opens its detail and chats ([onTap]). A
/// closed one is a [ClosedDisputeRow].
class InProgressDisputeRow extends StatelessWidget {
  const InProgressDisputeRow({
    super.key,
    required this.dispute,
    required this.now,
    this.onTap,
  });

  final TakenDisputeSummary dispute;

  /// The time the age is counted to.
  final DateTime now;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return Semantics(
      button: onTap != null,
      hint: onTap == null ? null : l10n.openDisputeHint,
      child: SurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: disputeStatusLabel(l10n, dispute.status),
              kind: statusChipKindOf(dispute.status, mine: true),
            ),
            const SizedBox(height: 10),
            Text(
              disputeAmountLabel(
                l10n,
                dispute,
                Localizations.localeOf(context),
              ),
              style: TextStyle(
                fontFamily: AppFonts.figures,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: pal.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              disputeInitiatorLabel(l10n, dispute.initiator),
              style: TextStyle(fontSize: 14, color: pal.textBody),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: pal.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    disputeTakenLabel(l10n, dispute.takenAt.toInt(), now),
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

/// One dispute this solver held that closed, as the Closed segment lists it:
/// lighter than an open one. How it ended (the neutral chip, amendment 3),
/// the amount, how long ago it closed, and the short id; who opened it and
/// when it was taken stay in its detail. A tap opens the detail, read only.
class ClosedDisputeRow extends StatelessWidget {
  const ClosedDisputeRow({
    super.key,
    required this.dispute,
    required this.now,
    this.onTap,
  });

  final TakenDisputeSummary dispute;

  /// The time the age is counted to.
  final DateTime now;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final closedAt = dispute.closedAt?.toInt();
    return Semantics(
      button: onTap != null,
      hint: onTap == null ? null : l10n.openDisputeHint,
      child: SurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: disputeStatusLabel(l10n, dispute.status),
              kind: statusChipKindOf(dispute.status, mine: true),
            ),
            const SizedBox(height: 10),
            Text(
              disputeAmountLabel(
                l10n,
                dispute,
                Localizations.localeOf(context),
              ),
              style: TextStyle(
                fontFamily: AppFonts.figures,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: pal.textPrimary,
              ),
            ),
            if (closedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 14,
                    color: pal.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      disputeClosedLabel(l10n, closedAt, now),
                      style: TextStyle(fontSize: 13, color: pal.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            CopyableDisputeId(id: dispute.disputeId),
          ],
        ),
      ),
    );
  }
}

/// "Closed 5 minutes ago", counted to [now] from [closedAt] (Unix seconds).
String disputeClosedLabel(AppLocalizations l10n, int closedAt, DateTime now) {
  final closed = DateTime.fromMillisecondsSinceEpoch(closedAt * 1000);
  final age = now.difference(closed);
  if (age.inMinutes < 1) return l10n.disputeClosedJustNow;
  if (age.inHours < 1) return l10n.disputeClosedMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return l10n.disputeClosedHoursAgo(age.inHours);
  return l10n.disputeClosedDaysAgo(age.inDays);
}

/// `75,000 sats · 50 EUR`: the sats, then the fiat side when the node sent
/// it (the code only when the order's event was found).
String disputeAmountLabel(
  AppLocalizations l10n,
  TakenDisputeSummary dispute,
  Locale locale,
) {
  final number = NumberFormat.decimalPattern(locale.toString());
  final sats = dispute.amount;
  if (sats == null) return l10n.disputeAmountUnknown;
  final parts = [l10n.disputeAmountSats(number.format(sats.toInt()))];
  if (dispute.fiatAmount case final fiat?) {
    final amount = number.format(fiat.toInt());
    final code = dispute.fiatCode;
    parts.add(
      code != null && code.isNotEmpty
          ? l10n.disputeAmountFiat(amount, code)
          : amount,
    );
  }
  return parts.join(' · ');
}
