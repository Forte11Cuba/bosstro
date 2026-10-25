/// Where the app keeps its own files: the SQLite database (A4).
///
/// Ported from MostroP2P/app's `core/storage/app_data_dir.dart`. Deliberately
/// NOT `getApplicationDocumentsDirectory()` on Linux: that is the user's
/// visible Documents folder. Per the XDG Base Directory spec app state belongs
/// in `$XDG_DATA_HOME` (default `~/.local/share`). Android keeps its documents
/// directory, which is already app-private.
///
/// Native only: the web build gets `app_data_dir_web.dart` through a
/// conditional import (`app_storage.dart`).
library;

import 'dart:io' show Directory, Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Directory name under the Linux data root. Renaming it strands every
/// existing installation's database.
const _appDirName = 'bosstro';

/// The Linux data directory from [env]: `$XDG_DATA_HOME/bosstro`, else
/// `$HOME/.local/share/bosstro`; a relative value is ignored, as the spec
/// says. `null` when neither is usable, so the caller falls back to
/// path_provider instead of guessing. POSIX paths whatever the host.
String? resolveLinuxDataDir(Map<String, String> env) {
  final xdgDataHome = env['XDG_DATA_HOME'];
  if (xdgDataHome != null &&
      xdgDataHome.isNotEmpty &&
      p.posix.isAbsolute(xdgDataHome)) {
    return p.posix.join(xdgDataHome, _appDirName);
  }
  final home = env['HOME'];
  if (home != null && home.isNotEmpty && p.posix.isAbsolute(home)) {
    return p.posix.join(home, '.local', 'share', _appDirName);
  }
  return null;
}

/// Absolute path of the app's data directory, created if missing.
Future<String> appDataDirPath() async {
  if (Platform.isLinux) {
    final resolved = resolveLinuxDataDir(Platform.environment);
    if (resolved != null) {
      try {
        await Directory(resolved).create(recursive: true);
        return resolved;
      } catch (e) {
        debugPrint('[storage] cannot create the data dir: $e — falling back');
      }
    }
  }
  return (await getApplicationDocumentsDirectory()).path;
}
