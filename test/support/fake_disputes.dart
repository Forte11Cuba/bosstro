import 'dart:async';

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
      disputes: disputes.where((d) => d.isPending).toList(),
      synced: synced,
    );
  }

  @override
  Stream<DisputeUpdate> updates() => changes.stream;

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
