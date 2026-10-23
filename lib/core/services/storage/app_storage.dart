import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:bosstro/core/services/storage/app_data_dir.dart'
    if (dart.library.js_interop) 'package:bosstro/core/services/storage/app_data_dir_web.dart';

/// Where the Rust core keeps its persistent store (A4), from ../app's
/// `core/storage/db_location.dart`.
///
/// On native platforms `init_db` takes a file path inside the app data
/// directory; on the web the same argument names the IndexedDB database.
const String webDatabaseName = 'bosstro';
const String databaseFileName = 'bosstro.db';

/// The `init_db` argument for this platform. [dataDir] is required off the
/// web.
String databaseLocation({required bool isWeb, String? dataDir}) {
  if (isWeb) return webDatabaseName;
  if (dataDir == null || dataDir.isEmpty) {
    throw ArgumentError.value(dataDir, 'dataDir', 'required off the web');
  }
  return '$dataDir/$databaseFileName';
}

/// Opens the persistent store on every platform. [initDb] is
/// `rust.initDb` in the app; an argument so this runs in a test without
/// Rust. [dataDir] is not called on the web.
Future<void> openDatabase({
  required Future<void> Function({required String path}) initDb,
  bool isWeb = kIsWeb,
  Future<String> Function() dataDir = appDataDirPath,
}) async {
  await initDb(
    path: databaseLocation(
      isWeb: isWeb,
      dataDir: isWeb ? null : await dataDir(),
    ),
  );
}
