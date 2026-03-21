import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/mistake_record.dart';
import '../ui/app_theme.dart';

class MistakesPage extends StatefulWidget {
  const MistakesPage({
    super.key,
    required this.reloadTick,
    required this.onTrainChoice,
    required this.onTrainSpelling,
  });

  final int reloadTick;
  final ValueChanged<int> onTrainChoice;
  final ValueChanged<int> onTrainSpelling;

  @override
  State<MistakesPage> createState() => _MistakesPageState();
}

class _MistakesPageState extends State<MistakesPage> {
  final _db = AppDatabase.instance;
  late Future<List<MistakeRecord>> _mistakesFuture;

  static const _typeOrder = ['choice', 'spelling'];
  static const _typeLabels = <String, String>{
    'choice': '选择题',
    'spelling': '拼写',
  };

  @override
  void initState() {
    super.initState();
    _mistakesFuture = _db.getMistakes();
  }

  @override
  void didUpdateWidget(covariant MistakesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _mistakesFuture = _db.getMistakes();
    });
  }

  String _typeLabel(String type) => _typeLabels[type] ?? type;

  int _totalCount(Map<String, List<MistakeRecord>> grouped) {
    return grouped.values.fold<int>(0, (sum, items) => sum + items.length);
  }

  Widget _buildOverviewCard(
    BuildContext context,
    Map<String, List<MistakeRecord>> grouped,
  ) {
    final totalCount = _totalCount(grouped);
    final choiceCount = grouped['choice']?.length ?? 0;
    final spellingCount = grouped['spelling']?.length ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppUi.radius12),
                  ),
                  child: Icon(
                    Icons.library_books_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppUi.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '错题本总览',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '按类型集中整理，先看高频错题，再用重练按钮回到对应训练。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUi.space16),
            Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              children: [
                _OverviewStatChip(
                  label: '总错题',
                  value: '$totalCount',
                  icon: Icons.fact_check_outlined,
                ),
                _OverviewStatChip(
                  label: '选择题',
                  value: '$choiceCount',
                  icon: Icons.quiz_outlined,
                ),
                _OverviewStatChip(
                  label: '拼写题',
                  value: '$spellingCount',
                  icon: Icons.spellcheck_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(MistakeRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除错题'),
          content: Text(
            '确定删除“${record.word ?? '未知单词'}”的${_typeLabel(record.type)}错题记录吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _db.deleteMistakeRecord(wordId: record.wordId, type: record.type);
    if (!mounted) {
      return;
    }
    _reload();
  }

  Future<void> _clearType(String type, int count) async {
    final label = _typeLabel(type);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('清空$label'),
          content: Text('确定清空$label错题吗？当前共 $count 条。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _db.clearMistakesByType(type);
    if (!mounted) {
      return;
    }
    _reload();
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String type,
    required int count,
  }) {
    final label = _typeLabel(type);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppUi.space8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _TypeCountBadge(count: count),
              ],
            ),
            const SizedBox(height: AppUi.space12),
            Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '本组共 $count 条错题',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: () => _clearType(type, count),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('清空本类型'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeItem(BuildContext context, MistakeRecord item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        colorScheme.secondaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppUi.radius12),
                  ),
                  child: Icon(
                    Icons.abc_outlined,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: AppUi.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.word ?? '未知单词',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.meaning?.trim().isNotEmpty == true
                            ? item.meaning!
                            : '暂无释义',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUi.space12),
            Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              children: [
                _InfoChip(
                  icon: Icons.repeat_outlined,
                  label: '错误次数 ${item.count}',
                ),
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: _typeLabel(item.type),
                ),
              ],
            ),
            const SizedBox(height: AppUi.space12),
            Wrap(
              spacing: AppUi.space8,
              runSpacing: AppUi.space8,
              alignment: WrapAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.quiz,
                  label: '选择题重练',
                  onPressed: () => widget.onTrainChoice(item.wordId),
                ),
                _ActionButton(
                  icon: Icons.spellcheck,
                  label: '拼写重练',
                  onPressed: () => widget.onTrainSpelling(item.wordId),
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: '删除',
                  isDanger: true,
                  onPressed: () => _deleteRecord(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MistakeRecord>>(
      future: _mistakesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final mistakes = snapshot.data ?? [];
        if (mistakes.isEmpty) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppUi.space16),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(AppUi.space16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(AppUi.radius12),
                                  ),
                                  child: Icon(
                                    Icons.inbox_outlined,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: AppUi.space16),
                                Text(
                                  '暂无错题',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppUi.space8),
                                Text(
                                  '继续练习吧，出现的错题会自动汇总到这里。',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        final grouped = <String, List<MistakeRecord>>{
          for (final type in _typeOrder) type: [],
        };
        for (final item in mistakes) {
          grouped.putIfAbsent(item.type, () => []).add(item);
        }

        final visibleTypes = _typeOrder
            .where((type) => (grouped[type] ?? const []).isNotEmpty)
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(AppUi.space16),
          itemCount: 1 + visibleTypes.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppUi.space12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildOverviewCard(context, grouped);
            }

            final type = visibleTypes[index - 1];
            final items = grouped[type]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  type: type,
                  count: items.length,
                ),
                const SizedBox(height: AppUi.space12),
                for (var i = 0; i < items.length; i++) ...[
                  _buildMistakeItem(context, items[i]),
                  if (i != items.length - 1)
                    const SizedBox(height: AppUi.space8),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewStatChip extends StatelessWidget {
  const _OverviewStatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label $value'),
    );
  }
}

class _TypeCountBadge extends StatelessWidget {
  const _TypeCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count 条',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = isDanger ? FilledButton.tonalIcon : FilledButton.icon;
    return button(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.space12,
          vertical: 10,
        ),
        backgroundColor: isDanger ? colorScheme.errorContainer : null,
        foregroundColor: isDanger ? colorScheme.error : null,
      ),
    );
  }
}
