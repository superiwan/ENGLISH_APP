import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';
import '../utils/pdf_importer.dart';
import 'card_study_page.dart';
import 'word_book_module_page.dart';

class WordBookPage extends StatefulWidget {
  const WordBookPage({
    super.key,
    required this.reloadTick,
    required this.onDataChanged,
    required this.onOpenChoice,
    required this.onOpenSpelling,
  });

  final int reloadTick;
  final VoidCallback onDataChanged;
  final VoidCallback onOpenChoice;
  final VoidCallback onOpenSpelling;

  @override
  State<WordBookPage> createState() => _WordBookPageState();
}

class _WordBookPageState extends State<WordBookPage> {
  final _db = AppDatabase.instance;
  final _importer = PdfImporter();
  late Future<List<Word>> _wordsFuture;
  late Future<Map<String, num>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _wordsFuture = _db.getAllWords();
    _statsFuture = _db.getProgressStats();
  }

  @override
  void didUpdateWidget(covariant WordBookPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick) {
      _reloadWords();
    }
  }

  void _reloadWords() {
    setState(() {
      _wordsFuture = _db.getAllWords();
      _statsFuture = _db.getProgressStats();
    });
  }

  Future<void> _handleImport() async {
    final path = await _importer.pickPdfPath();
    if (path == null || !mounted) {
      return;
    }

    final progress = ValueNotifier<double>(0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('正在导入 PDF'),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: value == 0 ? null : value),
                  const SizedBox(height: 12),
                  Text('进度: ${(value * 100).toStringAsFixed(0)}%'),
                ],
              );
            },
          ),
        );
      },
    );

    var affected = 0;
    var skipped = 0;
    var parsedCount = 0;
    var textLength = 0;
    var preview = '';

    try {
      final result = await _importer.parsePdf(path);
      skipped = result.skippedLines;
      parsedCount = result.words.length;
      textLength = result.totalTextLength;
      preview = result.preview;
      affected = await _db.importWords(
        result.words,
        onProgress: (current, total) {
          progress.value = total == 0 ? 1 : current / total;
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 导入失败：$e')));
      return;
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      progress.dispose();
    }

    if (!mounted) {
      return;
    }

    _reloadWords();
    widget.onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          affected == 0
              ? '导入完成：解析到 $parsedCount 条，可写入 0 条。预览: ${preview.isEmpty ? "(无可提取文本)" : preview}'
              : '导入完成：写入/更新 $affected 个单词（解析 $parsedCount 条，跳过 $skipped 行，文本长度 $textLength）。',
        ),
      ),
    );
  }

  List<WordBookModuleType> get _modules => const [
        WordBookModuleType.similarWords,
        WordBookModuleType.synonyms,
        WordBookModuleType.prefix,
        WordBookModuleType.suffix,
        WordBookModuleType.allWords,
      ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Word>>(
      future: _wordsFuture,
      builder: (context, wordsSnapshot) {
        if (wordsSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final words = wordsSnapshot.data ?? [];
        return FutureBuilder<Map<String, num>>(
          future: _statsFuture,
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ??
                {
                  'total': words.length,
                  'practiced': 0,
                  'mastered': 0,
                  'accuracy': 0.0,
                };
            final accuracy =
                ((stats['accuracy'] ?? 0.0) * 100).toStringAsFixed(1);
            return ListView(
              padding: const EdgeInsets.all(AppUi.space16),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _handleImport,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('导入PDF'),
                  ),
                ),
                const SizedBox(height: AppUi.space16),
                _TodayEntryCard(
                  total: '${stats['total']}',
                  practiced: '${stats['practiced']}',
                  accuracy: '$accuracy%',
                  onOpenCardStudy: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardStudyPage(words: words),
                      ),
                    );
                  },
                  onOpenChoice: widget.onOpenChoice,
                  onOpenSpelling: widget.onOpenSpelling,
                ),
                const SizedBox(height: AppUi.space16),
                Text('按模块浏览单词', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppUi.space8),
                Text(
                  words.isEmpty ? '先导入 PDF，再从模块进入单词列表。' : '从不同维度进入单词列表，再查看详情。',
                ),
                const SizedBox(height: AppUi.space16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth < 560
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppUi.space12) / 2;
                    return Wrap(
                      spacing: AppUi.space12,
                      runSpacing: AppUi.space12,
                      children: _modules.map((module) {
                        final count = moduleWordCount(words, module);
                        return SizedBox(
                          width: cardWidth,
                          child: _ModuleCard(
                            title: module.title,
                            description: module.description,
                            count: count,
                            icon: module.icon,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WordBookModulePage(module: module),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                if (words.isEmpty) ...[
                  const SizedBox(height: AppUi.space24),
                  const Center(child: Text('当前还没有单词。导入后就可以按模块查看。')),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _TodayEntryCard extends StatelessWidget {
  const _TodayEntryCard({
    required this.total,
    required this.practiced,
    required this.accuracy,
    required this.onOpenCardStudy,
    required this.onOpenChoice,
    required this.onOpenSpelling,
  });

  final String total;
  final String practiced;
  final String accuracy;
  final VoidCallback onOpenCardStudy;
  final VoidCallback onOpenChoice;
  final VoidCallback onOpenSpelling;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日学习入口',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppUi.space8),
            Text('总词数 $total · 已练习 $practiced · 正确率 $accuracy'),
            const SizedBox(height: AppUi.space12),
            Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              children: [
                SizedBox(
                  width: 152,
                  child: FilledButton.icon(
                    onPressed: onOpenChoice,
                    icon: const Icon(Icons.quiz),
                    label: const Text('选择题'),
                  ),
                ),
                SizedBox(
                  width: 152,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenSpelling,
                    icon: const Icon(Icons.spellcheck),
                    label: const Text('拼写'),
                  ),
                ),
                SizedBox(
                  width: 152,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenCardStudy,
                    icon: const Icon(Icons.view_carousel),
                    label: const Text('卡片学习'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.description,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppUi.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppUi.radius12),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppUi.space12),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('数量 $count', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
