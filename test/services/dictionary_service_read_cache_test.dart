/// DictionaryService.readCachedAll 只读查询测试：命中返回、未命中与不合法词返回空
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:echo_loop/services/dictionary_service.dart';

Database _createDb() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE words (
      word TEXT PRIMARY KEY,
      phonetic TEXT NOT NULL,
      translation TEXT,
      collins INTEGER DEFAULT 0,
      tag TEXT
    )
  ''');
  db.execute(
    "INSERT INTO words (word, phonetic, translation, collins, tag) "
    "VALUES ('run', 'rʌn', 'vi. 跑, 奔', 5, 'zk gk cet4')",
  );
  return db;
}

void main() {
  late DictionaryService service;

  setUp(() {
    service = DictionaryService.withDatabase(_createDb());
  });

  tearDown(() {
    service.close();
  });

  test('命中本地词典的词返回词条（大小写不敏感）', () async {
    final result = await service.readCachedAll(['run', 'Run']);

    expect(result.keys, unorderedEquals(['run', 'Run']));
    expect(result['Run']?.word, 'run');
    expect(result['Run']?.translation, 'vi. 跑, 奔');
  });

  test('未收录的词与不合法的多词输入都不返回', () async {
    final result = await service.readCachedAll(['missing', 'two words']);

    expect(result, isEmpty);
  });
}
