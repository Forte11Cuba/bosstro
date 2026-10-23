import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_theme.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/chat/providers/chat_providers.dart';
import 'package:bosstro/features/disputes/providers/pending_providers.dart';
import 'package:bosstro/features/nodes/models/node_display.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/nodes/providers/relay_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/l10n/app_localizations.dart';
import 'package:bosstro/shared/providers/core_providers.dart';
import 'package:bosstro/shared/providers/device_security_providers.dart';

import 'fake_chat.dart';
import 'fake_device_security.dart';
import 'fake_disputes.dart';
import 'fake_nodes.dart';
import 'fake_solver_key.dart';

export 'fake_chat.dart';
export 'fake_device_security.dart';
export 'fake_disputes.dart';
export 'fake_nodes.dart';
export 'fake_solver_key.dart';

/// The version the fake Rust core reports.
const fakeAppVersion = '0.1.0';

/// The fakes behind one pumped app: storage on a map and Rust in Dart.
class FakeKeyBackend {
  factory FakeKeyBackend({Map<String, String>? stored, bool loaded = false}) {
    final log = <String>[];
    final backend = FakeKeyBackend._(
      log,
      FakeSecretStore.logging(log, stored),
      FakeSolverCore(log),
    );
    if (loaded) backend.core.loaded = stored?[SolverKeyService.storageKey];
    return backend;
  }

  FakeKeyBackend._(this.log, this.store, this.core);

  /// Every store and core operation, in order.
  final List<String> log;
  final FakeSecretStore store;
  final FakeSolverCore core;

  SolverKeyService get service => SolverKeyService(store: store, core: core);
}

/// Overrides for everything that would call into the native library, which
/// widget tests run without. Signed in with [sampleKey] unless [signedIn]
/// is false; on the Mostro node unless [nodes] says otherwise (pass a
/// `FakeNodesCore()` for a solver who has not chosen one). The dispute feed
/// has answered with no pending dispute unless [disputes] says otherwise.
List<Override> fakeCoreOverrides({
  bool signedIn = true,
  FakeKeyBackend? backend,
  bool storedKeyUnreadable = false,
  FakeDeviceSecurity? device,
  FakeNodesCore? nodes,
  FakeRelaysCore? relays,
  FakeDisputesCore? disputes,
  FakeChatCore? chat,
}) {
  final nodeCore = nodes ?? FakeNodesCore(active: mostroNodePubkey);
  final keys =
      backend ??
      FakeKeyBackend(
        stored: signedIn ? {SolverKeyService.storageKey: sampleNsec} : null,
        loaded: signedIn,
      );
  return [
    appVersionProvider.overrideWithValue(fakeAppVersion),
    solverKeyServiceProvider.overrideWithValue(keys.service),
    solverKeyProvider.overrideWith(
      () => SolverKeyNotifier(signedIn ? sampleKey : null),
    ),
    storedKeyUnreadableProvider.overrideWithValue(storedKeyUnreadable),
    deviceSecurityProvider.overrideWithValue(device ?? FakeDeviceSecurity()),
    nodesCoreProvider.overrideWithValue(nodeCore),
    activeNodeProvider.overrideWith(() => ActiveNodeNotifier(nodeCore.active)),
    relaysCoreProvider.overrideWithValue(relays ?? FakeRelaysCore()),
    disputesCoreProvider.overrideWithValue(
      disputes ??
          FakeDisputesCore(node: null, followNode: () => nodeCore.active),
    ),
    chatCoreProvider.overrideWithValue(chat ?? FakeChatCore()),
  ];
}

/// Sets the test surface to [width] × [height] logical pixels.
void setSurface(
  WidgetTester tester, {
  double width = 320,
  double height = 640,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Pumps the whole app at [location], in [locale], [brightness] and
/// [textScale] — the DS-A11Y-4 conditions.
Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  Locale locale = const Locale('es'),
  Brightness brightness = Brightness.dark,
  double textScale = 2,
  List<Override>? overrides,
  bool settle = true,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? fakeCoreOverrides(),
      child: BosstroApp(
        initialLocation: location,
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps [child] alone in a themed, localized app.
Future<void> pumpWidgetAlone(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeCoreOverrides(),
      child: MaterialApp(
        theme:
            brightness == Brightness.dark
                ? buildDarkTheme()
                : buildLightTheme(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
