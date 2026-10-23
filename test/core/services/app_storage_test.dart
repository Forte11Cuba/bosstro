import 'package:flutter_test/flutter_test.dart';

import 'package:bosstro/core/services/storage/app_data_dir.dart';
import 'package:bosstro/core/services/storage/app_storage.dart';

void main() {
  test('the web names the database; native places the file', () {
    expect(databaseLocation(isWeb: true), 'bosstro');
    expect(
      databaseLocation(isWeb: false, dataDir: '/data/app'),
      '/data/app/bosstro.db',
    );
    expect(() => databaseLocation(isWeb: false), throwsArgumentError);
  });

  test('openDatabase hands init_db the platform location', () async {
    final paths = <String>[];
    Future<void> initDb({required String path}) async => paths.add(path);
    await openDatabase(
      initDb: initDb,
      isWeb: true,
      dataDir: () async {
        fail('the web has no data dir');
      },
    );
    await openDatabase(
      initDb: initDb,
      isWeb: false,
      dataDir: () async => '/home/s/.local/share/bosstro',
    );
    expect(paths, ['bosstro', '/home/s/.local/share/bosstro/bosstro.db']);
  });

  test('Linux keeps the database in the XDG data dir, never Documents', () {
    expect(
      resolveLinuxDataDir({'XDG_DATA_HOME': '/x/data', 'HOME': '/home/s'}),
      '/x/data/bosstro',
    );
    expect(
      resolveLinuxDataDir({'XDG_DATA_HOME': 'relative', 'HOME': '/home/s'}),
      '/home/s/.local/share/bosstro',
    );
    expect(resolveLinuxDataDir({'HOME': ''}), isNull);
  });
}
