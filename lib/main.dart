import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/app.dart';
import 'package:bosstro/core/font_licenses.dart';
import 'package:bosstro/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Loads the Rust core and runs its `frb(init)` functions. Nothing may call
  // into Rust before this completes.
  await RustLib.init();
  runApp(const ProviderScope(child: BosstroApp()));
}
