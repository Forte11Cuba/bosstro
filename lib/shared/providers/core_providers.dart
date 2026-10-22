import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/src/rust/api.dart' as rust;

/// The app version, as the Rust core reports it. Widget tests override it,
/// since they run without the native library.
final appVersionProvider = Provider<String>((ref) => rust.appVersion());
