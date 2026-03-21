import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/mistake_record.dart';

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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Chip(label: Text('$count 条')),
        TextButton.icon(
          onPressed: () => _clearType(type, count),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('清空本类型'),
        ),
      ],
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
          return const Center(child: Text('暂无错题，继续保持。'));
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final type in visibleTypes) ...[
              _buildSectionHeader(
                context,
                type: type,
                count: grouped[type]!.length,
              ),
              const SizedBox(height: 8),
              for (final item in grouped[type]!) ...[
                Card(
                  child: ListTile(
                    title: Text(item.word ?? '未知单词'),
                    subtitle: Text(
                      '${item.meaning ?? ''}\n错误次数: ${item.count}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: '选择题重练',
                          onPressed: () => widget.onTrainChoice(item.wordId),
                          icon: const Icon(Icons.quiz),
                        ),
                        IconButton(
                          tooltip: '拼写重练',
                          onPressed: () => widget.onTrainSpelling(item.wordId),
                          icon: const Icon(Icons.spellcheck),
                        ),
                        IconButton(
                          tooltip: '删除错题',
                          onPressed: () => _deleteRecord(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
