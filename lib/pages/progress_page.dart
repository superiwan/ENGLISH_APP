import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../ui/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_header.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, required this.reloadTick});

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

        final stats = snapshot.data ??
            {'total': 0, 'practiced': 0, 'mastered': 0, 'accuracy': 0.0};

        final accuracy = (stats['accuracy'] ?? 0.0) * 100;

        return ListView(
          padding: const EdgeInsets.all(AppUi.space16),
          children: [
            const SectionHeader(title: '学习统计', subtitle: '快速查看当前学习进度'),
            MetricCard(
              title: '总单词数',
              value: '${stats['total']}',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: AppUi.space8),
            MetricCard(
              title: '已练习数量',
              value: '${stats['practiced']}',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppUi.space8),
            MetricCard(
              title: '正确率',
              value: '${accuracy.toStringAsFixed(1)}%',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: AppUi.space8),
            MetricCard(
              title: '已掌握数量 (familiarity > 80)',
              value: '${stats['mastered']}',
              icon: Icons.workspace_premium_outlined,
            ),
          ],
        );
      },
    );
  }
}
