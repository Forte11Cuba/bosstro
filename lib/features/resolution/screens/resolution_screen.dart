import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/resolution_palette.dart';
import 'package:bosstro/features/disputes/providers/detail_providers.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/disputes/widgets/pending_dispute_row.dart'
    show disputeStatusLabel;
import 'package:bosstro/features/disputes/widgets/take_dialog.dart'
    show refusedBody;
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/list_empty_state.dart';
import 'package:bosstro/shared/widgets/list_skeleton.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';
import 'package:bosstro/shared/widgets/redesign_app_bar.dart';

/// The navigator a resolution screen is open on, if any. A second tap on
/// "Pay the buyer" or "Refund the seller" before the first screen shows (or
/// while it is open) opens nothing; the core also refuses a second request
/// of a dispute still waiting for its answer.
NavigatorState? _openOn;

/// Open the full-screen confirmation of [resolution] for [disputeId], over
/// everything (the shell and the tablet split view). Returns once it closed.
Future<void> openResolutionScreen(
  BuildContext context, {
  required String disputeId,
  required Resolution resolution,
}) async {
  if (_openOn?.mounted ?? false) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  _openOn = navigator;
  try {
    await navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder:
            (_) =>
                ResolutionScreen(disputeId: disputeId, resolution: resolution),
      ),
    );
  } finally {
    if (identical(_openOn, navigator)) _openOn = null;
  }
}

/// What the screen shows after the answer.
sealed class _Outcome {
  const _Outcome();
}

class _Answered extends _Outcome {
  const _Answered(this.result);
  final ResolveResult result;
}

class _NotSent extends _Outcome {
  const _NotSent(this.error);
  final ResolveError error;
}

/// "Pay the buyer?" / "Refund the seller?" — Mostrix's finalization popup
/// and its confirmation, as one full-screen modal: who gets the sats and how
/// many (from the take's `SolverDisputeInfo`), what happens to the other
/// side, and that it cannot be undone. Its one answer is red and repeats
/// the action (DS-CMP-2, DS-CMP-26, amendment 3).
///
/// While the node answers, the answer shows its own spinner (DS-CMP-13) and
/// there is no way back: leaving would lose what the node says. Then the
/// same screen turns into the outcome, with one way out.
class ResolutionScreen extends ConsumerStatefulWidget {
  const ResolutionScreen({
    super.key,
    required this.disputeId,
    required this.resolution,
  });

  final String disputeId;
  final Resolution resolution;

  @override
  ConsumerState<ResolutionScreen> createState() => _ResolutionScreenState();
}

class _ResolutionScreenState extends ConsumerState<ResolutionScreen> {
  bool _busy = false;
  _Outcome? _outcome;

  /// What the confirmation showed when the request left: the node's own
  /// revision may close the dispute before its answer arrives, and the
  /// screen must not change under a request that is waiting.
  DisputeDetail? _shown;

  bool get _pay => widget.resolution == Resolution.payBuyer;

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    _Outcome outcome;
    try {
      outcome = _Answered(
        await ref
            .read(disputesCoreProvider)
            .resolve(widget.disputeId, widget.resolution),
      );
    } on ResolveError catch (error) {
      outcome = _NotSent(error);
    } catch (e) {
      debugPrint('[resolve] failed: $e');
      outcome = const _NotSent(ResolveError.sendFailed);
    }
    if (!mounted) return;
    // A permission learned changes no dispute row: read it now.
    await ref.read(solverStandingProvider.notifier).refresh();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final outcome = _outcome;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: pal.bg,
        appBar: redesignAppBar(
          context,
          title: _pay ? l10n.payBuyerAction : l10n.refundSellerAction,
          onBack: _busy ? null : () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child:
              outcome == null
                  ? _confirmation(context, l10n)
                  : _OutcomeView(
                    outcome: outcome,
                    resolution: widget.resolution,
                  ),
        ),
      ),
    );
  }

  Widget _confirmation(BuildContext context, AppLocalizations l10n) {
    final watched = ref.watch(disputeDetailProvider(widget.disputeId));
    final detail = switch ((_busy, _shown)) {
      (true, final shown?) => AsyncData<DisputeDetail?>(shown),
      _ => watched,
    };
    if (detail case AsyncData(:final value?) when !value.isClosed) {
      _shown = value;
    }
    return switch (detail) {
      AsyncData(:final value?) when !value.isClosed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ConfirmationBody(
              detail: value,
              pay: _pay,
              busy: _busy,
            ),
          ),
          ActionBar(
            child: ModalFooter(
              secondary: ModalAction(
                label: l10n.cancel,
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
              primary: ModalAction(
                label: _pay ? l10n.payBuyerAnswer : l10n.refundSellerAnswer,
                tone: ModalTone.destructive,
                busy: _busy,
                onPressed: _send,
              ),
            ),
          ),
        ],
      ),
      AsyncData(:final value?) => ListEmptyState(
        sticker: 'thinking',
        title: closedResultLabel(l10n, value.resolvedAs, value.status),
        body: l10n.resolveClosedBody,
      ),
      AsyncData() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.detailNotYoursTitle,
        body: l10n.detailNotYoursBody,
      ),
      AsyncError() => ListEmptyState(
        sticker: 'thinking',
        title: l10n.pendingLoadErrorTitle,
        body: l10n.pendingLoadErrorBody,
      ),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ListSkeleton(label: l10n.loadingDisputes, rowHeight: 160),
      ),
    };
  }
}

/// How a closed dispute ended: what this key did, when its own request
/// closed it; otherwise the dispute's public status.
String closedResultLabel(
  AppLocalizations l10n,
  ResolvedAs? resolvedAs,
  DisputeStatus status,
) => switch (resolvedAs) {
  ResolvedAs.paidBuyer => l10n.closedPaidBuyer,
  ResolvedAs.refundedSeller => l10n.closedRefundedSeller,
  ResolvedAs.cooperativelyCanceled => l10n.closedCooperatively,
  null => disputeStatusLabel(l10n, status),
};

/// What the confirmation says: the amount and who gets it, how it is made
/// up, the other side, the bonds, and the warning.
class _ConfirmationBody extends StatelessWidget {
  const _ConfirmationBody({
    required this.detail,
    required this.pay,
    required this.busy,
  });

  final DisputeDetail detail;
  final bool pay;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final res = ResolutionPalette.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    String sats(int value) => l10n.disputeAmountSats(number.format(value));

    final total = (pay ? detail.buyerPayout : detail.sellerRefund)?.toInt();
    final amount = detail.amount?.toInt();
    final fee = detail.fee?.toInt() ?? 0;
    final fiat = switch ((detail.fiatAmount, detail.fiatCode)) {
      (null, _) => null,
      (final value?, final code?) when code.isNotEmpty => l10n
          .disputeAmountFiat(number.format(value.toInt()), code),
      (final value?, _) => number.format(value.toInt()),
    };
    final secondary = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: pal.textSecondary,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        redesignSidePadding,
        8,
        redesignSidePadding,
        24,
      ),
      children: [
        Text(
          pay ? l10n.payBuyerTitle : l10n.refundSellerTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: pal.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pay ? l10n.payBuyerRecipient : l10n.refundSellerRecipient,
                style: TextStyle(fontSize: 14, color: pal.textBody),
              ),
              const SizedBox(height: 6),
              Text(
                total == null ? l10n.disputeAmountUnknown : sats(total),
                style: TextStyle(
                  fontFamily: AppFonts.figures,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: res.recipientInk,
                ),
              ),
              if (amount != null) ...[
                const SizedBox(height: 8),
                Text(
                  pay
                      ? l10n.payBuyerBreakdown(sats(amount), sats(fee))
                      : l10n.refundSellerBreakdown(sats(amount), sats(fee)),
                  style: secondary,
                ),
              ],
              if (fiat != null) ...[
                const SizedBox(height: 4),
                Text(l10n.resolveTradeFiat(fiat), style: secondary),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          pay ? l10n.payBuyerOtherSide : l10n.refundSellerOtherSide,
          style: TextStyle(fontSize: 14, height: 1.45, color: pal.textBody),
        ),
        const SizedBox(height: 10),
        Text(l10n.resolveBondsNote, style: secondary),
        const SizedBox(height: 16),
        _IrreversibleBanner(text: l10n.resolveIrreversible),
        if (busy) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(l10n.resolveWaiting, style: secondary),
          ),
        ],
      ],
    );
  }
}

/// "This cannot be undone", on a red tint (never a red fill behind body
/// text); the icon is decoration, the words say it (DS-COL-10).
class _IrreversibleBanner extends StatelessWidget {
  const _IrreversibleBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final res = ResolutionPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: res.warningBg,
        border: Border.all(color: res.warningBorder),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: res.warningInk,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: res.warningInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How the request ended: an icon in the outcome's color, a title, what it
/// means, and one way on.
class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.outcome, required this.resolution});

  final _Outcome outcome;
  final Resolution resolution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final (icon, color, title, body) = switch (outcome) {
      _Answered(:final result) => switch (result.outcome) {
        ResolveOutcome.paidBuyer => (
          Icons.check_circle_outline_rounded,
          pal.limeIcon,
          l10n.resolvedPaidTitle,
          l10n.resolvedPaidBody,
        ),
        ResolveOutcome.refundedSeller => (
          Icons.check_circle_outline_rounded,
          pal.limeIcon,
          l10n.resolvedRefundedTitle,
          l10n.resolvedRefundedBody,
        ),
        ResolveOutcome.cooperativelyCanceled => (
          Icons.handshake_outlined,
          pal.textTertiary,
          l10n.resolvedCoopTitle,
          l10n.resolvedCoopBody,
        ),
        ResolveOutcome.readOnlySolver => (
          Icons.lock_outline_rounded,
          pal.dangerText,
          l10n.readOnlySolverTitle,
          l10n.resolveReadOnlyNote,
        ),
        ResolveOutcome.takenOver => (
          Icons.swap_horiz_rounded,
          pal.dangerText,
          l10n.takenOverTitle,
          l10n.takenOverBody,
        ),
        ResolveOutcome.notInDispute => (
          Icons.info_outline_rounded,
          pal.textTertiary,
          l10n.notInDisputeTitle,
          l10n.notInDisputeBody,
        ),
        ResolveOutcome.noAnswer => (
          Icons.hourglass_empty_rounded,
          pal.warnText,
          l10n.noAnswerTitle,
          l10n.resolveNoAnswerBody,
        ),
        ResolveOutcome.refused => (
          Icons.error_outline_rounded,
          pal.dangerText,
          l10n.resolveRefusedTitle,
          result.reason == 'not_found'
              ? refusedBody(l10n, result.reason)
              : l10n.resolveRefusedBody,
        ),
      },
      _NotSent(:final error) => (
        Icons.error_outline_rounded,
        pal.dangerText,
        l10n.takeFailedTitle,
        resolveNotSentBody(l10n, error),
      ),
    };
    final takenOver = switch (outcome) {
      _Answered(:final result) => result.outcome == ResolveOutcome.takenOver,
      _NotSent() => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              redesignSidePadding,
              24,
              redesignSidePadding,
              24,
            ),
            children: [
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Icon(icon, size: 24, color: color)),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: pal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: pal.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ActionBar(
          child: PrimaryButton(
            label:
                takenOver ? l10n.resolveGoToDisputes : l10n.resolveBackToDispute,
            onPressed: () {
              if (takenOver) {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.go(AppRoute.inProgress);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Why a resolution did not leave.
String resolveNotSentBody(AppLocalizations l10n, ResolveError error) =>
    switch (error) {
      ResolveError.alreadyResolving => l10n.takeAlreadyTakingBody,
      ResolveError.closed => l10n.resolveClosedBody,
      ResolveError.notYours => l10n.observerNotYours,
      ResolveError.noOrderId => l10n.resolveNoOrderBody,
      ResolveError.unknownDispute => l10n.takeUnknownBody,
      ResolveError.protocolUnsupported => l10n.takeProtocolBody,
      ResolveError.nodeInfoUnavailable => l10n.takeNodeInfoBody,
      ResolveError.noKey ||
      ResolveError.noNode ||
      ResolveError.noRelays ||
      ResolveError.sendFailed => l10n.takeFailedBody,
    };
