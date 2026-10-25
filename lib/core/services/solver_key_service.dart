import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bosstro/src/rust/api/solver.dart' as rust;

export 'package:bosstro/src/rust/api/solver.dart'
    show NewSolverAccount, SolverKeyError, SolverKeyInfo;

/// Where the solver's secret lives on the phone: one entry of secure
/// storage. An interface so tests run on a map.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// The app's one [FlutterSecureStorage] (AGENTS.md → "Key handling").
///
/// v10's default Android options: Keystore-backed ciphers, not the
/// deprecated `encryptedSharedPreferences`. `resetOnError` is off: on a
/// decryption error the plugin's default wipes the whole store, which here
/// is the solver's only key. The error reaches the app instead, which asks
/// for the key again without deleting anything.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The Rust side of the key, behind an interface so tests need no native
/// library.
abstract interface class SolverCore {
  rust.NewSolverAccount createAccount();
  String previewNpub(Uint8List secret);
  Future<rust.SolverKeyInfo> load(Uint8List secret);
  Future<bool> unload();
}

class RustSolverCore implements SolverCore {
  const RustSolverCore();

  @override
  rust.NewSolverAccount createAccount() => rust.createSolverAccount();

  @override
  String previewNpub(Uint8List secret) => rust.previewNpub(secret: secret);

  @override
  Future<rust.SolverKeyInfo> load(Uint8List secret) =>
      rust.loadSolverKey(secret: secret);

  @override
  Future<bool> unload() => rust.unloadSolverKey();
}

/// The stored key could not be read or loaded at startup. Nothing was
/// deleted; the solver is asked to log in again.
class StoredKeyUnreadable implements Exception {
  const StoredKeyUnreadable(this.cause);

  final Object cause;

  @override
  String toString() => 'StoredKeyUnreadable($cause)';
}

/// The solver's key: secure storage on the Dart side, the parsed key in
/// Rust's `SolverSlot`.
///
/// The secret crosses the bridge as bytes, never as a `String`, and the
/// buffer is overwritten right after each call ([_withSecretBytes]). The
/// Strings it comes from — the text field, the clipboard, the storage plugin
/// — are immutable in Dart and live until collected; that limit is accepted,
/// as is the key living in Rust's memory while the app runs.
class SolverKeyService {
  const SolverKeyService({
    SecretStore store = const SecureSecretStore(),
    SolverCore core = const RustSolverCore(),
  }) : _store = store,
       _core = core;

  /// The secure-storage entry that holds the nsec, as the solver gave it
  /// (bech32 or hex).
  static const storageKey = 'bosstro_solver_nsec';

  final SecretStore _store;
  final SolverCore _core;

  /// Startup: the stored key, loaded into Rust; null when there is none.
  ///
  /// Throws [StoredKeyUnreadable] when the entry cannot be read, or holds
  /// something Rust refuses. The entry is left as it is.
  Future<rust.SolverKeyInfo?> restore() async {
    final String? stored;
    try {
      stored = await _store.read(storageKey);
    } catch (e) {
      throw StoredKeyUnreadable(e);
    }
    if (stored == null) return null;
    try {
      return await _load(stored);
    } catch (e) {
      throw StoredKeyUnreadable(e);
    }
  }

  /// A new key, not loaded and not stored: Create new account shows it for
  /// backup first, then hands it to [logIn].
  rust.NewSolverAccount createAccount() => _core.createAccount();

  /// The npub [secret] stands for, without loading it. Throws a
  /// [rust.SolverKeyError] when it is not a secret key.
  String previewNpub(String secret) =>
      _withSecretBytes(secret, _core.previewNpub);

  /// Makes [secret] the solver key: the safe replace of MostroP2P/app's
  /// `IdentityService._replaceLoadedIdentity`.
  ///
  /// Unload the key Rust holds, load the new one, and only then write
  /// storage. When the load or the write fails, the key storage still holds
  /// is loaded again before the error goes on, so the session is never left
  /// without the key it had.
  Future<rust.SolverKeyInfo> logIn(String secret) async {
    final previous = await _readOrNull();
    await _core.unload();
    final rust.SolverKeyInfo info;
    try {
      info = await _load(secret);
    } catch (_) {
      await _reload(previous);
      rethrow;
    }
    try {
      await _store.write(storageKey, secret.trim());
    } catch (_) {
      await _core.unload();
      await _reload(previous);
      rethrow;
    }
    return info;
  }

  /// Removes the key from Rust and from the phone. When storage refuses the
  /// delete, the key is loaded again, so what Rust holds and what storage
  /// holds never disagree.
  Future<void> logOut() async {
    final previous = await _readOrNull();
    await _core.unload();
    try {
      await _store.delete(storageKey);
    } catch (_) {
      await _reload(previous);
      rethrow;
    }
  }

  /// The stored secret, for Settings → Backup.
  Future<String?> readBackup() => _store.read(storageKey);

  Future<rust.SolverKeyInfo> _load(String secret) =>
      _withSecretBytesAsync(secret, _core.load);

  Future<String?> _readOrNull() async {
    try {
      return await _store.read(storageKey);
    } catch (_) {
      return null;
    }
  }

  /// Loads [previous] again after a refused replacement. Never throws: the
  /// caller reports the refusal that brought it here.
  Future<void> _reload(String? previous) async {
    if (previous == null) return;
    try {
      await _core.unload();
      await _load(previous);
    } catch (e) {
      debugPrint('[solver-key] previous key not reloaded: ${e.runtimeType}');
    }
  }
}

/// Hands [secret] to [use] as UTF-8 bytes and overwrites them afterwards,
/// whatever [use] does.
T _withSecretBytes<T>(String secret, T Function(Uint8List) use) {
  final bytes = utf8.encode(secret);
  try {
    return use(bytes);
  } finally {
    bytes.fillRange(0, bytes.length, 0);
  }
}

Future<T> _withSecretBytesAsync<T>(
  String secret,
  Future<T> Function(Uint8List) use,
) async {
  final bytes = utf8.encode(secret);
  try {
    return await use(bytes);
  } finally {
    bytes.fillRange(0, bytes.length, 0);
  }
}
