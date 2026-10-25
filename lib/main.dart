import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/app_routes.dart';
import 'package:bosstro/core/font_licenses.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/core/services/storage/app_storage.dart';
import 'package:bosstro/core/startup_sequence.dart';
import 'package:bosstro/features/nodes/providers/node_providers.dart';
import 'package:bosstro/features/settings/providers/language_provider.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/src/rust/api.dart' as rust;
import 'package:bosstro/src/rust/api/nodes.dart' as nodes_api;
import 'package:bosstro/src/rust/api/relays.dart' as relays_api;
import 'package:bosstro/src/rust/api/settings.dart' as settings_api;
import 'package:bosstro/src/rust/frb_generated.dart';

/// A step that throws before the first frame paints the startup failure
/// screen, naming the step, instead of leaving a blank one
/// (`lib/core/startup_sequence.dart`).
Future<void> main() => runGuarded(_startup);

Future<void> _startup(StartupSequence startup) async {
  WidgetsFlutterBinding.ensureInitialized();
  await startup.optional(
    'registering font licenses',
    () async => registerFontLicenses(),
  );
  // Loads the Rust core and runs its `frb(init)` functions. Nothing may call
  // into Rust before this completes, so nothing opens without it.
  await startup.required('loading the engine', () => RustLib.init());

  // The persistent store (A4): a SQLite file off the web, an IndexedDB
  // database on it. Before anything that reads it. Optional, as in ../app:
  // without it the session runs from memory and the node choice is not kept.
  await startup.optional(
    'opening the local database',
    () => openDatabase(initDb: rust.initDb),
  );

  // The chosen language, before the first frame: the app never opens in
  // one language and turns to another. None: the system's.
  String? language;
  await startup.optional('reading your language', () async {
    language = await settings_api.getLanguage();
  });

  // The active node, before the relay pool starts, so the pool's first
  // `Online` already reads that node's relay list (D5).
  String? activeNode;
  await startup.optional('selecting your node', () async {
    activeNode = await nodes_api.rehydrateActiveNode();
  });

  // The relay pool connects in the background; startup does not wait for a
  // relay. Optional: without it the app opens, and the app bar and Settings
  // say the relays are offline.
  await startup.optional(
    'starting the relay connections',
    () => relays_api.initializeRelays(),
  );

  // Startup: read storage → load into Rust → Welcome or the tabs. Done before
  // the first frame, so the router never shows Welcome to a solver who has a
  // key, nor the tabs to one who has none. An unreadable key is not a
  // failure: Welcome says so and the entry is left as it is.
  const service = SolverKeyService();
  SolverKeyInfo? key;
  var unreadable = false;
  await startup.required('reading your secret key', () async {
    try {
      key = await service.restore();
    } on StoredKeyUnreadable catch (e) {
      unreadable = true;
      debugPrint(
        '[startup] stored solver key not loaded: ${e.cause.runtimeType}',
      );
    }
  });

  startup.currentStep = 'building the interface';
  runApp(
    ProviderScope(
      overrides: [
        solverKeyProvider.overrideWith(() => SolverKeyNotifier(key)),
        storedKeyUnreadableProvider.overrideWithValue(unreadable),
        activeNodeProvider.overrideWith(() => ActiveNodeNotifier(activeNode)),
        languageProvider.overrideWith(() => LanguageNotifier(language)),
      ],
      // A solver with a key but no node yet (the app closed on the node
      // selector) picks one first.
      child: BosstroApp(
        initialLocation: AppRoute.home(hasNode: activeNode != null),
      ),
    ),
  );
}
