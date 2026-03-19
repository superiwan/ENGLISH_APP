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

        return ListView.separated(
          itemCount: mistakes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = mistakes[index];
            return ListTile(
              title: Text(item.word ?? '未知单词'),
              subtitle: Text('${item.meaning ?? ''}\n类型: ${item.type}  错误次数: ${item.count}'),
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
