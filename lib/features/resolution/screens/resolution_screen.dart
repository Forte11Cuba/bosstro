import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/disputes_palette.dart';
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
/// everything (the shell and the detail). Returns once it closed.
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
/// On a node that uses anti-abuse bonds (`bond_enabled` in its kind 38385,
/// [DisputeDetail.bondsEnabled]) the solver also chooses whose bond is
/// slashed, if anyone's (Mostrix's bond submenu): "Don't slash" by default.
/// The choice goes in the same request. On a node without bonds nothing is
/// offered or said; where it is not known, the screen says so, and the
/// request carries no slash (mostrod then releases any bond).
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

  /// Which bonds the request slashes (only offered when the node uses them).
  BondSlash _bond = BondSlash.noSlash;

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
            .resolve(widget.disputeId, widget.resolution, _bond),
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
        // No title: the confirmation's headline names the action ("Pay the
        // buyer?"), and the outcome says how it ended.
        appBar: redesignAppBar(
          context,
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
                    // Back to the confirmation, to choose other bonds.
                    onChooseAgain: () => setState(() => _outcome = null),
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
              bond: _bond,
              onBond: (bond) => setState(() => _bond = bond),
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
    required this.bond,
    required this.onBond,
  });

  final DisputeDetail detail;
  final bool pay;
  final bool busy;
  final BondSlash bond;
  final ValueChanged<BondSlash> onBond;

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
        switch (detail.bondsEnabled) {
          true => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _BondPicker(value: bond, onChanged: busy ? null : onBond),
          ),
          null => Text(l10n.resolveBondsUnknown, style: secondary),
          false => const SizedBox.shrink(),
        },
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
/// means, and one way on; centred, as a centred dialog (and an empty state)
/// says it.
class _OutcomeView extends StatelessWidget {
  const _OutcomeView({
    required this.outcome,
    required this.resolution,
    required this.onChooseAgain,
  });

  final _Outcome outcome;
  final Resolution resolution;

  /// After [ResolveOutcome.bondNotPosted]: back to the confirmation.
  final VoidCallback onChooseAgain;

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
        ResolveOutcome.bondNotPosted => (
          Icons.error_outline_rounded,
          pal.dangerText,
          l10n.bondNotPostedTitle,
          l10n.bondNotPostedBody,
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
    final chooseAgain = switch (outcome) {
      _Answered(:final result) =>
        result.outcome == ResolveOutcome.bondNotPosted,
      _NotSent() => false,
    };
    // What a resolution that went through slashed, when it slashed anything.
    final slashed = switch (outcome) {
      _Answered(:final result)
          when result.outcome == ResolveOutcome.paidBuyer ||
              result.outcome == ResolveOutcome.refundedSeller =>
        slashedLabel(l10n, result.bond),
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: redesignSidePadding,
              vertical: 32,
            ),
            children: [
              Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    ExcludeSemantics(child: Icon(icon, size: 44, color: color)),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: pal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: pal.textBody,
                      ),
                    ),
                    if (slashed != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        slashed,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: pal.textBody,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ActionBar(
          child: PrimaryButton(
            label:
                chooseAgain
                    ? l10n.bondChooseAgain
                    : takenOver
                    ? l10n.resolveGoToDisputes
                    : l10n.resolveBackToDispute,
            onPressed: () {
              if (chooseAgain) {
                onChooseAgain();
              } else if (takenOver) {
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

/// What a resolution slashed, in words, or null when it slashed nothing.
String? slashedLabel(AppLocalizations l10n, BondSlash? bond) => switch (bond) {
  BondSlash.buyer => l10n.resolvedSlashedBuyer,
  BondSlash.seller => l10n.resolvedSlashedSeller,
  BondSlash.both => l10n.resolvedSlashedBoth,
  BondSlash.noSlash || null => null,
};

/// The bond choice as its label (the Info row of a closed dispute).
String bondChoiceLabel(AppLocalizations l10n, BondSlash bond) => switch (bond) {
  BondSlash.noSlash => l10n.bondNoSlash,
  BondSlash.buyer => l10n.bondSlashBuyer,
  BondSlash.seller => l10n.bondSlashSeller,
  BondSlash.both => l10n.bondSlashBoth,
};

/// Whose bond a resolution slashes, if anyone's: four rows of one group,
/// "Don't slash" first and chosen by default. Each row names the party it
/// slashes and marks it with that party's colour (buyer lime, seller pink,
/// both for both, none for "Don't slash", amendment 8): a dot beside the
/// words, never a filled row, so no choice reads as the suggested one. Red
/// stays the confirmation's answer. The choice is read from the radio and
/// the words, never from colour alone (DS-COL-10).
class _BondPicker extends StatelessWidget {
  const _BondPicker({required this.value, required this.onChanged});

  final BondSlash value;

  /// Null while the request waits: the choice can no longer change.
  final ValueChanged<BondSlash>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = ShellPalette.of(context);
    final parties = DisputesPalette.of(context);
    final buyer = parties.observedBuyerLabel;
    final seller = parties.observedSellerLabel;
    final options = [
      (BondSlash.noSlash, l10n.bondNoSlash, l10n.bondNoSlashDetail, <Color>[]),
      (
        BondSlash.buyer,
        l10n.bondSlashBuyer,
        l10n.bondSlashBuyerDetail,
        [buyer],
      ),
      (
        BondSlash.seller,
        l10n.bondSlashSeller,
        l10n.bondSlashSellerDetail,
        [seller],
      ),
      (
        BondSlash.both,
        l10n.bondSlashBoth,
        l10n.bondSlashBothDetail,
        [buyer, seller],
      ),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.bondsTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: pal.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.bondsPickerHint,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: pal.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          for (final (choice, label, detail, dots) in options)
            _BondOption(
              label: label,
              detail: detail,
              dots: dots,
              selected: choice == value,
              onTap: onChanged == null ? null : () => onChanged!(choice),
            ),
        ],
      ),
    );
  }
}

class _BondOption extends StatelessWidget {
  const _BondOption({
    required this.label,
    required this.detail,
    required this.dots,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final List<Color> dots;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = ShellPalette.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      enabled: onTap != null,
      label: '$label. $detail',
      // Its own tap: the excluded subtree takes the InkWell's with it.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? pal.limeIcon : pal.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: pal.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: pal.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dots.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (i, color) in dots.indexed) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
