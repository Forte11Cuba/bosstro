import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/screens/node_info_screen.dart';
import 'package:bosstro/features/nodes/services/nodes_core.dart';
import 'package:bosstro/shared/widgets/order_data_card.dart';
import 'package:bosstro/shared/widgets/primary_button.dart';

import '../../support/screen_harness.dart';

void main() {
  /// DS-A11Y-4: every new screen at 2× text, 320 dp wide, in Spanish (the
  /// longest locale), in both themes, without overflow.
  group('fits at 320 dp, 2× text, es', () {
    for (final brightness in Brightness.values) {
      final theme = brightness.name;

      testWidgets('Choose node, onboarding ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.chooseNode,
          brightness: brightness,
          overrides: fakeCoreOverrides(nodes: FakeNodesCore()),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Elige tu nodo'), findsOneWidget);
      });

      testWidgets('Choose node, from Settings ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.settingsNode,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Nodo'), findsOneWidget);
      });

      testWidgets('Choose node, loading ($theme)', (tester) async {
        setSurface(tester);
        final semantics = tester.ensureSemantics();
        final nodes = FakeNodesCore()..listGate = Completer<void>();
        await pumpApp(
          tester,
          location: AppRoute.chooseNode,
          brightness: brightness,
          overrides: fakeCoreOverrides(nodes: nodes),
          settle: false,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Cargando nodos'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        nodes.listGate!.complete();
        await tester.pumpAndSettle();
        semantics.dispose();
      });

      testWidgets('Add a node, with an error ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.chooseNode,
          brightness: brightness,
          overrides: fakeCoreOverrides(nodes: FakeNodesCore()),
        );
        await tester.scrollUntilVisible(
          find.text('Agregar nodo propio'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Agregar nodo propio'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'nsec1abc');
        await tester.tap(find.text('Agregar nodo'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('clave secreta'), findsOneWidget);
      });

      testWidgets('Node info, full ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.nodeInfo(cubaPubkey),
          brightness: brightness,
          overrides: fakeCoreOverrides(
            nodes: FakeNodesCore(
              active: mostroNodePubkey,
              info: sampleInfo(protocolVersion: 1, stale: true),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Mostro Cuba'), findsWidgets);
        expect(find.text('Usar este nodo'), findsOneWidget);
        // The rest of the page, scrolled through: nothing overflows there
        // either.
        await tester.scrollUntilVisible(find.text('MONEDAS FIAT'), 300);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Node info, none published ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.nodeInfo(mostroNodePubkey),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text('Aún no hay información de la instancia'),
          findsOneWidget,
        );
        // The active node cannot be chosen again.
        expect(find.text('Usar este nodo'), findsNothing);
      });

      testWidgets('Relays ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.relays,
          brightness: brightness,
          overrides: fakeCoreOverrides(
            relays: FakeRelaysCore(
              relays: [
                relay('wss://relay.mostro.network'),
                relay(
                  'wss://relay.un-nombre-muy-largo-de-relay.example/con/ruta',
                  status: RelayStatus.connecting,
                  source: RelaySource.mostroDiscovered,
                ),
                relay(
                  'wss://mine.example',
                  status: RelayStatus.error,
                  source: RelaySource.userAdded,
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Conectado'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Agregar relay'), 200);
        expect(tester.takeException(), isNull);
        expect(find.text('Rechazado'), findsOneWidget);
      });

      testWidgets('Pending before a node is chosen ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.pending,
          brightness: brightness,
          overrides: fakeCoreOverrides(nodes: FakeNodesCore()),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Primero elige tu nodo'), findsOneWidget);
      });

      testWidgets('Settings with the node group ($theme)', (tester) async {
        setSurface(tester);
        await pumpApp(
          tester,
          location: AppRoute.settings,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Relays'), findsOneWidget);
      });
    }
  });

  group('Choose node', () {
    Future<FakeNodesCore> open(
      WidgetTester tester, {
      String location = AppRoute.chooseNode,
      FakeNodesCore? nodes,
    }) async {
      setSurface(tester, width: 400, height: 900);
      final core = nodes ?? FakeNodesCore();
      await pumpApp(
        tester,
        location: location,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(nodes: core),
      );
      return core;
    }

    testWidgets('lists Mostro first, then the communities', (tester) async {
      await open(tester);
      final mostro = tester.getTopLeft(find.text('Mostro'));
      final cuba = tester.getTopLeft(find.text('Mostro Cuba'));
      expect(mostro.dy, lessThan(cuba.dy));
      expect(find.text('TRUSTED'), findsNWidgets(2));
      expect(find.text('Add your own node'), findsOneWidget);
    });

    testWidgets('after onboarding there is no way back', (tester) async {
      await open(tester);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('choosing a node leads to the tabs', (tester) async {
      final core = await open(tester);
      await tester.tap(find.text('Mostro Cuba'));
      await tester.pumpAndSettle();
      expect(core.log, ['select:$cubaPubkey']);
      expect(find.text('Pending disputes'), findsOneWidget);
      // The app bar names the node, and the relays in words.
      expect(find.text('Mostro Cuba'), findsOneWidget);
      expect(find.text('Online · 1/1 relays'), findsOneWidget);
    });

    testWidgets('a refused choice says so and stays', (tester) async {
      final core = FakeNodesCore()..failSelect = true;
      await open(tester, nodes: core);
      await tester.tap(find.text('Mostro Cuba'));
      await tester.pumpAndSettle();
      expect(find.text('Could not switch to this node. Try again.'), findsOne);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your node'), findsOneWidget);
    });

    testWidgets('from Settings, a switch returns with a confirmation', (
      tester,
    ) async {
      final core = await open(
        tester,
        location: AppRoute.settings,
        nodes: FakeNodesCore(active: mostroNodePubkey),
      );
      expect(find.text('Mostro'), findsWidgets);
      await tester.tap(find.text('Node').last);
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE'), findsOneWidget);

      await tester.tap(find.text('Mostro Cuba'));
      await tester.pumpAndSettle();
      expect(core.active, cubaPubkey);
      expect(find.text('Now on Mostro Cuba'), findsOneWidget);
      // Back on Settings.
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('a node is added by its public key', (tester) async {
      final core = await open(tester);
      await tester.tap(find.text('Add your own node'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'not a key');
      await tester.tap(find.text('Add node'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a valid public key'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, customPubkey);
      await tester.enterText(find.byType(TextField).last, 'My node');
      await tester.tap(find.text('Add node'));
      await tester.pumpAndSettle();
      expect(core.log, ['add:$customPubkey']);
      expect(find.text('My node'), findsOneWidget);
      expect(find.text('ADDED BY YOU'), findsOneWidget);
    });

    testWidgets('the info screen can choose the node', (tester) async {
      final core = await open(tester, nodes: FakeNodesCore(info: sampleInfo()));
      await tester.tap(find.byTooltip('Node info').at(1));
      await tester.pumpAndSettle();
      expect(find.text('Node info'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('mostro-cuba-lnd'), 300);

      await tester.tap(find.text('Use this node'));
      await tester.pumpAndSettle();
      expect(core.log, ['select:$cubaPubkey']);
      expect(find.text('Pending disputes'), findsOneWidget);
    });
  });

  group('Node info clears the system navigation bar', () {
    Finder list() =>
        find
            .descendant(
              of: find.byType(NodeInfoScreen),
              matching: find.byType(Scrollable),
            )
            .first;

    testWidgets('the active node, with no button: the end of the page', (
      tester,
    ) async {
      setSurface(tester, padding: systemBars);
      await pumpApp(
        tester,
        location: AppRoute.nodeInfo(cubaPubkey),
        overrides: fakeCoreOverrides(
          nodes: FakeNodesCore(active: cubaPubkey, info: sampleInfo()),
        ),
      );
      expect(find.text('Usar este nodo'), findsNothing);
      await expectClearOfNavBar(
        tester,
        scrollable: list(),
        last: find.byType(SurfaceCard).last,
      );
    });

    testWidgets('another node: the end of the page and its button', (
      tester,
    ) async {
      setSurface(tester, padding: systemBars);
      await pumpApp(
        tester,
        location: AppRoute.nodeInfo(cubaPubkey),
        overrides: fakeCoreOverrides(
          nodes: FakeNodesCore(active: mostroNodePubkey, info: sampleInfo()),
        ),
      );
      await expectClearOfNavBar(
        tester,
        scrollable: list(),
        last: find.byType(SurfaceCard).last,
      );
      expect(
        tester.getBottomLeft(find.byType(PrimaryButton)).dy,
        lessThanOrEqualTo(640 - 48),
      );
    });
  });

  group('Node info', () {
    Future<FakeNodesCore> open(WidgetTester tester, FakeNodesCore core) async {
      setSurface(tester, width: 400, height: 2400);
      await pumpApp(
        tester,
        location: AppRoute.nodeInfo(cubaPubkey),
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(nodes: core),
      );
      return core;
    }

    testWidgets("shows Mostrix's sections, formatted", (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 10, 23)), () async {
        final now = DateTime.utc(2026, 10, 23).millisecondsSinceEpoch ~/ 1000;
        await open(
          tester,
          FakeNodesCore(
            active: mostroNodePubkey,
            info: sampleInfo(lastUpdated: now - 3 * 3600),
          ),
        );
      });
      for (final header in [
        'PROTOCOL',
        'MOSTRO DAEMON',
        'LIGHTNING NODE',
        'FIAT CURRENCIES',
      ]) {
        expect(find.text(header), findsOneWidget);
      }
      expect(find.text('Updated 3 hours ago'), findsOneWidget);
      expect(find.text('1,000,000 sats'), findsOneWidget);
      // The tag is a fraction: 0.006 is 0.6 %.
      expect(find.text('0.6 %'), findsOneWidget);
      expect(find.text('144 blocks'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('CUP, USD, MLC'), findsOneWidget);
      expect(find.textContaining('protocol v'), findsNothing);
    });

    testWidgets('warns about protocol v1 and stale info', (tester) async {
      await open(
        tester,
        FakeNodesCore(
          active: mostroNodePubkey,
          info: sampleInfo(protocolVersion: 1, stale: true),
        ),
      );
      expect(find.textContaining('speaks protocol v1'), findsOneWidget);
      expect(find.textContaining('more than 7 days old'), findsOneWidget);
    });

    testWidgets('a failed fetch keeps saying so', (tester) async {
      await open(
        tester,
        FakeNodesCore(active: mostroNodePubkey)..failFetch = true,
      );
      // Nothing cached and the relays failed: the empty explanation, not a
      // skeleton forever.
      expect(find.text('No instance info yet'), findsOneWidget);
    });

    testWidgets('a node the solver added can be removed', (tester) async {
      final core = FakeNodesCore(active: mostroNodePubkey);
      await core.addNode(input: customPubkey, name: 'Mine');
      setSurface(tester, width: 400, height: 900);
      await pumpApp(
        tester,
        location: AppRoute.settingsNode,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(nodes: core),
      );
      await tester.tap(find.byTooltip('Node info').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Remove node'), 200);
      await tester.tap(find.text('Remove node'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this node?'), findsOneWidget);
      await tester.tap(find.text('Remove node').last);
      await tester.pumpAndSettle();
      expect(core.log.last, 'remove:$customPubkey');
      expect(find.text('Mine'), findsNothing);
      expect(find.text('Node removed'), findsOneWidget);
    });

    testWidgets('a trusted or active node offers no removal', (tester) async {
      await open(tester, FakeNodesCore(active: mostroNodePubkey));
      expect(find.text('Remove node'), findsNothing);
    });
  });

  group('Relays', () {
    Future<FakeRelaysCore> open(
      WidgetTester tester,
      FakeRelaysCore core,
    ) async {
      setSurface(tester, width: 400, height: 900);
      await pumpApp(
        tester,
        location: AppRoute.relays,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(relays: core),
      );
      return core;
    }

    testWidgets('a relay is added, and a bad address is named', (tester) async {
      final core = await open(tester, FakeRelaysCore());
      await tester.tap(find.text('Add relay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'relay.example');
      await tester.tap(find.text('Add relay').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('starts with wss://'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'wss://new.example');
      await tester.tap(find.text('Add relay').last);
      await tester.pumpAndSettle();
      expect(core.log, ['add:wss://new.example']);
      expect(find.text('wss://new.example'), findsOneWidget);
      expect(find.text('· Added by you'), findsOneWidget);
    });

    testWidgets('the last relay is not removed, and says why', (tester) async {
      await open(tester, FakeRelaysCore());
      await tester.tap(find.byTooltip('Remove relay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove relay').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('This is your last relay'), findsOneWidget);
    });

    testWidgets('a removed node relay is not listed', (tester) async {
      await open(
        tester,
        FakeRelaysCore(
          relays: [
            relay('wss://a.example'),
            relay(
              'wss://gone.example',
              source: RelaySource.mostroDiscovered,
              blacklisted: true,
            ),
          ],
        ),
      );
      expect(find.text('wss://gone.example'), findsNothing);
    });

    testWidgets('status changes show live, in the app bar too', (tester) async {
      final core = FakeRelaysCore(
        relays: [relay('wss://a.example', status: RelayStatus.connecting)],
      );
      setSurface(tester, width: 400, height: 900);
      await pumpApp(
        tester,
        location: AppRoute.pending,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(relays: core),
      );
      expect(find.text('Connecting to relays…'), findsOneWidget);

      core.publish([
        relay('wss://a.example', status: RelayStatus.disconnected),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Offline · no relay answers'), findsOneWidget);

      core.publish([relay('wss://a.example')]);
      await tester.pumpAndSettle();
      expect(find.text('Online · 1/1 relays'), findsOneWidget);
    });

    testWidgets('a pool that never started reads offline and explains', (
      tester,
    ) async {
      await open(tester, FakeRelaysCore(failStart: true));
      expect(find.text('The relays did not start'), findsOneWidget);
    });
  });

  group('Onboarding without a node', () {
    testWidgets('Log in leads to the node selector', (tester) async {
      setSurface(tester, width: 400, height: 900);
      final nodes = FakeNodesCore();
      await pumpApp(
        tester,
        location: AppRoute.welcome,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(
          signedIn: false,
          backend: FakeKeyBackend(),
          nodes: nodes,
        ),
      );
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), sampleNsec);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, log in'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your node'), findsOneWidget);

      await tester.tap(find.text('Mostro'));
      await tester.pumpAndSettle();
      expect(nodes.active, mostroNodePubkey);
      expect(find.text('Pending disputes'), findsOneWidget);
    });

    testWidgets('Pending offers to choose one', (tester) async {
      setSurface(tester, width: 400, height: 900);
      await pumpApp(
        tester,
        location: AppRoute.pending,
        locale: const Locale('en'),
        textScale: 1,
        overrides: fakeCoreOverrides(nodes: FakeNodesCore()),
      );
      await tester.tap(find.text('Choose node'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your node'), findsOneWidget);
      // Opened from a tab, so there is a way back.
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });

  test('a node is named by its name, its region, its brand or its key', () {
    expect(
      nodeDisplayName(
        const MostroNodeEntry(
          pubkey: cubaPubkey,
          region: '🇨🇺 Cuba',
          isTrusted: true,
          isActive: false,
        ),
      ),
      'Cuba',
    );
    expect(
      nodeDisplayName(
        const MostroNodeEntry(
          pubkey: mostroNodePubkey,
          region: '🌐',
          isTrusted: true,
          isActive: false,
        ),
      ),
      'Mostro',
    );
    expect(
      nodeDisplayName(
        const MostroNodeEntry(
          pubkey: customPubkey,
          isTrusted: false,
          isActive: false,
        ),
      ),
      '00000000…0001',
    );
  });
}
