import 'dart:async';

import 'package:clock/clock.dart';

import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';

/// The dispute feed in Dart: a list the test sets, read the way the core
/// answers (`pending_disputes`: only pending rows, for the active node), and
/// a stream of updates the test pushes.
class FakeDisputesCore implements DisputesCore {
  FakeDisputesCore({
    String? node = mostroNodePubkey,
    String? Function()? followNode,
    List<DisputeSummary>? disputes,
    this.synced = true,
  }) : _node = node,
       _followNode = followNode,
       disputes = disputes ?? [];

  String? _node;

  /// When set, the node is read from here, as the core reads the active node
  /// (the harness points it at the fake node registry).
  final String? Function()? _followNode;

  /// The node the core follows; null without one.
  String? get node => _followNode?.call() ?? _node;
  set node(String? value) => _node = value;

  List<DisputeSummary> disputes;

  /// NIP-40 expirations by dispute id: past one (by `clock`), the dispute is
  /// no longer pending, as the core computes `is_pending` when it answers.
  final Map<String, DateTime> expiresAt = {};
  bool synced;
  int reads = 0;
  final StreamController<DisputeUpdate> changes = StreamController.broadcast();

  @override
  Future<PendingDisputes?> pending() async {
    reads++;
    final node = this.node;
    if (node == null) return null;
    return PendingDisputes(
      mostroPubkey: node,
      disputes:
          disputes
              .where((d) => d.isPending)
              .where(
                (d) => expiresAt[d.disputeId]?.isAfter(clock.now()) ?? true,
              )
              .toList(),
      synced: synced,
    );
  }

  @override
  Stream<DisputeUpdate> updates() => changes.stream;

  /// The disputes this key holds, as `in_progress_disputes` answers.
  List<TakenDisputeSummary> held = [];

  /// What `recover_candidates` answers.
  List<DisputeSummary> candidates = [];

  /// What `solver_standing` answers (on [node]).
  SolverStatus status = SolverStatus.unknown;
  SolverPermission permission = SolverPermission.unknown;

  /// How each take ends: a [TakeResult] outcome, or a [TakeError] thrown.
  /// [takeAnswer] completes it later when set (a take still waiting).
  TakeOutcome takeOutcome = TakeOutcome.taken;
  String? takeReason;
  TakeError? takeError;
  Completer<void>? takeAnswer;

  /// The dispute ids asked for, in order.
  final List<String> takes = [];

  @override
  Future<TakeResult> take(String disputeId) async {
    takes.add(disputeId);
    if (takeAnswer case final wait?) await wait.future;
    if (takeError case final error?) throw error;
    if (takeOutcome == TakeOutcome.taken) {
      final taken = disputes.where((d) => d.disputeId == disputeId).toList();
      disputes.removeWhere((d) => d.disputeId == disputeId);
      candidates.removeWhere((d) => d.disputeId == disputeId);
      held.add(
        sampleTaken(
          id: disputeId,
          initiator:
              taken.isEmpty ? DisputeInitiator.seller : taken.first.initiator,
        ),
      );
      // The core stores the take (`record_take`) before it answers, so the
      // detail is there as soon as the take returns.
      details[disputeId] ??= sampleDetail(id: disputeId);
      status = SolverStatus.yes;
      push();
    } else if (takeOutcome == TakeOutcome.notSolver) {
      status = SolverStatus.no;
    }
    return TakeResult(
      mostroPubkey: node ?? '',
      disputeId: disputeId,
      outcome: takeOutcome,
      reason: takeReason,
    );
  }

  /// The closed disputes this key held, as `in_progress_disputes` answers.
  List<TakenDisputeSummary> closed = [];

  @override
  Future<InProgressDisputes?> inProgress() async {
    final node = this.node;
    if (node == null) return null;
    return InProgressDisputes(
      mostroPubkey: node,
      disputes: List.of(held),
      closed: List.of(closed),
    );
  }

  @override
  Future<List<DisputeSummary>?> recoverCandidates() async =>
      node == null ? null : List.of(candidates);

  @override
  Future<SolverStanding?> standing() async {
    final node = this.node;
    if (node == null) return null;
    return SolverStanding(
      mostroPubkey: node,
      status: status,
      permission: permission,
    );
  }

  /// What `dispute_detail` answers, by dispute id (absent: not this key's).
  final Map<String, DisputeDetail> details = {};

  @override
  Future<DisputeDetail?> detail(String disputeId) async =>
      node == null ? null : details[disputeId];

  /// How each resolution ends: a [ResolveResult] outcome, or a
  /// [ResolveError] thrown. [resolveAnswer] completes it later when set (a
  /// request still waiting for the node).
  ResolveOutcome resolveOutcome = ResolveOutcome.paidBuyer;
  String? resolveReason;
  ResolveError? resolveError;
  Completer<void>? resolveAnswer;

  /// The resolutions asked for, in order.
  final List<(String, Resolution)> resolutions = [];

  /// The bond choice of each resolution, in the same order.
  final List<BondSlash> bonds = [];

  @override
  Future<ResolveResult> resolve(
    String disputeId,
    Resolution resolution,
    BondSlash bond,
  ) async {
    resolutions.add((disputeId, resolution));
    bonds.add(bond);
    if (resolveAnswer case final wait?) await wait.future;
    if (resolveError case final error?) throw error;
    final resolvedAs = switch (resolveOutcome) {
      ResolveOutcome.paidBuyer => ResolvedAs.paidBuyer,
      ResolveOutcome.refundedSeller => ResolvedAs.refundedSeller,
      ResolveOutcome.cooperativelyCanceled => ResolvedAs.cooperativelyCanceled,
      _ => null,
    };
    if (resolvedAs != null) {
      final status = switch (resolvedAs) {
        ResolvedAs.paidBuyer => DisputeStatus.settled,
        ResolvedAs.refundedSeller => DisputeStatus.sellerRefunded,
        ResolvedAs.cooperativelyCanceled => DisputeStatus.cooperativelyCanceled,
      };
      if (held.any((d) => d.disputeId == disputeId)) {
        closed.insert(
          0,
          sampleTaken(id: disputeId, status: status, resolvedAs: resolvedAs),
        );
      }
      held.removeWhere((d) => d.disputeId == disputeId);
      if (details[disputeId] case final detail?) {
        details[disputeId] = sampleDetail(
          id: detail.disputeId,
          status: status,
          resolvedAs: resolvedAs,
          bondSlash:
              resolvedAs == ResolvedAs.cooperativelyCanceled
                  ? BondSlash.noSlash
                  : bond,
          bondsEnabled: detail.bondsEnabled,
        );
      }
      permission = SolverPermission.readWrite;
      push();
    } else if (resolveOutcome == ResolveOutcome.readOnlySolver) {
      permission = SolverPermission.read;
      push();
    } else if (resolveOutcome == ResolveOutcome.takenOver) {
      held.removeWhere((d) => d.disputeId == disputeId);
      details.remove(disputeId);
      push();
    }
    return ResolveResult(
      mostroPubkey: node ?? '',
      disputeId: disputeId,
      resolution: resolution,
      bond: bond,
      outcome: resolveOutcome,
      reason: resolveReason,
    );
  }

  /// Announce a change of [dispute] (or of the list, without one) for
  /// [forNode], as the feed does.
  void push({DisputeSummary? dispute, String? forNode}) {
    changes.add(
      DisputeUpdate(
        mostroPubkey: forNode ?? node ?? '',
        dispute: dispute,
        synced: synced,
      ),
    );
  }
}

/// A dispute as the core summarises it.
DisputeSummary sampleDispute({
  String id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  DisputeStatus status = DisputeStatus.initiated,
  DisputeInitiator initiator = DisputeInitiator.seller,
  int? openedAt = 1700000000,
  String node = mostroNodePubkey,
}) => DisputeSummary(
  mostroPubkey: node,
  disputeId: id,
  status: status,
  initiator: initiator,
  openedAt: openedAt,
  isPending: status == DisputeStatus.initiated,
);

/// A dispute this key holds (or held, with a closed [status]), as the core
/// summarises it.
TakenDisputeSummary sampleTaken({
  String id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  DisputeStatus status = DisputeStatus.inProgress,
  ResolvedAs? resolvedAs,
  DisputeInitiator initiator = DisputeInitiator.seller,
  int? openedAt = 1700000000,
  int takenAt = 1700003600,
  int? amount = 75000,
  int? fiatAmount = 50,
  String? fiatCode = 'EUR',
  String node = mostroNodePubkey,
  int? closedAt,
}) => TakenDisputeSummary(
  mostroPubkey: node,
  disputeId: id,
  status: status,
  initiator: initiator,
  openedAt: openedAt,
  takenAt: takenAt,
  amount: amount,
  fiatAmount: fiatAmount,
  fiatCode: fiatCode,
  resolvedAs: resolvedAs,
  // A closed one closed half an hour after the take, unless told.
  closedAt:
      closedAt ??
      (status == DisputeStatus.initiated || status == DisputeStatus.inProgress
          ? null
          : takenAt + 1800),
);

/// A dispute's detail, as the core answers it.
DisputeDetail sampleDetail({
  String id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  DisputeStatus status = DisputeStatus.inProgress,
  ResolvedAs? resolvedAs,
  BondSlash? bondSlash,
  bool? bondsEnabled = false,
  String? orderPreviousStatus = 'fiat-sent',
  Resolution? unanswered,
  String? orderId = '5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d',
  DisputeInitiator initiator = DisputeInitiator.seller,
  int? openedAt = 1700000000,
  int takenAt = 1700003600,
  String? buyerPubkey =
      'b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecf',
  String? sellerPubkey =
      'd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeef',
  String node = mostroNodePubkey,
}) => DisputeDetail(
  mostroPubkey: node,
  disputeId: id,
  status: status,
  initiator: initiator,
  openedAt: openedAt,
  takenAt: takenAt,
  orderId: orderId,
  orderKind: 'sell',
  amount: 75000,
  fiatAmount: 50,
  fiatCode: 'EUR',
  paymentMethod: 'Transferencia bancaria nacional',
  premium: 2,
  fee: 750,
  buyerPubkey: buyerPubkey,
  sellerPubkey: sellerPubkey,
  isClosed:
      resolvedAs != null ||
      switch (status) {
        DisputeStatus.initiated || DisputeStatus.inProgress => false,
        _ => true,
      },
  resolvedAs: resolvedAs,
  bondSlash: bondSlash,
  bondsEnabled: bondsEnabled,
  orderPreviousStatus: orderPreviousStatus,
  buyerPayout: 75000 - 750,
  sellerRefund: 75000 + 750,
  unansweredResolution: unanswered,
);
