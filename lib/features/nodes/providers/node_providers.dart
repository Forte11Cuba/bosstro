import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/nodes/services/nodes_core.dart';

/// The core behind every node provider. Tests override it with a fake.
final nodesCoreProvider = Provider<NodesCore>((ref) => const RustNodesCore());

// ── The active node (D5) ─────────────────────────────────────────────────────

/// The active node's pubkey (hex), or null until the solver picks one.
/// Startup loads it from the core before the first frame (`main.dart`) and
/// overrides the initial value.
final activeNodeProvider = NotifierProvider<ActiveNodeNotifier, String?>(
  ActiveNodeNotifier.new,
);

class ActiveNodeNotifier extends Notifier<String?> {
  ActiveNodeNotifier([this._initial]);

  final String? _initial;

  @override
  String? build() => _initial;

  /// Make [pubkey] the active node. Rethrows the core's marker when it is
  /// refused; the active node is then unchanged. The new state is what the
  /// core saved (its normalised hex), never Dart's guess at it.
  Future<void> select(String pubkey) async {
    final core = ref.read(nodesCoreProvider);
    await core.selectNode(pubkey);
    state = core.activeNode();
  }
}

// ── The registry ─────────────────────────────────────────────────────────────

/// The node registry, as Rust lists it (Mostro first, then the trusted
/// communities, then the solver's own nodes), re-read when the active node
/// changes. Building it also refreshes the nodes' kind 0 profiles in the
/// background; the cached registry shows meanwhile.
final nodeRegistryProvider =
    AsyncNotifierProvider<NodeRegistryNotifier, List<MostroNodeEntry>>(
      NodeRegistryNotifier.new,
    );

class NodeRegistryNotifier extends AsyncNotifier<List<MostroNodeEntry>> {
  /// The refresh in flight, if any: a second call joins it.
  Future<void>? _refreshing;

  NodesCore get _core => ref.read(nodesCoreProvider);

  @override
  Future<List<MostroNodeEntry>> build() async {
    ref.watch(activeNodeProvider);
    final list = await _core.listNodes();
    unawaited(Future.microtask(refreshMetadata));
    return list;
  }

  /// Fetch every node's kind 0 profile, then the pictures they name.
  /// Best effort: a failure leaves the list as it is. Coalesced.
  Future<void> refreshMetadata() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    try {
      state = AsyncData(await _core.refreshMetadata());
    } catch (e) {
      debugPrint('[nodes] metadata refresh failed: $e');
    }
    try {
      for (final pubkey in await _core.syncPictures()) {
        ref.invalidate(nodePictureProvider(pubkey));
      }
    } catch (e) {
      debugPrint('[nodes] picture sync failed: $e');
    }
  }

  /// Add a node by pubkey. Rethrows the core's marker (`InvalidPubkey`,
  /// `PrivateKeyNotAllowed`, `NodeAlreadyExists`) for the dialog to word.
  Future<MostroNodeEntry> addNode({required String input, String? name}) async {
    final entry = await _core.addNode(input: input, name: name);
    state = AsyncData(await _core.listNodes());
    unawaited(refreshMetadata());
    return entry;
  }

  /// Remove one of the solver's own nodes. Rethrows the core's marker.
  Future<void> removeNode(String pubkey) async {
    await _core.removeNode(pubkey);
    state = AsyncData(await _core.listNodes());
  }
}

/// The registry entry of the active node, or null when none is chosen or
/// the registry has not loaded yet.
final activeNodeEntryProvider = Provider<MostroNodeEntry?>((ref) {
  final active = ref.watch(activeNodeProvider);
  if (active == null) return null;
  final nodes = ref.watch(nodeRegistryProvider).valueOrNull ?? const [];
  for (final node in nodes) {
    if (node.pubkey == active) return node;
  }
  return null;
});

// ── Pictures ─────────────────────────────────────────────────────────────────

/// A node's kind 0 picture as the device keeps it, or null (from ../app's
/// `node_picture_provider.dart`). Resolves once the picture is decoded into
/// the image cache; bytes that do not decode are forgotten, so the avatar
/// loads the URL and the next sync downloads the picture again.
final nodePictureProvider = FutureProvider.family<MostroNodePicture?, String>((
  ref,
  pubkey,
) async {
  final core = ref.read(nodesCoreProvider);
  final picture = await core.picture(pubkey);
  if (picture == null) return null;
  if (await _decode(nodePictureImage(picture.bytes))) return picture;
  try {
    await core.forgetPicture(pubkey);
  } catch (e) {
    debugPrint('[nodes] could not forget an undecodable picture: $e');
  }
  return null;
});

/// One decode width for every size: sharp up to 64 dp at 3×.
const nodePictureCacheWidth = 192;

/// The image of a stored picture's [bytes].
ImageProvider nodePictureImage(Uint8List bytes) =>
    ResizeImage(MemoryImage(bytes), width: nodePictureCacheWidth);

/// Decode [image] into the image cache; whether it decoded.
Future<bool> _decode(ImageProvider image) {
  final done = Completer<bool>();
  final stream = image.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!done.isCompleted) done.complete(true);
      // Not before the frame ends, as in `precacheImage`.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        info.dispose();
        stream.removeListener(listener);
      });
    },
    onError: (_, _) {
      if (!done.isCompleted) done.complete(false);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return done.future;
}

// ── Instance info (kind 38385) ───────────────────────────────────────────────

/// What the node info screen shows: the info as last known, and whether a
/// fetch from the relays is running or last failed.
@immutable
class NodeInfoView {
  const NodeInfoView({this.info, this.refreshing = false, this.failed = false});

  final NodeInfo? info;
  final bool refreshing;
  final bool failed;
}

/// A node's instance info: the cached copy at once, then the relays' newest.
final nodeInfoProvider = AsyncNotifierProvider.autoDispose
    .family<NodeInfoNotifier, NodeInfoView, String>(NodeInfoNotifier.new);

class NodeInfoNotifier
    extends AutoDisposeFamilyAsyncNotifier<NodeInfoView, String> {
  @override
  Future<NodeInfoView> build(String pubkey) async {
    NodeInfo? cached;
    try {
      cached = await ref.read(nodesCoreProvider).cachedInfo(pubkey);
    } catch (e) {
      debugPrint('[nodes] cached info not read: $e');
    }
    unawaited(Future.microtask(refresh));
    return NodeInfoView(info: cached, refreshing: true);
  }

  /// Ask the relays again; the cached info stays on screen meanwhile.
  Future<void> refresh() async {
    final current = state.valueOrNull?.info;
    state = AsyncData(NodeInfoView(info: current, refreshing: true));
    try {
      final fresh = await ref.read(nodesCoreProvider).fetchInfo(arg);
      state = AsyncData(NodeInfoView(info: fresh ?? current));
    } catch (e) {
      debugPrint('[nodes] info fetch failed: $e');
      state = AsyncData(NodeInfoView(info: current, failed: true));
    }
  }
}
