import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/font_licenses.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/core/services/storage/app_storage.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/src/rust/api.dart' as rust;
import 'package:bosstro/src/rust/api/nodes.dart' as nodes_api;
import 'package:bosstro/src/rust/api/relays.dart' as relays_api;
import 'package:bosstro/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Loads the Rust core and runs its `frb(init)` functions. Nothing may call
  // into Rust before this completes.
  await RustLib.init();

  // The persistent store (A4): a SQLite file off the web, an IndexedDB
  // database on it. Before anything that reads it. Optional, as in ../app:
  // without it the session runs from memory and the node choice is not kept.
  try {
    await openDatabase(initDb: rust.initDb);
  } catch (e) {
    debugPrint('[startup] database not opened: $e');
  }

  // The active node, before the relay pool starts, so the pool's first
  // `Online` already reads that node's relay list (D5).
  String? activeNode;
  try {
    activeNode = await nodes_api.rehydrateActiveNode();
  } catch (e) {
    debugPrint('[startup] active node not loaded: $e');
  }

  // The relay pool connects in the background; startup does not wait for a
  // relay. Optional: without it the app opens, and the app bar and Settings
  // say the relays are offline.
  try {
    await relays_api.initializeRelays();
  } catch (e) {
    debugPrint('[startup] relay pool not started: $e');
  }

  // Startup: read storage → load into Rust → Welcome or the tabs. Done before
  // the first frame, so the router never shows Welcome to a solver who has a
  // key, nor the tabs to one who has none.
  const service = SolverKeyService();
  SolverKeyInfo? key;
  var unreadable = false;
  try {
    key = await service.restore();
  } on StoredKeyUnreadable catch (e) {
    unreadable = true;
    debugPrint(
      '[startup] stored solver key not loaded: ${e.cause.runtimeType}',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        solverKeyProvider.overrideWith(() => SolverKeyNotifier(key)),
        storedKeyUnreadableProvider.overrideWithValue(unreadable),
        activeNodeProvider.overrideWith(() => ActiveNodeNotifier(activeNode)),
      ],
      // A solver with a key but no node yet (the app closed on the node
      // selector) picks one first.
      child: BosstroApp(
        initialLocation: AppRoute.home(hasNode: activeNode != null),
      ),
    ),
  );
}
