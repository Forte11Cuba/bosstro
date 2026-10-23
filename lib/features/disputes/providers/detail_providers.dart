import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/disputes/services/disputes_core.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';

/// The detail of one dispute this key took, live; null when it is not this
/// key's on the active node (reopened, another key's).
final disputeDetailProvider = AsyncNotifierProvider.autoDispose
    .family<DisputeDetailNotifier, DisputeDetail?, String>(
      DisputeDetailNotifier.new,
    );

class DisputeDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<DisputeDetail?, String> {
  Timer? _pending;

  DisputesCore get _core => ref.read(disputesCoreProvider);

  @override
  Future<DisputeDetail?> build(String arg) async {
    ref.watch(activeNodeProvider);
    ref.watch(solverKeyProvider);
    ref.listen(disputeUpdatesProvider, (_, next) {
      final update = next.valueOrNull;
      if (update == null ||
          update.mostroPubkey != ref.read(activeNodeProvider)) {
        return;
      }
      final dispute = update.dispute;
      if (dispute == null || dispute.disputeId == arg) _schedule();
    });
    ref.onDispose(() => _pending?.cancel());
    return _core.detail(arg);
  }

  void _schedule() {
    if (_pending?.isActive ?? false) return;
    _pending = Timer(NodeDisputesNotifier.coalesce, () => unawaited(_reload()));
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await _core.detail(arg));
    } catch (e) {
      debugPrint('[disputes] detail not read: $e');
    }
  }
}

/// The dispute open beside the list in the tablet split view (In progress);
/// none after a node or key change.
final selectedDisputeProvider = StateProvider<String?>((ref) {
  ref.watch(activeNodeProvider);
  ref.watch(solverKeyProvider);
  return null;
});
