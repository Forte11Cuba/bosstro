import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/l10n/app_localizations_en.dart';

import '../../support/fake_nodes.dart';

void main() {
  test('the active node is what the core saved, not what was typed', () async {
    final core = FakeNodesCore();
    final container = ProviderContainer(
      overrides: [nodesCoreProvider.overrideWithValue(core)],
    );
    addTearDown(container.dispose);

    await container
        .read(activeNodeProvider.notifier)
        .select('  ${cubaPubkey.toUpperCase()} ');
    expect(container.read(activeNodeProvider), cubaPubkey);
    expect(container.read(activeNodeProvider), core.activeNode());
  });

  test('a refused selection leaves the active node as it was', () async {
    final core = FakeNodesCore(active: mostroNodePubkey)..failSelect = true;
    final container = ProviderContainer(
      overrides: [
        nodesCoreProvider.overrideWithValue(core),
        activeNodeProvider.overrideWith(
          () => ActiveNodeNotifier(mostroNodePubkey),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(activeNodeProvider.notifier).select(cubaPubkey),
      throwsException,
    );
    expect(container.read(activeNodeProvider), mostroNodePubkey);
  });

  test('the link is online with one connected relay in use', () {
    final link = relayLinkOf([
      relay('wss://a', status: RelayStatus.disconnected),
      relay('wss://b'),
      // A removed node relay counts for nothing.
      relay('wss://c', blacklisted: true),
    ]);
    expect(link.state, ConnectionState.online);
    expect(link.connected, 1);
    expect(link.total, 2);
  });

  test('the link is connecting while one tries, offline otherwise', () {
    expect(
      relayLinkOf([relay('wss://a', status: RelayStatus.connecting)]).state,
      ConnectionState.reconnecting,
    );
    expect(
      relayLinkOf([relay('wss://a', status: RelayStatus.error)]).state,
      ConnectionState.offline,
    );
    expect(relayLinkOf(const []).state, ConnectionState.offline);
  });

  test('each core marker has its own copy', () {
    final l10n = AppLocalizationsEn();
    String node(String marker) => localizedNodeError(l10n, Exception(marker));
    String relayError(String marker) =>
        localizedRelayError(l10n, Exception(marker));
    expect(node('PrivateKeyNotAllowed: x'), l10n.nodeErrorPrivateKey);
    expect(node('NodeAlreadyExists: x'), l10n.nodeErrorAlreadyExists);
    expect(node('InvalidPubkey: x'), l10n.nodeErrorInvalidPubkey);
    expect(node('CannotRemoveActiveNode: x'), l10n.nodeErrorActive);
    expect(node('NotInitialized: x'), l10n.nodeErrorStorage);
    expect(node('anything else'), l10n.nodeErrorGeneric);
    expect(relayError('InvalidRelayUrl'), l10n.relayErrorInvalidUrl);
    expect(relayError('RelayAlreadyExists'), l10n.relayErrorExists);
    expect(relayError('LastRelay'), l10n.relayErrorLast);
  });

  test('the age of the info reads in the largest whole unit', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime.utc(2026, 10, 23);
    final t = now.millisecondsSinceEpoch ~/ 1000;
    expect(updatedAgo(l10n, t - 30, now), 'Updated just now');
    expect(updatedAgo(l10n, t - 60, now), 'Updated 1 minute ago');
    expect(updatedAgo(l10n, t - 7200, now), 'Updated 2 hours ago');
    expect(updatedAgo(l10n, t - 8 * 86400, now), 'Updated 8 days ago');
  });
}
