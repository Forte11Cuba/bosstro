import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/src/rust/api.dart' as rust;

/// The app version, as the Rust core reports it. Widget tests override it,
/// since they run without the native library.
final appVersionProvider = Provider<String>((ref) => rust.appVersion());

/// The commit this build was made from, `--dart-define=GIT_COMMIT` (the
/// release workflow passes it, docs/RELEASING.md); empty for a build that set
/// none. About shows it under the version, as ../app.
final appCommitProvider = Provider<String>(
  (ref) => const String.fromEnvironment('GIT_COMMIT'),
);
