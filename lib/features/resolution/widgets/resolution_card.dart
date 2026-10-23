import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/resolution/screens/resolution_screen.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/warning_note.dart';

/// The Info segment's way to end an open dispute this key holds: "Pay the
/// buyer" and "Refund the seller" (Mostrix's finalization popup), each
/// opening its full-screen confirmation. Neither is the screen's primary
/// action, and both weigh the same (DS-CMP-3, DS-CMP-4): the red answer is
/// the confirmation's.
///
/// When the node said this key is read-only here, the actions stay and a note
/// says why they will be refused — the operator may have changed it since,
/// and the next answer would tell. A request that got no answer is named
/// above them while it is still waited for: the node may have acted on it.
class ResolutionCard extends ConsumerWidget {
  const ResolutionCard({super.key, required this.detail});

  final DisputeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final permission =
        ref.watch(solverStandingProvider).valueOrNull?.permission;

    void open(Resolution resolution) => openResolutionScreen(
      context,
      disputeId: detail.disputeId,
      resolution: resolution,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.balance_rounded, size: 16, color: pal.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.resolveCardTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pal.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resolveCardBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: pal.textSecondary,
            ),
          ),
          if (detail.unansweredResolution case final unanswered?) ...[
            const SizedBox(height: 12),
            WarningNote(
              icon: Icons.hourglass_empty_rounded,
              text: switch (unanswered) {
                Resolution.payBuyer => l10n.resolveUnansweredPayNote,
                Resolution.refundSeller => l10n.resolveUnansweredRefundNote,
              },
            ),
          ],
          if (permission == SolverPermission.read) ...[
            const SizedBox(height: 12),
            WarningNote(
              icon: Icons.lock_outline_rounded,
              text: l10n.resolveReadOnlyNote,
            ),
          ],
          const SizedBox(height: 14),
          SecondaryButton(
            label: l10n.payBuyerAction,
            onPressed: () => open(Resolution.payBuyer),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: l10n.refundSellerAction,
            onPressed: () => open(Resolution.refundSeller),
          ),
        ],
      ),
    );
  }
}
