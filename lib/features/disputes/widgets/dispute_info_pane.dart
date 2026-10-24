import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart';
import 'package:bosstro/features/observer/widgets/observer_card.dart';
import 'package:bosstro/features/resolution/screens/resolution_screen.dart'
    show bondChoiceLabel, closedResultLabel;
import 'package:bosstro/features/resolution/widgets/resolution_card.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The Info segment of the dispute detail: what the take told this solver,
/// as label → value rows (DS-CMP-24). Ids and keys read short and copy whole
/// (DS-CMP-22); a value the node did not send reads "Not known". The facts
/// come first (the dispute, with how it ended once closed; the order; the
/// parties' keys), then the way into the chat between the parties (phase
/// 5c), and last, while it is open, the way to resolve it (phase 6): the
/// irreversible step comes after everything it is decided on.
class DisputeInfoPane extends StatelessWidget {
  const DisputeInfoPane({super.key, required this.detail});

  final DisputeDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final unknown = OrderDataValue(l10n.detailPartyUnknown);

    Widget idRow(IconData icon, String label, String? id) => OrderDataRow(
      icon: icon,
      label: label,
      onTap: id == null ? null : () => copyId(context, id),
      value: id == null ? unknown : OrderIdValue(id: id),
    );

    Widget textRow(
      IconData icon,
      String label,
      String? value, {
      bool figures = false,
    }) => OrderDataRow(
      icon: icon,
      label: label,
      value:
          value == null || value.isEmpty
              ? unknown
              : OrderDataValue(value, figures: figures),
    );

    final fiat = switch ((detail.fiatAmount, detail.fiatCode)) {
      (null, _) => null,
      (final amount?, final code?) when code.isNotEmpty => l10n
          .disputeAmountFiat(number.format(amount.toInt()), code),
      (final amount?, _) => number.format(amount.toInt()),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        12,
        redesignSidePadding,
        24,
      ),
      children: [
        OrderDataCard(
          rows: [
            idRow(Icons.gavel_rounded, l10n.detailDisputeId, detail.disputeId),
            textRow(
              Icons.flag_outlined,
              l10n.detailStatus,
              disputeStatusLabel(l10n, detail.status),
            ),
            textRow(
              Icons.person_outline_rounded,
              l10n.detailOpenedBy,
              switch (detail.initiator) {
                DisputeInitiator.buyer => l10n.detailPartyBuyer,
                DisputeInitiator.seller => l10n.detailPartySeller,
                DisputeInitiator.unknown => null,
              },
            ),
            textRow(
              Icons.schedule_rounded,
              l10n.detailOpenedAt,
              _dateTime(detail.openedAt?.toInt(), locale),
            ),
            textRow(
              Icons.how_to_reg_outlined,
              l10n.detailTakenAt,
              _dateTime(detail.takenAt.toInt(), locale),
            ),
            if (detail.isClosed)
              textRow(
                Icons.task_alt_rounded,
                l10n.detailResult,
                closedResultLabel(l10n, detail.resolvedAs, detail.status),
              ),
            if (detail.isClosed && detail.bondSlash != null)
              textRow(
                Icons.shield_outlined,
                l10n.detailBonds,
                bondChoiceLabel(l10n, detail.bondSlash!),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OrderDataCard(
          rows: [
            idRow(
              Icons.receipt_long_outlined,
              l10n.detailOrderId,
              detail.orderId,
            ),
            textRow(
              Icons.swap_horiz_rounded,
              l10n.detailOrderKind,
              switch (detail.orderKind) {
                'buy' => l10n.detailOrderKindBuy,
                'sell' => l10n.detailOrderKindSell,
                _ => null,
              },
            ),
            textRow(
              Icons.history_rounded,
              l10n.detailPreviousStatus,
              previousStatusLabel(l10n, detail.orderPreviousStatus),
            ),
            textRow(
              Icons.currency_bitcoin_rounded,
              l10n.detailAmount,
              detail.amount == null
                  ? null
                  : l10n.disputeAmountSats(
                    number.format(detail.amount!.toInt()),
                  ),
              figures: true,
            ),
            textRow(
              Icons.payments_outlined,
              l10n.detailFiatAmount,
              fiat,
              figures: true,
            ),
            textRow(
              Icons.account_balance_outlined,
              l10n.detailPaymentMethod,
              detail.paymentMethod,
            ),
            textRow(
              Icons.percent_rounded,
              l10n.detailPremium,
              detail.premium == null
                  ? null
                  : l10n.detailPremiumValue(
                    number.format(detail.premium!.toInt()),
                  ),
              figures: true,
            ),
            textRow(
              Icons.toll_outlined,
              l10n.detailFee,
              detail.fee == null
                  ? null
                  : l10n.disputeAmountSats(number.format(detail.fee!.toInt())),
              figures: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        OrderDataCard(
          rows: [
            idRow(Icons.key_outlined, l10n.detailBuyerKey, detail.buyerPubkey),
            idRow(
              Icons.key_outlined,
              l10n.detailSellerKey,
              detail.sellerPubkey,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ObserverCard(disputeId: detail.disputeId),
        if (!detail.isClosed) ...[
          const SizedBox(height: 12),
          ResolutionCard(detail: detail),
        ],
      ],
    );
  }
}

/// A Unix time as the locale writes a date and a time; null when unknown.
String? _dateTime(int? seconds, String locale) {
  if (seconds == null) return null;
  final at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  return DateFormat.yMMMd(locale).add_Hm().format(at);
}

/// The order's status when the dispute opened, in words: whether the buyer
/// had marked the fiat as sent. A word the node may add later reads as it
/// came; null (not kept) reads "Not known".
String? previousStatusLabel(AppLocalizations l10n, String? status) =>
    switch (status) {
      'active' => l10n.orderStatusActive,
      'fiat-sent' => l10n.orderStatusFiatSent,
      null || '' => null,
      final other => other,
    };
