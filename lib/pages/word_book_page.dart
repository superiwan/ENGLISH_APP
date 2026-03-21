import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../utils/pdf_importer.dart';
import 'word_book_module_page.dart';

class WordBookPage extends StatefulWidget {
  const WordBookPage({
    super.key,
    required this.reloadTick,
    required this.onDataChanged,
  });

  final int reloadTick;
  final VoidCallback onDataChanged;

  @override
  State<WordBookPage> createState() => _WordBookPageState();
}

class _WordBookPageState extends State<WordBookPage> {
  final _db = AppDatabase.instance;
  final _importer = PdfImporter();
  late Future<List<Word>> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _wordsFuture = _db.getAllWords();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 导入失败：$e')),
      );
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
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final words = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _handleImport,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('导入PDF'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '按模块浏览单词',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              words.isEmpty ? '先导入 PDF，再从模块进入单词列表。' : '从不同维度进入单词列表，再查看详情。',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _modules.map((module) {
                final count = moduleWordCount(words, module);
                return SizedBox(
                  width: 260,
                  child: _ModuleCard(
                    title: module.title,
                    description: module.description,
                    count: count,
                    icon: module.icon,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordBookModulePage(module: module),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
            if (words.isEmpty) ...[
              const SizedBox(height: 24),
              const Center(child: Text('当前还没有单词。导入后就可以按模块查看。')),
            ],
          ],
        );
      },
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
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
