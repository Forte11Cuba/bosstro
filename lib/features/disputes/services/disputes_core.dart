import 'dart:async';

import 'package:bosstro/src/rust/api/disputes.dart' as disputes_api;
import 'package:bosstro/src/rust/api/disputes.dart'
    show DisputeUpdate, PendingDisputes;

export 'package:bosstro/src/rust/api/disputes.dart'
    show
        DisputeInitiator,
        DisputeStatus,
        DisputeSummary,
        DisputeUpdate,
        PendingDisputes;

/// The Rust core's dispute feed (`rust/src/api/disputes.rs`). An interface so
/// widget tests, which run without the native library, drive a fake.
abstract interface class DisputesCore {
  /// The active node's pending disputes, oldest first, or null without an
  /// active node.
  Future<PendingDisputes?> pending();

  /// Every change the feed announces, for whichever node is active.
  Stream<DisputeUpdate> updates();
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
}
