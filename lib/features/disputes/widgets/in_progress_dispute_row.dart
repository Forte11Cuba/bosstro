import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/status_chip.dart';

/// One dispute this solver holds: its status (lime, the solver's move,
/// amendment 3), the amount in sats and fiat from the take's answer, who
/// opened it, how long ago it was taken, and its short id, which copies the
/// full one (DS-CMP-22). A tap opens its detail and chats ([onTap]); in the
/// tablet split view the row open beside the list is [selected].
class InProgressDisputeRow extends StatelessWidget {
  const InProgressDisputeRow({
    super.key,
    required this.dispute,
    required this.now,
    this.onTap,
    this.selected = false,
  });

  final TakenDisputeSummary dispute;

  /// The time the age is counted to.
  final DateTime now;

  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    return Semantics(
      button: onTap != null,
      selected: selected,
      hint: onTap == null ? null : l10n.openDisputeHint,
      child: SurfaceCard(
        onTap: onTap,
        borderColor:
            selected ? DisputesPalette.of(context).segmentActiveBorder : null,
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
