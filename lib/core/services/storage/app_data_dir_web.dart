/// The web has no file system: the database is named, not placed
/// (`app_storage.dart`). Mirrors `app_data_dir.dart` so the conditional
/// import compiles.
library;

Future<String> appDataDirPath() async {
  throw UnsupportedError('appDataDirPath is not supported on the web');
}
