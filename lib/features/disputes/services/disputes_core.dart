import 'dart:async';

import 'package:bosstro/src/rust/api/disputes.dart' as disputes_api;
import 'package:bosstro/src/rust/api/disputes.dart'
    show DisputeSummary, DisputeUpdate, PendingDisputes;
import 'package:bosstro/src/rust/api/take.dart' as take_api;
import 'package:bosstro/src/rust/api/take.dart'
    show DisputeDetail, InProgressDisputes, SolverStanding, TakeResult;

export 'package:bosstro/src/rust/api/disputes.dart'
    show
        DisputeInitiator,
        DisputeStatus,
        DisputeSummary,
        DisputeUpdate,
        PendingDisputes;
export 'package:bosstro/src/rust/api/take.dart'
    show
        DisputeDetail,
        InProgressDisputes,
        SolverPermission,
        SolverStanding,
        SolverStatus,
        TakeError,
        TakeOutcome,
        TakeResult,
        TakenDisputeSummary;

/// The Rust core's dispute feed and take (`rust/src/api/disputes.rs`,
/// `rust/src/api/take.rs`). An interface so widget tests, which run without
/// the native library, drive a fake.
abstract interface class DisputesCore {
  /// The active node's pending disputes, oldest first, or null without an
  /// active node.
  Future<PendingDisputes?> pending();

  /// Every change the feed announces, for whichever node is active.
  Stream<DisputeUpdate> updates();

  /// Ask the active node for [disputeId] and wait for its answer. Throws a
  /// [TakeError] when the request was not sent.
  Future<TakeResult> take(String disputeId);

  /// The disputes this key holds on the active node, or null without a node
  /// or a key.
  Future<InProgressDisputes?> inProgress();

  /// The active node's `in-progress` disputes this key does not hold here,
  /// or null without a node or a key.
  Future<List<DisputeSummary>?> recoverCandidates();

  /// This key's standing on the active node, or null without a node or a key.
  Future<SolverStanding?> standing();

  /// The detail of [disputeId] when this key took it on the active node;
  /// null otherwise (reopened, another key's, no node or key).
  Future<DisputeDetail?> detail(String disputeId);
}

class RustDisputesCore implements DisputesCore {
  const RustDisputesCore();

  @override
  Future<PendingDisputes?> pending() => disputes_api.pendingDisputes();

  @override
  Stream<DisputeUpdate> updates() async* {
    final stream = await disputes_api.onDisputeUpdates();
    while (true) {
      final next = await stream.next();
      if (next == null) return;
      yield next;
    }
  }

  @override
  Future<TakeResult> take(String disputeId) =>
      take_api.takeDispute(disputeId: disputeId);

  @override
  Future<InProgressDisputes?> inProgress() => take_api.inProgressDisputes();

  @override
  Future<List<DisputeSummary>?> recoverCandidates() =>
      take_api.recoverCandidates();

  @override
  Future<SolverStanding?> standing() => take_api.solverStanding();

  @override
  Future<DisputeDetail?> detail(String disputeId) =>
      take_api.disputeDetail(disputeId: disputeId);
}
