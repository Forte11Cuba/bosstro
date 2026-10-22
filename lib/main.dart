import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/font_licenses.dart';
import 'package:bosstro/core/services/solver_key_service.dart';
import 'package:bosstro/features/solver_key/providers/solver_key_providers.dart';
import 'package:bosstro/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Loads the Rust core and runs its `frb(init)` functions. Nothing may call
  // into Rust before this completes.
  await RustLib.init();

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
      ],
      child: const BosstroApp(),
    ),
  );
}
