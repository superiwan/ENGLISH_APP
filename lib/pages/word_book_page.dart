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

    final theme = Theme.of(context);
    final progress = ValueNotifier<double>(0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: theme.colorScheme.surface,
          elevation: 12,
          shadowColor: Colors.black26,
          surfaceTintColor: theme.colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUi.radius12 * 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppUi.space16),
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, child) {
                final percent = (value * 100).toStringAsFixed(0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(AppUi.radius12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '正在导入 PDF',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '请稍候，系统正在解析文件并写入单词。',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: value == 0 ? null : value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            value == 0 ? '准备中' : '进度 $percent%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          value == 0 ? '正在处理' : '已完成 $percent%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
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
              ? '导入完成\n解析到 $parsedCount 条，可写入 0 条。\n预览：${preview.isEmpty ? "(无可提取文本)" : preview}'
              : '导入完成\n写入/更新 $affected 个单词\n解析 $parsedCount 条，跳过 $skipped 行，文本长度 $textLength。',
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
    final theme = Theme.of(context);
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
                _OverviewCard(
                  total: '${stats['total']}',
                  practiced: '${stats['practiced']}',
                  mastered: '${stats['mastered']}',
                  accuracy: '$accuracy%',
                  hasWords: words.isNotEmpty,
                  onImport: _handleImport,
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
                _SectionHeader(
                  title: '按模块浏览单词',
                  subtitle: words.isEmpty
                      ? '先导入 PDF，再从模块进入单词列表。'
                      : '从不同维度进入单词列表，再查看详情。',
                ),
                const SizedBox(height: AppUi.space8),
                _ModuleBrowserGrid(
                  words: words,
                  modules: _modules,
                  onOpenModule: (module) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WordBookModulePage(module: module),
                      ),
                    );
                  },
                ),
                if (words.isEmpty) ...[
                  const SizedBox(height: AppUi.space24),
                  Center(
                    child: Text(
                      '当前还没有单词。导入后就可以按模块查看。',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.total,
    required this.practiced,
    required this.mastered,
    required this.accuracy,
    required this.hasWords,
    required this.onImport,
  });

  final String total;
  final String practiced;
  final String mastered;
  final String accuracy;
  final bool hasWords;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12 * 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(AppUi.space16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final title = Text(
              '欢迎回来',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            );
            final subtitle = Text(
              hasWords ? '继续整理单词，先完成最重要的学习动作。' : '先导入单词，再开始今天的学习。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.84,
                ),
              ),
            );
            final importButton = FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('导入 PDF'),
            );

            final statChips = Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              children: [
                _StatChip(label: '总词数', value: total),
                _StatChip(label: '已练习', value: practiced),
                _StatChip(label: '已掌握', value: mastered),
                _StatChip(label: '正确率', value: accuracy),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: AppUi.space8),
                  subtitle,
                  const SizedBox(height: AppUi.space16),
                  statChips,
                  const SizedBox(height: AppUi.space16),
                  SizedBox(width: double.infinity, child: importButton),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: AppUi.space8),
                      subtitle,
                      const SizedBox(height: AppUi.space16),
                      statChips,
                    ],
                  ),
                ),
                const SizedBox(width: AppUi.space16),
                Align(
                  alignment: Alignment.topRight,
                  child: importButton,
                ),
              ],
            );
          },
        ),
      ),
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
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12 * 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日学习入口',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUi.space8),
            Text(
              '总词数 $total · 已练习 $practiced · 正确率 $accuracy',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppUi.space16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 500;
                final primaryButton = FilledButton.icon(
                  onPressed: onOpenChoice,
                  icon: const Icon(Icons.quiz),
                  label: const Text('开始选择题'),
                );
                final secondaryButtons = [
                  FilledButton.tonalIcon(
                    onPressed: onOpenSpelling,
                    icon: const Icon(Icons.spellcheck),
                    label: const Text('开始拼写'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onOpenCardStudy,
                    icon: const Icon(Icons.view_carousel),
                    label: const Text('卡片学习'),
                  ),
                ];

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 48, child: primaryButton),
                      const SizedBox(height: AppUi.space8),
                      ...secondaryButtons
                          .expand(
                            (button) => [
                              SizedBox(height: 48, child: button),
                              const SizedBox(height: AppUi.space8),
                            ],
                          )
                          .toList()
                        ..removeLast(),
                    ],
                  );
                }

                return Wrap(
                  spacing: AppUi.space12,
                  runSpacing: AppUi.space12,
                  children: [
                    SizedBox(width: 160, child: primaryButton),
                    SizedBox(width: 160, child: secondaryButtons[0]),
                    SizedBox(width: 160, child: secondaryButtons[1]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.space12,
        vertical: AppUi.space8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppUi.radius12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleBrowserGrid extends StatelessWidget {
  const _ModuleBrowserGrid({
    required this.words,
    required this.modules,
    required this.onOpenModule,
  });

  final List<Word> words;
  final List<WordBookModuleType> modules;
  final ValueChanged<WordBookModuleType> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 600
            ? 1
            : width < 980
                ? 2
                : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppUi.space12,
            mainAxisSpacing: AppUi.space12,
            mainAxisExtent: 192,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            final count = moduleWordCount(words, module);
            return _ModuleCard(
              title: module.title,
              description: module.description,
              count: count,
              icon: module.icon,
              onTap: () => onOpenModule(module),
            );
          },
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
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12 * 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppUi.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppUi.radius12 + 4),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppUi.space12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
