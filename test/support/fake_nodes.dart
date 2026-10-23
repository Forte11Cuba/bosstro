import 'dart:async';

import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';

/// A community from the registry, as the core lists it.
const cubaPubkey =
    '00000235a3e904cfe1213a8a54d6f1ec1bef7cc6bfaabd6193e82931ccf1366a';

/// Valid hex that is no real node: what a solver adds by hand.
const customPubkey =
    '0000000000000000000000000000000000000000000000000000000000000001';

/// The node registry, the active node and instance info, in Dart: the rules
/// of `rust/src/api/nodes.rs` that the screens rely on (Mostro first, the
/// active flag, the markers of a refused add or remove).
class FakeNodesCore implements NodesCore {
  FakeNodesCore({this.active, NodeInfo? info, this.failFetch = false})
    : infos = {if (info != null) info.pubkey: info};

  String? active;
  final List<({String pubkey, String? name})> custom = [];
  final Map<String, NodeInfo> infos;
  bool failFetch;
  bool failSelect = false;
  final List<String> log = [];

  /// When set, `listNodes` waits for it: the loading state.
  Completer<void>? listGate;

  List<MostroNodeEntry> _entries() => [
    MostroNodeEntry(
      pubkey: mostroNodePubkey,
      region: '🌐',
      isTrusted: true,
      isActive: active == mostroNodePubkey,
    ),
    MostroNodeEntry(
      pubkey: cubaPubkey,
      region: '🇨🇺 Cuba',
      isTrusted: true,
      isActive: active == cubaPubkey,
      name: 'Mostro Cuba',
      about: 'La comunidad de Mostro en Cuba.',
    ),
    for (final node in custom)
      MostroNodeEntry(
        pubkey: node.pubkey,
        isTrusted: false,
        isActive: active == node.pubkey,
        name: node.name,
      ),
  ];

  @override
  Future<List<MostroNodeEntry>> listNodes() async {
    await listGate?.future;
    return _entries();
  }

  @override
  Future<List<MostroNodeEntry>> refreshMetadata() async => _entries();

  @override
  Future<List<String>> syncPictures() async => const [];

  @override
  Future<MostroNodePicture?> picture(String pubkey) async => null;

  @override
  Future<void> forgetPicture(String pubkey) async {}

  @override
  Future<MostroNodeEntry> addNode({required String input, String? name}) async {
    final key = input.trim();
    if (key.startsWith('nsec')) throw Exception('PrivateKeyNotAllowed: x');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
      throw Exception('InvalidPubkey: x');
    }
    if (_entries().any((e) => e.pubkey == key)) {
      throw Exception('NodeAlreadyExists: x');
    }
    final trimmed = name?.trim();
    custom.add((
      pubkey: key,
      name: trimmed == null || trimmed.isEmpty ? null : trimmed,
    ));
    log.add('add:$key');
    return _entries().last;
  }

  @override
  Future<void> removeNode(String pubkey) async {
    if (pubkey == active) throw Exception('CannotRemoveActiveNode: x');
    custom.removeWhere((n) => n.pubkey == pubkey);
    log.add('remove:$pubkey');
  }

  @override
  Future<void> selectNode(String pubkey) async {
    if (failSelect) throw Exception('storage refused');
    active = pubkey;
    log.add('select:$pubkey');
  }

  @override
  Future<NodeInfo?> cachedInfo(String pubkey) async => null;

  @override
  Future<NodeInfo?> fetchInfo(String pubkey) async {
    if (failFetch) throw Exception('fetch_events failed');
    return infos[pubkey];
  }
}

/// The relay pool in Dart: a list the test sets, and a stream of changes
/// the test pushes.
class FakeRelaysCore implements RelaysCore {
  FakeRelaysCore({List<RelayInfo>? relays, this.failStart = false})
    : list = relays ?? [relay('wss://relay.mostro.network')];

  List<RelayInfo> list;
  final bool failStart;
  final StreamController<RelayInfo> changes = StreamController.broadcast();
  final List<String> log = [];

  @override
  Future<List<RelayInfo>> relays() async {
    if (failStart) throw Exception('NotInitialized');
    return list;
  }

  @override
  Stream<RelayInfo> relayChanges() => changes.stream;

  /// Replaces the list and publishes the change, as the pool does.
  void publish(List<RelayInfo> next) {
    list = next;
    changes.add(next.first);
  }

  @override
  Future<void> addRelay(String url) async {
    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      throw Exception('InvalidRelayUrl');
    }
    if (list.any((r) => r.url == url)) throw Exception('RelayAlreadyExists');
    list = [...list, relay(url, source: RelaySource.userAdded)];
    log.add('add:$url');
  }

  @override
  Future<void> removeRelay(String url) async {
    if (list.length <= 1) throw Exception('LastRelay');
    list = list.where((r) => r.url != url).toList();
    log.add('remove:$url');
  }
}

RelayInfo relay(
  String url, {
  RelayStatus status = RelayStatus.connected,
  RelaySource source = RelaySource.default_,
  bool blacklisted = false,
}) => RelayInfo(
  url: url,
  isActive: !blacklisted,
  isDefault: source == RelaySource.default_,
  source: source,
  isBlacklisted: blacklisted,
  status: status,
);

/// A full kind 38385 as the core parses it.
NodeInfo sampleInfo({
  String pubkey = cubaPubkey,
  int? protocolVersion = 2,
  bool stale = false,
  int lastUpdated = 0,
}) => NodeInfo(
  pubkey: pubkey,
  lastUpdated: lastUpdated,
  isStale: stale,
  name: 'Mostro Cuba',
  mostroVersion: '0.20.1',
  mostroCommitHash: '9f2c1d0e8b7a6f5e4d3c2b1a09f8e7d6c5b4a392',
  maxOrderAmount: 1000000,
  minOrderAmount: 100,
  expirationHours: 24,
  expirationSeconds: 900,
  fiatCurrenciesAccepted: const ['CUP', 'USD', 'MLC'],
  maxOrdersPerResponse: 10,
  fee: 0.006,
  pow: 0,
  powFirstContact: 8,
  protocolVersion: protocolVersion,
  protocolSupport:
      protocolVersion == null
          ? ProtocolSupport.unknown
          : protocolVersion == 2
          ? ProtocolSupport.supported
          : ProtocolSupport.unsupported,
  bondEnabled: true,
  holdInvoiceExpirationWindow: 300,
  holdInvoiceCltvDelta: 144,
  invoiceExpirationWindow: 300,
  lndVersion: '0.18.3-beta',
  lndNodePubkey:
      '02a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
  lndCommitHash: 'abc123',
  lndNodeAlias: 'mostro-cuba-lnd',
  lndChains: const ['bitcoin'],
  lndNetworks: const ['mainnet'],
  lndUris: const [
    '02a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90@203.0.113.7:9735',
  ],
);
