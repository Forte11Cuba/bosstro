import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/services/solver_key_service.dart';

import '../../support/fake_solver_key.dart';

const _key = SolverKeyService.storageKey;
const _other = 'nsec1otherkeyotherkeyotherkey';

void main() {
  late List<String> log;
  late FakeSecretStore store;
  late FakeSolverCore core;
  late SolverKeyService service;

  void setUpWith([Map<String, String>? entries]) {
    log = [];
    store = FakeSecretStore.logging(log, entries);
    core = FakeSolverCore(log);
    service = SolverKeyService(store: store, core: core);
  }

  setUp(setUpWith);

  /// Every buffer handed to Rust was overwritten after the call.
  void expectBuffersWiped() {
    expect(core.buffers, isNotEmpty);
    for (final buffer in core.buffers) {
      expect(buffer.every((b) => b == 0), isTrue, reason: '$buffer');
    }
  }

  test('the storage entry is bosstro_solver_nsec', () {
    expect(SolverKeyService.storageKey, 'bosstro_solver_nsec');
  });

  group('restore', () {
    test('no stored key: null, nothing loaded', () async {
      expect(await service.restore(), isNull);
      expect(core.loaded, isNull);
    });

    test('loads the stored key', () async {
      setUpWith({_key: sampleNsec});
      final info = await service.restore();
      expect(info?.npub, sampleNpub);
      expect(core.loaded, sampleNsec);
      expectBuffersWiped();
    });

    test('an unreadable store is reported and left as it is', () async {
      setUpWith({_key: sampleNsec});
      store.failRead = true;
      expect(service.restore(), throwsA(isA<StoredKeyUnreadable>()));
      expect(store.entries[_key], sampleNsec);
    });

    test('a stored key Rust refuses is reported, not deleted', () async {
      setUpWith({_key: 'garbage'});
      await expectLater(service.restore(), throwsA(isA<StoredKeyUnreadable>()));
      expect(store.entries[_key], 'garbage');
      expect(log, isNot(contains('delete')));
    });
  });

  group('previewNpub', () {
    test('returns the npub without loading or storing', () {
      expect(service.previewNpub(sampleNsec), sampleNpub);
      expect(core.loaded, isNull);
      expect(store.entries, isEmpty);
      expectBuffersWiped();
    });

    test('passes on the marker of a refused key, and still wipes', () {
      expect(
        () => service.previewNpub(sampleNpub),
        throwsA(SolverKeyError.publicKeyGiven),
      );
      expectBuffersWiped();
    });
  });

  group('logIn (the safe replace)', () {
    test('unloads, loads, and only then writes storage', () async {
      final info = await service.logIn(sampleNsec);
      expect(info.npub, sampleNpub);
      expect(log, ['unload', 'load:$sampleNsec', 'write']);
      expect(store.entries[_key], sampleNsec);
      expectBuffersWiped();
    });

    test('stores the key trimmed', () async {
      await service.logIn('  $sampleNsec\n');
      expect(store.entries[_key], sampleNsec);
    });

    test('replaces a loaded key', () async {
      setUpWith({_key: _other});
      await service.restore();
      log.clear();
      await service.logIn(sampleNsec);
      expect(log, ['unload', 'load:$sampleNsec', 'write']);
      expect(core.loaded, sampleNsec);
      expect(store.entries[_key], sampleNsec);
    });

    test('a refused key reloads the previous one and stores nothing', () async {
      setUpWith({_key: _other});
      await service.restore();
      await expectLater(
        service.logIn('not a key'),
        throwsA(SolverKeyError.invalid),
      );
      expect(core.loaded, _other);
      expect(store.entries[_key], _other);
      expect(log, isNot(contains('write')));
    });

    test(
      'a refused write unloads the new key and reloads the previous',
      () async {
        setUpWith({_key: _other});
        await service.restore();
        store.failWrite = true;
        await expectLater(service.logIn(sampleNsec), throwsException);
        expect(core.loaded, _other);
        expect(store.entries[_key], _other);
      },
    );

    test(
      'without a previous key, a refused write leaves none loaded',
      () async {
        store.failWrite = true;
        await expectLater(service.logIn(sampleNsec), throwsException);
        expect(core.loaded, isNull);
        expect(store.entries, isEmpty);
      },
    );
  });

  group('logOut', () {
    test('unloads, then deletes the entry', () async {
      setUpWith({_key: sampleNsec});
      await service.restore();
      log.clear();
      await service.logOut();
      expect(log, ['unload', 'delete']);
      expect(core.loaded, isNull);
      expect(store.entries, isEmpty);
    });

    test('a refused delete loads the key again', () async {
      setUpWith({_key: sampleNsec});
      await service.restore();
      store.failDelete = true;
      await expectLater(service.logOut(), throwsException);
      expect(core.loaded, sampleNsec);
      expect(store.entries[_key], sampleNsec);
    });
  });

  test('readBackup reads the stored secret', () async {
    setUpWith({_key: sampleNsec});
    expect(await service.readBackup(), sampleNsec);
  });

  test('createAccount neither loads nor stores', () {
    final account = service.createAccount();
    expect(account.nsec, sampleNsec);
    expect(core.loaded, isNull);
    expect(store.entries, isEmpty);
  });
}
