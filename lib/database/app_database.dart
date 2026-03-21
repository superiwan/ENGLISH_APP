import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/mistake_record.dart';
import '../models/word.dart';
import '../utils/pdf_importer.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;
  final Random _random = Random();
  final RegExp _chineseRegExp = RegExp(r'[\u4e00-\u9fff]');

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'english_word_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT UNIQUE,
            phonetic TEXT,
            meaning TEXT,
            phrase TEXT,
            prefix TEXT,
            suffix TEXT,
            similar_words TEXT,
            synonyms TEXT,
            familiarity INTEGER DEFAULT 0,
            wrong_count INTEGER DEFAULT 0,
            right_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE mistakes (
            word_id INTEGER,
            type TEXT,
            count INTEGER DEFAULT 1,
            PRIMARY KEY (word_id, type),
            FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
          )
        ''');

        await _insertSeedData(db);
      },
    );
  }

  Future<void> _insertSeedData(Database db) async {
    final seedWords = <Word>[
      Word(
        word: 'accumulate',
        phonetic: "ə'kjuːmjuleɪt",
        meaning: '积累',
        phrase: 'accumulate experience',
        prefix: 'ac-',
        suffix: '-ate',
        similarWords: 'stimulate, formulate',
        synonyms: 'collect, gather',
      ),
      Word(
        word: 'improve',
        phonetic: 'ɪmˈpruːv',
        meaning: '提高，改善',
        phrase: 'improve skills',
        prefix: 'im-',
        suffix: '-prove',
        similarWords: 'approve, prove',
        synonyms: 'enhance, boost',
      ),
      Word(
        word: 'analyze',
        phonetic: 'ˈænəlaɪz',
        meaning: '分析',
        phrase: 'analyze data',
        prefix: 'ana-',
        suffix: '-lyze',
        similarWords: 'paralyze, catalyze',
        synonyms: 'examine, inspect',
      ),
      Word(
        word: 'focus',
        phonetic: 'ˈfəʊkəs',
        meaning: '专注',
        phrase: 'focus on goals',
        prefix: null,
        suffix: null,
        similarWords: 'focuse (mistyped)',
        synonyms: 'concentrate',
      ),
      Word(
        word: 'maintain',
        phonetic: 'meɪnˈteɪn',
        meaning: '维持，保持',
        phrase: 'maintain balance',
        prefix: 'main-',
        suffix: '-tain',
        similarWords: 'obtain, retain',
        synonyms: 'preserve, sustain',
      ),
    ];

    for (final word in seedWords) {
      await db.insert(
        'words',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> insertWord(Word word) async {
    final db = await database;
    final cleaned = PdfImporter.normalizeImportedWord(word);
    return db.insert(
      'words',
      cleaned.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Word>> getAllWords() async {
    final db = await database;
    final rows = await db.query('words', orderBy: 'word COLLATE NOCASE ASC');
    return rows.map(Word.fromMap).toList();
  }

  Future<Word?> getWordById(int id) async {
    final db = await database;
    final rows =
        await db.query('words', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return Word.fromMap(rows.first);
  }

  Future<Word?> pickPriorityWord({List<int> excludedWordIds = const []}) async {
    final db = await database;
    final uniqueExcluded = excludedWordIds.toSet().toList();
    final hasExcluded = uniqueExcluded.isNotEmpty;
    final placeholders =
        hasExcluded ? List.filled(uniqueExcluded.length, '?').join(',') : '';
    final where = hasExcluded
        ? 'wrong_count > 0 AND id NOT IN ($placeholders)'
        : 'wrong_count > 0';
    final whereArgs = hasExcluded ? List<Object?>.from(uniqueExcluded) : null;
    final candidates = await db.query(
      'words',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'wrong_count DESC, RANDOM()',
      limit: 50,
    );

    final validCandidates = candidates
        .map(Word.fromMap)
        .where((w) => _isValidMeaning(w.meaning))
        .toList();
    if (validCandidates.isNotEmpty) {
      return validCandidates.first;
    }

    final randomWords = !hasExcluded
        ? await db.rawQuery('SELECT * FROM words ORDER BY RANDOM() LIMIT 200')
        : await db.rawQuery(
            'SELECT * FROM words WHERE id NOT IN ($placeholders) ORDER BY RANDOM() LIMIT 200',
            uniqueExcluded,
          );
    for (final row in randomWords) {
      final word = Word.fromMap(row);
      if (_isValidMeaning(word.meaning)) {
        return word;
      }
    }
    if (hasExcluded) {
      return pickPriorityWord();
    }
    return null;
  }

  Future<List<Word>> getRandomWordsExcept(int excludedId, int count) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM words WHERE id != ? ORDER BY RANDOM() LIMIT ?',
      [excludedId, count],
    );
    return rows.map(Word.fromMap).toList();
  }

  Future<void> recordChoiceResult(
      {required int wordId, required bool isCorrect}) async {
    if (isCorrect) {
      await _updateWordStats(wordId, familiarityDelta: 10, rightDelta: 1);
    } else {
      await _updateWordStats(wordId, familiarityDelta: -15, wrongDelta: 1);
      await _upsertMistake(wordId: wordId, type: 'choice');
    }
  }

  Future<void> recordSpellingResult(
      {required int wordId, required bool isCorrect}) async {
    if (isCorrect) {
      await _updateWordStats(wordId, familiarityDelta: 10, rightDelta: 1);
    } else {
      await _updateWordStats(wordId, familiarityDelta: -15, wrongDelta: 1);
      await _upsertMistake(wordId: wordId, type: 'spelling');
    }
  }

  Future<void> _updateWordStats(
    int wordId, {
    required int familiarityDelta,
    int wrongDelta = 0,
    int rightDelta = 0,
  }) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE words
      SET
        familiarity = MAX(0, familiarity + ?),
        wrong_count = MAX(0, wrong_count + ?),
        right_count = MAX(0, right_count + ?)
      WHERE id = ?
      ''',
      [familiarityDelta, wrongDelta, rightDelta, wordId],
    );
  }

  Future<void> _upsertMistake(
      {required int wordId, required String type}) async {
    final db = await database;
    await db.rawInsert(
      '''
      INSERT INTO mistakes (word_id, type, count)
      VALUES (?, ?, 1)
      ON CONFLICT(word_id, type)
      DO UPDATE SET count = count + 1
      ''',
      [wordId, type],
    );
  }

  Future<List<MistakeRecord>> getMistakes() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT m.word_id, m.type, m.count, w.word, w.meaning
      FROM mistakes m
      INNER JOIN words w ON w.id = m.word_id
      ORDER BY m.count DESC, w.word COLLATE NOCASE ASC
    ''');
    return rows.map(MistakeRecord.fromMap).toList();
  }

  Future<int> deleteMistakeRecord({
    required int wordId,
    required String type,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT count FROM mistakes WHERE word_id = ? AND type = ? LIMIT 1',
        [wordId, type],
      );
      if (rows.isEmpty) {
        return 0;
      }

      final count = (rows.first['count'] as int?) ?? 0;
      await txn.delete(
        'mistakes',
        where: 'word_id = ? AND type = ?',
        whereArgs: [wordId, type],
      );
      await txn.rawUpdate(
        '''
        UPDATE words
        SET wrong_count = MAX(0, wrong_count - ?)
        WHERE id = ?
        ''',
        [count, wordId],
      );
      return count;
    });
  }

  Future<int> clearMistakesByType(String type) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT word_id, count FROM mistakes WHERE type = ?',
        [type],
      );
      if (rows.isEmpty) {
        return 0;
      }

      var removedCount = 0;
      for (final row in rows) {
        final wordId = row['word_id'] as int;
        final count = (row['count'] as int?) ?? 0;
        await txn.delete(
          'mistakes',
          where: 'word_id = ? AND type = ?',
          whereArgs: [wordId, type],
        );
        await txn.rawUpdate(
          '''
          UPDATE words
          SET wrong_count = MAX(0, wrong_count - ?)
          WHERE id = ?
          ''',
          [count, wordId],
        );
        removedCount += count;
      }
      return removedCount;
    });
  }

  Future<Map<String, num>> getProgressStats() async {
    final db = await database;
    final totalRow = await db.rawQuery('SELECT COUNT(*) AS total FROM words');
    final practicedRow = await db.rawQuery(
      'SELECT COUNT(*) AS practiced FROM words WHERE right_count > 0 OR wrong_count > 0',
    );
    final masteredRow = await db.rawQuery(
      'SELECT COUNT(*) AS mastered FROM words WHERE familiarity > 80',
    );
    final sumRow = await db.rawQuery(
      'SELECT IFNULL(SUM(right_count), 0) AS right_total, IFNULL(SUM(wrong_count), 0) AS wrong_total FROM words',
    );

    final total = (totalRow.first['total'] as int?) ?? 0;
    final practiced = (practicedRow.first['practiced'] as int?) ?? 0;
    final mastered = (masteredRow.first['mastered'] as int?) ?? 0;
    final rightTotal = (sumRow.first['right_total'] as int?) ?? 0;
    final wrongTotal = (sumRow.first['wrong_total'] as int?) ?? 0;

    final attempts = rightTotal + wrongTotal;
    final accuracy = attempts == 0 ? 0.0 : rightTotal / attempts;

    return {
      'total': total,
      'practiced': practiced,
      'mastered': mastered,
      'accuracy': accuracy,
    };
  }

  Future<int> importWords(List<Word> words,
      {void Function(int, int)? onProgress}) async {
    final db = await database;
    var success = 0;

    await db.transaction((txn) async {
      for (var i = 0; i < words.length; i++) {
        final current = PdfImporter.normalizeImportedWord(words[i]);
        if (!_isValidMeaning(current.meaning)) {
          onProgress?.call(i + 1, words.length);
          continue;
        }
        await txn.rawInsert(
          '''
          INSERT INTO words (
            word, phonetic, meaning, phrase, prefix, suffix, similar_words, synonyms,
            familiarity, wrong_count, right_count
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0)
          ON CONFLICT(word) DO UPDATE SET
            phonetic = CASE
              WHEN excluded.phonetic IS NOT NULL AND LENGTH(TRIM(excluded.phonetic)) > 0 THEN excluded.phonetic
              ELSE words.phonetic
            END,
            meaning = CASE
              WHEN LENGTH(TRIM(excluded.meaning)) > 0 THEN excluded.meaning
              ELSE words.meaning
            END
          ''',
          [
            current.word,
            current.phonetic,
            current.meaning,
            current.phrase,
            current.prefix,
            current.suffix,
            current.similarWords,
            current.synonyms,
          ],
        );
        success++;

        onProgress?.call(i + 1, words.length);
      }
    });

    return success;
  }

  Future<int> normalizeExistingWords() async {
    final db = await database;
    final rows = await db.query('words');
    var updated = 0;
    await db.transaction((txn) async {
      for (final row in rows) {
        final original = Word.fromMap(row);
        final cleaned = PdfImporter.normalizeImportedWord(original);
        if (cleaned.phonetic == original.phonetic &&
            cleaned.meaning == original.meaning) {
          continue;
        }
        await txn.update(
          'words',
          {
            'phonetic': cleaned.phonetic,
            'meaning': cleaned.meaning,
          },
          where: 'id = ?',
          whereArgs: [original.id],
        );
        updated++;
      }
    });
    return updated;
  }

  Future<List<String>> buildOptionsForWord(Word answerWord) async {
    if (answerWord.id == null) {
      return [answerWord.meaning];
    }

    final distractors = await getRandomWordsExcept(answerWord.id!, 10);
    final unique = <String>{};
    final options = <String>[answerWord.meaning];

    for (final word in distractors) {
      if (!_isValidMeaning(word.meaning)) {
        continue;
      }
      if (word.meaning == answerWord.meaning) {
        continue;
      }
      if (!unique.add(word.meaning)) {
        continue;
      }
      options.add(word.meaning);
      if (options.length == 4) {
        break;
      }
    }

    while (options.length < 4 && options.isNotEmpty) {
      options.add(options[_random.nextInt(options.length)]);
    }

    options.shuffle(_random);
    return options;
  }

  bool _isValidMeaning(String meaning) {
    return _chineseRegExp.hasMatch(meaning);
  }
}
