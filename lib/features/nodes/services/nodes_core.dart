import 'dart:async';

import 'package:bosstro/src/rust/api/node_info.dart' as info_api;
import 'package:bosstro/src/rust/api/nodes.dart' as nodes_api;
import 'package:bosstro/src/rust/api/relays.dart' as relays_api;
import 'package:bosstro/src/rust/api/node_info.dart' show NodeInfo;
import 'package:bosstro/src/rust/api/nodes.dart'
    show MostroNodeEntry, MostroNodePicture;
import 'package:bosstro/src/rust/api/relays.dart' show RelayInfo;

export 'package:bosstro/src/rust/api/node_info.dart'
    show NodeInfo, ProtocolSupport;
export 'package:bosstro/src/rust/api/nodes.dart'
    show MostroNodeEntry, MostroNodePicture;
export 'package:bosstro/src/rust/api/relays.dart'
    show ConnectionState, RelayInfo, RelaySource, RelayStatus;

/// The Rust core's node registry, active node and instance info
/// (`rust/src/api/nodes.rs`, `node_info.rs`). An interface so widget tests,
/// which run without the native library, drive a fake.
abstract interface class NodesCore {
  Future<List<MostroNodeEntry>> listNodes();
  Future<List<MostroNodeEntry>> refreshMetadata();

  /// The pubkeys whose stored picture changed.
  Future<List<String>> syncPictures();
  Future<MostroNodePicture?> picture(String pubkey);
  Future<void> forgetPicture(String pubkey);

  Future<MostroNodeEntry> addNode({required String input, String? name});
  Future<void> removeNode(String pubkey);

  /// Persist [pubkey] (hex or npub) as the active node.
  Future<void> selectNode(String pubkey);

  /// The active node as the core holds it (lowercase hex), or null.
  String? activeNode();

  Future<NodeInfo?> cachedInfo(String pubkey);
  Future<NodeInfo?> fetchInfo(String pubkey);
}

class RustNodesCore implements NodesCore {
  const RustNodesCore();

  @override
  Future<List<MostroNodeEntry>> listNodes() => nodes_api.listMostroNodes();

  @override
  Future<List<MostroNodeEntry>> refreshMetadata() =>
      nodes_api.refreshMostroNodeMetadata();

  @override
  Future<List<String>> syncPictures() => nodes_api.syncMostroNodePictures();

  @override
  Future<MostroNodePicture?> picture(String pubkey) =>
      nodes_api.getMostroNodePicture(pubkey: pubkey);

  @override
  Future<void> forgetPicture(String pubkey) =>
      nodes_api.forgetMostroNodePicture(pubkey: pubkey);

  @override
  Future<MostroNodeEntry> addNode({required String input, String? name}) =>
      nodes_api.addCustomMostroNode(input: input, name: name);

  @override
  Future<void> removeNode(String pubkey) =>
      nodes_api.removeCustomMostroNode(pubkey: pubkey);

  @override
  Future<void> selectNode(String pubkey) =>
      nodes_api.selectActiveNode(pubkey: pubkey);

  @override
  String? activeNode() => nodes_api.activeNode();

  @override
  Future<NodeInfo?> cachedInfo(String pubkey) =>
      info_api.cachedNodeInfo(pubkey: pubkey);

  @override
  Future<NodeInfo?> fetchInfo(String pubkey) =>
      info_api.fetchNodeInfo(pubkey: pubkey);
}

/// The Rust core's relay pool (`rust/src/api/relays.rs`), behind the same
/// kind of seam.
abstract interface class RelaysCore {
  Future<List<RelayInfo>> relays();

  /// Every relay that changed status, or was added or removed.
  Stream<RelayInfo> relayChanges();

  Future<void> addRelay(String url);
  Future<void> removeRelay(String url);
}

class RustRelaysCore implements RelaysCore {
  const RustRelaysCore();

  @override
  Future<List<RelayInfo>> relays() => relays_api.getRelays();

  @override
  Stream<RelayInfo> relayChanges() async* {
    final stream = await relays_api.onRelayStatusChanged();
    while (true) {
      final next = await stream.next();
      if (next == null) return;
      yield next;
    }
  }

  @override
  Future<void> addRelay(String url) => relays_api.addRelay(url: url);

  @override
  Future<void> removeRelay(String url) => relays_api.removeRelay(url: url);
}
