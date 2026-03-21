import 'package:english_word_app/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'english_word_app.db'));
  });

  test('删除单条错题会同步扣减 wrong_count', () async {
    final db = await AppDatabase.instance.database;
    final words = await db.query('words', limit: 1);
    final wordId = words.first['id'] as int;

    await db.update(
      'words',
      {'wrong_count': 7},
      where: 'id = ?',
      whereArgs: [wordId],
    );
    await db.insert(
      'mistakes',
      {'word_id': wordId, 'type': 'choice', 'count': 3},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final removed = await AppDatabase.instance.deleteMistakeRecord(
      wordId: wordId,
      type: 'choice',
    );

    final updatedWord = await db.query(
      'words',
      columns: ['wrong_count'],
      where: 'id = ?',
      whereArgs: [wordId],
      limit: 1,
    );
    final mistakeRows = await db.query(
      'mistakes',
      where: 'word_id = ? AND type = ?',
      whereArgs: [wordId, 'choice'],
    );

    expect(removed, 3);
    expect(updatedWord.first['wrong_count'], 4);
    expect(mistakeRows, isEmpty);
  });

  test('按类型清空错题会同步扣减对应 wrong_count', () async {
    final db = await AppDatabase.instance.database;
    final words = await db.query('words', orderBy: 'id ASC', limit: 1);
    final wordId = words.first['id'] as int;

    await db.update(
      'words',
      {'wrong_count': 9},
      where: 'id = ?',
      whereArgs: [wordId],
    );
    await db.insert(
      'mistakes',
      {'word_id': wordId, 'type': 'spelling', 'count': 4},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final removed = await AppDatabase.instance.clearMistakesByType('spelling');

    final updatedWord = await db.query(
      'words',
      columns: ['wrong_count'],
      where: 'id = ?',
      whereArgs: [wordId],
      limit: 1,
    );
    final spellingRows = await db.query(
      'mistakes',
      where: 'type = ?',
      whereArgs: ['spelling'],
    );

    expect(removed, 4);
    expect(updatedWord.first['wrong_count'], 5);
    expect(spellingRows, isEmpty);
  });
}
