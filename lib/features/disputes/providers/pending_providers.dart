import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';

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

/// The active node's pending disputes (`initiated`, oldest first), live; null
/// without an active node.
///
/// Rust owns the list: storage, order and what counts as pending. Every
/// update for the active node re-reads it, coalesced so a node's whole
/// history arriving at once costs a few reads, not hundreds.
final pendingDisputesProvider =
    AsyncNotifierProvider<PendingDisputesNotifier, PendingDisputes?>(
      PendingDisputesNotifier.new,
    );

class PendingDisputesNotifier extends AsyncNotifier<PendingDisputes?> {
  /// How long updates are gathered before the list is read again.
  static const coalesce = Duration(milliseconds: 150);

  Timer? _pending;

  DisputesCore get _core => ref.read(disputesCoreProvider);

  @override
  Future<PendingDisputes?> build() async {
    final node = ref.watch(activeNodeProvider);
    ref.listen(disputeUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update != null &&
          update.mostroPubkey == ref.read(activeNodeProvider)) {
        _schedule();
      }
    });
    ref.onDispose(() => _pending?.cancel());
    if (node == null) return null;
    return _core.pending();
  }

  void _schedule() {
    if (_pending?.isActive ?? false) return;
    _pending = Timer(coalesce, () => unawaited(_reload()));
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await _core.pending());
    } catch (e) {
      // The list on screen stays; the next update tries again.
      debugPrint('[disputes] pending list not read: $e');
    }
  }
}
