import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bosstro/core/services/solver_key_service.dart';

/// NIP-19's example pair: a real nsec and the npub it stands for. The fake
/// core maps between them like Rust would.
const sampleNsec =
    'nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5';
const sampleNpub =
    'npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg';
const sampleKey = SolverKeyInfo(
  npub: sampleNpub,
  publicKeyHex:
      '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e',
);

/// Secure storage on a map, with a switch per operation to make it fail.
class FakeSecretStore implements SecretStore {
  FakeSecretStore([Map<String, String>? entries])
    : entries = entries ?? {},
      log = [];

  final Map<String, String> entries;
  final List<String> log;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;

  FakeSecretStore.logging(this.log, [Map<String, String>? entries])
    : entries = entries ?? {};

  @override
  Future<String?> read(String key) async {
    if (failRead) throw Exception('read refused');
    return entries[key];
  }

  @override
  Future<void> write(String key, String value) async {
    log.add('write');
    if (failWrite) throw Exception('write refused');
    entries[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    log.add('delete');
    if (failDelete) throw Exception('delete refused');
    entries.remove(key);
  }
}

/// Rust's side, in Dart: a secret starting with `nsec1` (or 64 hex
/// characters) parses; `npub1…` is the wrong key; anything else is invalid.
/// It records each call and keeps every buffer it was handed, to check they
/// were wiped.
class FakeSolverCore implements SolverCore {
  FakeSolverCore(this.log);

  final List<String> log;
  final List<Uint8List> buffers = [];
  String? loaded;
  bool failLoad = false;

  static String npubFor(String secret) =>
      secret == sampleNsec ? sampleNpub : 'npub1${secret.hashCode.abs()}';

  String _parse(Uint8List bytes) {
    buffers.add(bytes);
    final text = utf8.decode(bytes).trim();
    if (text.isEmpty) throw SolverKeyError.empty;
    if (text.startsWith('npub1')) throw SolverKeyError.publicKeyGiven;
    if (!text.startsWith('nsec1') &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(text)) {
      throw SolverKeyError.invalid;
    }
    return text;
  }

  @override
  NewSolverAccount createAccount() =>
      const NewSolverAccount(nsec: sampleNsec, npub: sampleNpub);

  @override
  String previewNpub(Uint8List secret) => npubFor(_parse(secret));

  @override
  Future<SolverKeyInfo> load(Uint8List secret) async {
    final text = _parse(secret);
    log.add('load:$text');
    if (failLoad) throw SolverKeyError.invalid;
    if (loaded != null) throw SolverKeyError.alreadyLoaded;
    loaded = text;
    final npub = npubFor(text);
    return SolverKeyInfo(npub: npub, publicKeyHex: 'hex:$npub');
  }

  @override
  Future<bool> unload() async {
    log.add('unload');
    final had = loaded != null;
    loaded = null;
    return had;
  }
}
