import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/widgets/mostro_modal.dart';
import 'package:bosstro/shared/widgets/snackbar.dart';

/// Which question the dialog asks: take a dispute waiting for a solver
/// (Pending), or ask again for one in progress (Recover a dispute).
enum TakeKind { take, recover }

/// The navigator a take dialog is open on, if any. A second tap before the
/// first dialog shows (or while it is open) opens nothing, so one dispute is
/// never asked for twice by a double tap; the core also refuses a second
/// take of a dispute still waiting for its answer. A navigator that is gone
/// (the app rebuilt) holds no dialog.
NavigatorState? _openOn;

/// Ask the solver to confirm, send the take, and say how it ended. The
/// dialog stays open while the node answers (its answer button busy), then
/// either closes with a snackbar (taken) or turns into the outcome. Returns
/// once it is closed.
Future<void> openTakeDialog(
  BuildContext context, {
  required String disputeId,
  required TakeKind kind,
}) async {
  if (_openOn?.mounted ?? false) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  _openOn = navigator;
  try {
    final taken = await showMostroDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TakeDialog(disputeId: disputeId, kind: kind),
    );
    if (taken == true && context.mounted) {
      final l10n = AppLocalizations.of(context);
      showMostroSnackBar(
        context,
        kind == TakeKind.take ? l10n.takeTakenSnack : l10n.recoverTakenSnack,
      );
    }
  } finally {
    if (identical(_openOn, navigator)) _openOn = null;
  }
}

/// What the dialog shows after the answer.
sealed class _Outcome {
  const _Outcome();
}

class _Answered extends _Outcome {
  const _Answered(this.result);
  final TakeResult result;
}

class _NotSent extends _Outcome {
  const _NotSent(this.error);
  final TakeError error;
}

class TakeDialog extends ConsumerStatefulWidget {
  const TakeDialog({super.key, required this.disputeId, required this.kind});

  final String disputeId;
  final TakeKind kind;

  @override
  ConsumerState<TakeDialog> createState() => _TakeDialogState();
}

class _TakeDialogState extends ConsumerState<TakeDialog> {
  bool _busy = false;
  _Outcome? _outcome;

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    _Outcome outcome;
    try {
      outcome = _Answered(
        await ref.read(disputesCoreProvider).take(widget.disputeId),
      );
    } on TakeError catch (error) {
      outcome = _NotSent(error);
    } catch (e) {
      debugPrint('[take] failed: $e');
      outcome = const _NotSent(TakeError.sendFailed);
    }
    if (!mounted) return;
    // What the answer taught about this key (not a solver here) changes no
    // dispute, so no update says it: read it now.
    await ref.read(solverStandingProvider.notifier).refresh();
    if (!mounted) return;
    if (outcome case _Answered(
      :final result,
    ) when result.outcome == TakeOutcome.taken) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // No way back while the node answers: closing would lose its answer.
    return PopScope(
      canPop: !_busy,
      child: switch (_outcome) {
        null => _confirmation(l10n),
        final outcome => _outcomeDialog(context, l10n, outcome),
      },
    );
  }

  Widget _confirmation(AppLocalizations l10n) {
    final recover = widget.kind == TakeKind.recover;
    return MostroDialog(
      icon: recover ? Icons.history_rounded : Icons.gavel_rounded,
      title: recover ? l10n.recoverDisputeTitle : l10n.takeDisputeTitle,
      body: recover ? l10n.recoverDisputeBody : l10n.takeDisputeBody,
      secondary: ModalAction(
        label: l10n.cancel,
        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
      ),
      primary: ModalAction(
        label: recover ? l10n.recoverDisputeAnswer : l10n.takeDisputeAnswer,
        busy: _busy,
        onPressed: _send,
      ),
    );
  }

  Widget _outcomeDialog(
    BuildContext context,
    AppLocalizations l10n,
    _Outcome outcome,
  ) {
    final close = ModalAction(
      label: l10n.close,
      onPressed: () => Navigator.of(context).pop(false),
    );
    // Leaves the dialog for another screen of the app.
    ModalAction goTo(String label, String location) => ModalAction(
      label: label,
      onPressed: () {
        final router = GoRouter.of(context);
        Navigator.of(context).pop(false);
        router.push(location);
      },
    );
    final (title, body, primary, secondary) = switch (outcome) {
      _Answered(:final result) => switch (result.outcome) {
        TakeOutcome.notSolver => (
          l10n.notSolverTitle,
          l10n.notSolverBody,
          goTo(l10n.switchNodeAction, AppRoute.settingsNode),
          close,
        ),
        TakeOutcome.cannotTakeOver => (
          l10n.cannotTakeOverTitle,
          l10n.cannotTakeOverBody,
          close,
          null,
        ),
        TakeOutcome.noAnswer => (
          l10n.noAnswerTitle,
          l10n.noAnswerBody,
          // Already on Recover: nothing to open.
          widget.kind == TakeKind.recover
              ? close
              : goTo(l10n.recoverTitle, AppRoute.recover),
          widget.kind == TakeKind.recover ? null : close,
        ),
        TakeOutcome.refused || TakeOutcome.taken => (
          l10n.takeRefusedTitle,
          refusedBody(l10n, result.reason),
          close,
          null,
        ),
      },
      _NotSent(:final error) => (
        l10n.takeFailedTitle,
        notSentBody(l10n, error),
        close,
        null,
      ),
    };
    return MostroDialog(
      icon: Icons.error_outline_rounded,
      iconTone: ModalTone.destructive,
      title: title,
      body: body,
      primary: primary,
      secondary: secondary,
      liveRegion: true,
    );
  }
}

/// The copy of a refusal: mostro-core's `CantDoReason` marker, worded where
/// the solver can do something about it.
String refusedBody(AppLocalizations l10n, String? reason) => switch (reason) {
  'not_found' => l10n.takeRefusedNotFoundBody,
  _ => l10n.takeRefusedBody,
};

/// Why a take did not leave.
String notSentBody(AppLocalizations l10n, TakeError error) => switch (error) {
  TakeError.alreadyTaking => l10n.takeAlreadyTakingBody,
  TakeError.notTakeable => l10n.takeClosedBody,
  TakeError.unknownDispute => l10n.takeUnknownBody,
  TakeError.protocolUnsupported => l10n.takeProtocolBody,
  TakeError.noKey ||
  TakeError.noNode ||
  TakeError.noRelays ||
  TakeError.sendFailed => l10n.takeFailedBody,
};
