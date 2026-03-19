import 'package:flutter/material.dart';

import '../database/app_database.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.reloadTick,
  });

  final int reloadTick;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _db = AppDatabase.instance;
  late Future<Map<String, num>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _db.getProgressStats();
  }

  @override
  void didUpdateWidget(covariant ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _statsFuture = _db.getProgressStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, num>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {
          'total': 0,
          'practiced': 0,
          'mastered': 0,
          'accuracy': 0.0,
        };

        final accuracy = (stats['accuracy'] ?? 0.0) * 100;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card('总单词数', '${stats['total']}'),
            _card('已练习数量', '${stats['practiced']}'),
            _card('正确率', '${accuracy.toStringAsFixed(1)}%'),
            _card('已掌握数量 (familiarity > 80)', '${stats['mastered']}'),
          ],
        );
      },
    );
  }

  Widget _card(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
