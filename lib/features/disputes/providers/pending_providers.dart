import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';

/// The core behind every dispute provider. Tests override it with a fake.
final disputesCoreProvider = Provider<DisputesCore>(
  (ref) => const RustDisputesCore(),
);

/// The feed's updates. Not auto-disposed, and not rebuilt on a node switch:
/// a pending `next()` cannot be cancelled from Dart, so one subscription
/// serves the whole process (as `relaysProvider`).
final disputeUpdatesProvider = StreamProvider<DisputeUpdate>(
  (ref) => ref.watch(disputesCoreProvider).updates(),
);

/// Something the core reads about the active node's disputes, kept live.
///
/// Rust owns the data: storage, order, and what belongs on each list. It is
/// read when the active node (or the solver key) changes, and again on every
/// update for the active node, coalesced so a node's whole history arriving
/// at once costs a few reads, not hundreds.
abstract class NodeDisputesNotifier<T> extends AsyncNotifier<T?> {
  /// How long updates are gathered before the core is read again.
  static const coalesce = Duration(milliseconds: 150);

  Timer? _pending;

  DisputesCore get core => ref.read(disputesCoreProvider);

  /// One read of the core.
  Future<T?> read();

  /// What a log out or another key changes: the In progress list, Recover
  /// and the standing are per key; Pending is not.
  bool get followsKey => true;

  @override
  Future<T?> build() async {
    final node = ref.watch(activeNodeProvider);
    if (followsKey) ref.watch(solverKeyProvider);
    ref.listen(disputeUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update != null &&
          update.mostroPubkey == ref.read(activeNodeProvider)) {
        _schedule();
      }
    });
    ref.onDispose(() => _pending?.cancel());
    if (node == null) return null;
    return read();
  }

  /// Read again now: what a list holds also changes with time (a dispute
  /// past its NIP-40 expiration leaves) and after a take.
  Future<void> refresh() => _reload();

  void _schedule() {
    if (_pending?.isActive ?? false) return;
    _pending = Timer(coalesce, () => unawaited(_reload()));
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await read());
    } catch (e) {
      // What is on screen stays; the next update tries again.
      debugPrint('[disputes] not read: $e');
    }
  }
}

/// The active node's pending disputes (`initiated`, oldest first), live; null
/// without an active node.
final pendingDisputesProvider =
    AsyncNotifierProvider<PendingDisputesNotifier, PendingDisputes?>(
      PendingDisputesNotifier.new,
    );

class PendingDisputesNotifier extends NodeDisputesNotifier<PendingDisputes> {
  static const coalesce = NodeDisputesNotifier.coalesce;

  /// How often an unsynced list is read again. The core marks a node synced
  /// within ten seconds and announces it, but the announcement can go before
  /// this notifier's stream is listening (the feed starts before the first
  /// frame): without a read of its own the skeleton would never leave.
  static const unsyncedRecheck = Duration(seconds: 2);

  Timer? _recheck;

  @override
  bool get followsKey => false;

  @override
  Future<PendingDisputes?> build() {
    ref.onDispose(() => _recheck?.cancel());
    return super.build();
  }

  @override
  Future<PendingDisputes?> read() async {
    final pending = await core.pending();
    _recheck?.cancel();
    if (pending != null && !pending.synced) {
      _recheck = Timer(unsyncedRecheck, () => unawaited(refresh()));
    }
    return pending;
  }
}

/// The disputes this key holds on the active node, oldest first, live; null
/// without a node or a key.
final inProgressDisputesProvider =
    AsyncNotifierProvider<InProgressDisputesNotifier, InProgressDisputes?>(
      InProgressDisputesNotifier.new,
    );

class InProgressDisputesNotifier
    extends NodeDisputesNotifier<InProgressDisputes> {
  @override
  Future<InProgressDisputes?> read() => core.inProgress();
}

/// What Recover a dispute offers, live; null without a node or a key.
final recoverCandidatesProvider =
    AsyncNotifierProvider<RecoverCandidatesNotifier, List<DisputeSummary>?>(
      RecoverCandidatesNotifier.new,
    );

class RecoverCandidatesNotifier
    extends NodeDisputesNotifier<List<DisputeSummary>> {
  @override
  Future<List<DisputeSummary>?> read() => core.recoverCandidates();
}

/// This key's standing on the active node (solver or not, permission), as
/// the node's answers taught it; null without a node or a key. A take
/// changes it, and every take also changes a dispute, so the updates keep it
/// current.
final solverStandingProvider =
    AsyncNotifierProvider<SolverStandingNotifier, SolverStanding?>(
      SolverStandingNotifier.new,
    );

class SolverStandingNotifier extends NodeDisputesNotifier<SolverStanding> {
  @override
  Future<SolverStanding?> read() => core.standing();
}
