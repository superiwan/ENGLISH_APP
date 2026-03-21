import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../widgets/word_list_item.dart';
import 'word_detail_page.dart';

enum WordBookModuleType {
  similarWords,
  synonyms,
  prefix,
  suffix,
  allWords,
}

extension WordBookModuleTypeX on WordBookModuleType {
  String get title => switch (this) {
        WordBookModuleType.similarWords => '形近词',
        WordBookModuleType.synonyms => '同义词',
        WordBookModuleType.prefix => '前缀相同',
        WordBookModuleType.suffix => '后缀相同',
        WordBookModuleType.allWords => '全部单词',
      };

  String get description => switch (this) {
        WordBookModuleType.similarWords => '自动按词形结构分组',
        WordBookModuleType.synonyms => '自动按中文释义关键词分组',
        WordBookModuleType.prefix => '自动按前缀分组',
        WordBookModuleType.suffix => '自动按后缀分组',
        WordBookModuleType.allWords => '按首字母分组查看全部单词',
      };

  IconData get icon => switch (this) {
        WordBookModuleType.similarWords => Icons.compare_arrows,
        WordBookModuleType.synonyms => Icons.translate,
        WordBookModuleType.prefix => Icons.text_fields,
        WordBookModuleType.suffix => Icons.segment,
        WordBookModuleType.allWords => Icons.library_books,
      };
}

class WordGroupSection {
  WordGroupSection({
    required this.label,
    required this.words,
  });

  final String label;
  final List<Word> words;
}

final RegExp _splitterRegExp = RegExp(r'[,，;；、/|]+|\s+');
final RegExp _zhWordRegExp = RegExp(r'[\u4e00-\u9fff]{1,6}');

List<WordGroupSection> buildWordGroups(
    List<Word> words, WordBookModuleType module) {
  final map = <String, List<Word>>{};
  for (final word in words) {
    final keys = _groupKeysForWord(word, module);
    for (final key in keys) {
      final list = map.putIfAbsent(key, () => <Word>[]);
      if (!_containsWord(list, word)) {
        list.add(word);
      }
    }
  }

  final sections = map.entries
      .map(
        (entry) => WordGroupSection(
          label: entry.key,
          words: _sortWords(entry.value),
        ),
      )
      .toList();

  sections.sort((a, b) {
    final sizeCompare = b.words.length.compareTo(a.words.length);
    if (sizeCompare != 0) {
      return sizeCompare;
    }
    return a.label.compareTo(b.label);
  });
  return sections;
}

int moduleWordCount(List<Word> words, WordBookModuleType module) {
  if (module == WordBookModuleType.allWords) {
    return words.length;
  }
  // 自动分类模式下，四个模块都覆盖全量单词。
  return words.length;
}

List<String> _groupKeysForWord(Word word, WordBookModuleType module) {
  switch (module) {
    case WordBookModuleType.prefix:
      final explicit = _normalizedPieces(word.prefix, trimDash: true);
      if (explicit.isNotEmpty) {
        return explicit;
      }
      final auto =
          word.word.length >= 3 ? word.word.substring(0, 3) : word.word;
      return ['前缀 $auto'];
    case WordBookModuleType.suffix:
      final explicit = _normalizedPieces(word.suffix, trimDash: true);
      if (explicit.isNotEmpty) {
        return explicit;
      }
      final auto = word.word.length >= 3
          ? word.word.substring(word.word.length - 3)
          : word.word;
      return ['后缀 $auto'];
    case WordBookModuleType.synonyms:
      final explicit = _normalizedPieces(word.synonyms);
      if (explicit.isNotEmpty) {
        return explicit;
      }
      final zhTokens = _extractMeaningTokens(word.meaning);
      if (zhTokens.isNotEmpty) {
        return ['义类 ${zhTokens.first}'];
      }
      return ['义类 其他'];
    case WordBookModuleType.similarWords:
      final explicit = _normalizedPieces(word.similarWords);
      if (explicit.isNotEmpty) {
        return explicit;
      }
      return ['词形 ${_wordShape(word.word)}'];
    case WordBookModuleType.allWords:
      final first = word.word.isEmpty ? '#' : word.word[0].toUpperCase();
      final label = RegExp(r'[A-Z]').hasMatch(first) ? first : '其他';
      return ['字母 $label'];
  }
}

List<String> _normalizedPieces(String? raw, {bool trimDash = false}) {
  if (raw == null || raw.trim().isEmpty) {
    return const <String>[];
  }

  final set = <String>{};
  for (final part in raw.split(_splitterRegExp)) {
    var token = part.trim().toLowerCase();
    token = token.replaceAll(RegExp("[()\\[\\]{}<>《》“”\"'`]+"), '');
    token = token.replaceAll(RegExp(r'\.+$'), '');
    if (trimDash) {
      token = token.replaceAll(RegExp(r'^-+|-+$'), '');
    }
    if (token.isEmpty) {
      continue;
    }
    set.add(token);
  }
  final list = set.toList();
  list.sort();
  return list;
}

List<String> _extractMeaningTokens(String meaning) {
  final matches = _zhWordRegExp.allMatches(meaning);
  final set = <String>{};
  for (final match in matches) {
    final token = match.group(0)?.trim() ?? '';
    if (token.length < 2) {
      continue;
    }
    set.add(token);
    if (set.length >= 3) {
      break;
    }
  }
  return set.toList();
}

String _wordShape(String word) {
  if (word.isEmpty) {
    return '其他';
  }
  var normalized = word.toLowerCase();
  normalized = normalized.replaceAll(RegExp(r'[aeiou]'), '_');
  if (normalized.length >= 6) {
    return '${normalized.substring(0, 3)}...${normalized.substring(normalized.length - 2)}';
  }
  return normalized;
}

List<Word> _sortWords(List<Word> words) {
  final cloned = List<Word>.from(words);
  cloned.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
  return cloned;
}

bool _containsWord(List<Word> words, Word target) {
  for (final item in words) {
    if (item.id != null && target.id != null && item.id == target.id) {
      return true;
    }
    if (item.word == target.word) {
      return true;
    }
  }
  return false;
}

class WordBookModulePage extends StatefulWidget {
  const WordBookModulePage({
    super.key,
    required this.module,
  });

  final WordBookModuleType module;

  @override
  State<WordBookModulePage> createState() => _WordBookModulePageState();
}

class _WordBookModulePageState extends State<WordBookModulePage> {
  late Future<List<Word>> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _wordsFuture = AppDatabase.instance.getAllWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.module.title}（自动分类）')),
      body: FutureBuilder<List<Word>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data ?? [];
          if (words.isEmpty) {
            return const Center(child: Text('暂无单词，请先导入 PDF。'));
          }

          final groups = buildWordGroups(words, widget.module);
          if (groups.isEmpty) {
            return const Center(child: Text('暂无可分组数据。'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupLineSection(
                label: group.label,
                words: group.words,
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupLineSection extends StatelessWidget {
  const _GroupLineSection({
    required this.label,
    required this.words,
  });

  final String label;
  final List<Word> words;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '(${words.length})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final word in words)
            WordListItem(
              dense: true,
              title: word.word,
              subtitle: _subtitle(word),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final id = word.id;
                if (id == null) {
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WordDetailPage(wordId: id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _subtitle(Word word) {
    final parts = <String>[
      if (word.phonetic.trim().isNotEmpty) word.phonetic,
      if (word.meaning.trim().isNotEmpty) word.meaning,
    ];
    return parts.join('  ·  ');
  }
}
