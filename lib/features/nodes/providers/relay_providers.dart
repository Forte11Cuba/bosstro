import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/features/nodes/services/nodes_core.dart';

/// The core behind every relay provider. Tests override it with a fake.
final relaysCoreProvider = Provider<RelaysCore>(
  (ref) => const RustRelaysCore(),
);

/// The relay list, live: read once, then again on every change the pool
/// publishes. Errors when the pool never started (`NotInitialized`).
///
/// Not auto-disposed: the core's broadcast sender is process-wide and a
/// pending `next()` cannot be cancelled from Dart (MostroP2P/app), so one
/// subscription serves the whole process.
final relaysProvider = AsyncNotifierProvider<RelaysNotifier, List<RelayInfo>>(
  RelaysNotifier.new,
);

class RelaysNotifier extends AsyncNotifier<List<RelayInfo>> {
  RelaysCore get _core => ref.read(relaysCoreProvider);

  @override
  Future<List<RelayInfo>> build() async {
    final subscription = _core.relayChanges().listen(
      (_) => unawaited(_reload()),
      onError: (Object e) => debugPrint('[relays] change stream failed: $e'),
    );
    ref.onDispose(subscription.cancel);
    return _core.relays();
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await _core.relays());
    } catch (e) {
      debugPrint('[relays] reload failed: $e');
    }
  }

  /// Add a relay. Rethrows the core's marker (`InvalidRelayUrl`,
  /// `RelayAlreadyExists`) for the dialog to word.
  Future<void> add(String url) async {
    await _core.addRelay(url);
    await _reload();
  }

  /// Remove a relay. Rethrows the core's marker (`LastRelay`).
  Future<void> remove(String url) async {
    await _core.removeRelay(url);
    await _reload();
  }
}

/// How the app bar reads the relays: the pool's state and how many of the
/// relays in use answer.
@immutable
class RelayLink {
  const RelayLink({
    required this.state,
    required this.connected,
    required this.total,
  });

  final ConnectionState state;
  final int connected;
  final int total;
}

/// [RelayLink] from the live list, or null while it loads. A pool that
/// never started reads as offline with no relays.
final relayLinkProvider = Provider<RelayLink?>((ref) {
  final relays = ref.watch(relaysProvider);
  if (relays.hasError) {
    return const RelayLink(
      state: ConnectionState.offline,
      connected: 0,
      total: 0,
    );
  }
  final list = relays.valueOrNull;
  if (list == null) return null;
  return relayLinkOf(list);
});

/// The pool's state as the relay list implies it — the rule of the core's
/// `derive_connection_state`, applied to the rows it publishes — and the
/// counts over the relays in use (blacklisted rows are not).
RelayLink relayLinkOf(List<RelayInfo> relays) {
  final inUse = relays.where((r) => r.isActive && !r.isBlacklisted).toList();
  final connected =
      inUse.where((r) => r.status == RelayStatus.connected).length;
  final connecting = inUse.any((r) => r.status == RelayStatus.connecting);
  return RelayLink(
    state:
        connected > 0
            ? ConnectionState.online
            : connecting
            ? ConnectionState.reconnecting
            : ConnectionState.offline,
    connected: connected,
    total: inUse.length,
  );
}
