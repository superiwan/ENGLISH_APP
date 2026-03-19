import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../utils/pdf_importer.dart';
import 'word_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _handleImport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('导入PDF'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Word>>(
            future: _wordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final words = snapshot.data ?? [];
              if (words.isEmpty) {
                return const Center(child: Text('暂无单词，请先导入 PDF。'));
              }

              return ListView.separated(
                itemCount: words.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final word = words[index];
                  return ListTile(
                    title: Text(word.word),
                    subtitle: Text('${word.phonetic}  ${word.meaning}'),
                    trailing: Text('熟练度 ${word.familiarity}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordDetailPage(wordId: word.id!),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
