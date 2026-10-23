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

  @override
  Future<InProgressDisputes?> inProgress() async {
    final node = this.node;
    if (node == null) return null;
    return InProgressDisputes(mostroPubkey: node, disputes: List.of(held));
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

/// A dispute this key holds, as the core summarises it.
TakenDisputeSummary sampleTaken({
  String id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  DisputeInitiator initiator = DisputeInitiator.seller,
  int? openedAt = 1700000000,
  int takenAt = 1700003600,
  int? amount = 75000,
  int? fiatAmount = 50,
  String? fiatCode = 'EUR',
  String node = mostroNodePubkey,
}) => TakenDisputeSummary(
  mostroPubkey: node,
  disputeId: id,
  status: DisputeStatus.inProgress,
  initiator: initiator,
  openedAt: openedAt,
  takenAt: takenAt,
  amount: amount,
  fiatAmount: fiatAmount,
  fiatCode: fiatCode,
);

/// A dispute's detail, as the core answers it.
DisputeDetail sampleDetail({
  String id = '8a0c1e64-0d3b-4c39-9a3e-3a1f1f0f4b2c',
  DisputeStatus status = DisputeStatus.inProgress,
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
  orderId: '5b9e1f7e-6f0e-4b8a-9c3d-2e1f0a9b8c7d',
  orderKind: 'sell',
  amount: 75000,
  fiatAmount: 50,
  fiatCode: 'EUR',
  paymentMethod: 'Transferencia bancaria nacional',
  premium: 2,
  fee: 750,
  buyerPubkey: buyerPubkey,
  sellerPubkey: sellerPubkey,
  isClosed: switch (status) {
    DisputeStatus.initiated || DisputeStatus.inProgress => false,
    _ => true,
  },
);
