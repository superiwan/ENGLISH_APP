import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../ui/app_theme.dart';

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

        final total = _formatCount(stats['total']);
        final practiced = _formatCount(stats['practiced']);
        final mastered = _formatCount(stats['mastered']);
        final accuracy = _formatAccuracy(stats['accuracy']);
        final masteredRate =
            _formatMasteredRate(stats['mastered'], stats['total']);

        return ListView(
          padding: const EdgeInsets.all(AppUi.space16),
          children: [
            _ProgressOverviewCard(
              total: total,
              practiced: practiced,
              accuracy: accuracy,
              hasData: stats['total'] != null && (stats['total'] ?? 0) > 0,
            ),
            const SizedBox(height: AppUi.space16),
            _MetricsPanel(
              mastered: mastered,
              practiced: practiced,
              total: total,
              masteredRate: masteredRate,
              accuracy: accuracy,
            ),
            const SizedBox(height: AppUi.space16),
            _AdviceCard(
              text: _buildAdviceText(
                total: stats['total'] ?? 0,
                practiced: stats['practiced'] ?? 0,
                mastered: stats['mastered'] ?? 0,
                accuracy: stats['accuracy'] ?? 0.0,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCount(num? value) {
    return '${(value ?? 0).round()}';
  }

  String _formatAccuracy(num? value) {
    return '${((value ?? 0.0) * 100).toStringAsFixed(1)}%';
  }

  String _formatMasteredRate(num? mastered, num? total) {
    final totalValue = (total ?? 0).toDouble();
    if (totalValue <= 0) {
      return '0.0%';
    }
    final rate = ((mastered ?? 0).toDouble() / totalValue) * 100;
    return '${rate.toStringAsFixed(1)}%';
  }

  String _buildAdviceText({
    required num total,
    required num practiced,
    required num mastered,
    required num accuracy,
  }) {
    if (total <= 0) {
      return '先导入单词，再开始积累统计。统计页会随着学习进展自动刷新，适合在每次训练后快速检查变化。';
    }

    final accuracyPercent = accuracy * 100;
    if (practiced <= 0) {
      return '当前还没有练习记录。建议先从卡片学习或拼写训练开始，完成一轮后再回来查看正确率和已掌握数量。';
    }
    if (accuracyPercent < 60) {
      return '正确率还有提升空间。先优先巩固高频单词，缩小单次练习范围，会比一次性刷很多词更有效。';
    }
    if (mastered < total / 3) {
      return '状态正在稳步上升。继续保持练习频率，把已练习的词反复巩固，已掌握数量会更快增长。';
    }
    return '当前进度比较健康。可以继续扩展新词，同时穿插复习，保持正确率和已掌握数量同步增长。';
  }
}

class _ProgressOverviewCard extends StatelessWidget {
  const _ProgressOverviewCard({
    required this.total,
    required this.practiced,
    required this.accuracy,
    required this.hasData,
  });

  final String total;
  final String practiced;
  final String accuracy;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.7),
              scheme.surfaceContainerHighest,
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
              '学习概览',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            );
            final subtitle = Text(
              hasData ? '把今天的练习结果变成可读的进度反馈。' : '先开始学习，统计会自动累积。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.82),
              ),
            );

            final tiles = [
              _StatTile(
                label: '总词数',
                value: total,
                icon: Icons.menu_book_outlined,
              ),
              _StatTile(
                label: '已练习',
                value: practiced,
                icon: Icons.check_circle_outline,
              ),
              _StatTile(
                label: '正确率',
                value: accuracy,
                icon: Icons.analytics_outlined,
              ),
            ];

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: AppUi.space8),
                  subtitle,
                  const SizedBox(height: AppUi.space16),
                  ...tiles.map(
                    (tile) => Padding(
                      padding: const EdgeInsets.only(bottom: AppUi.space8),
                      child: tile,
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: AppUi.space8),
                          subtitle,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppUi.space12),
                    Icon(
                      Icons.auto_graph_outlined,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: AppUi.space16),
                Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: AppUi.space12),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: AppUi.space12),
                    Expanded(child: tiles[2]),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.mastered,
    required this.practiced,
    required this.total,
    required this.masteredRate,
    required this.accuracy,
  });

  final String mastered;
  final String practiced;
  final String total;
  final String masteredRate;
  final String accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      _MetricItem(
        title: '已掌握',
        value: mastered,
        icon: Icons.workspace_premium_outlined,
        note: 'familiarity > 80',
      ),
      _MetricItem(
        title: '掌握率',
        value: masteredRate,
        icon: Icons.flag_outlined,
        note: '已掌握 / 总词数',
      ),
      _MetricItem(
        title: '练习覆盖',
        value: '$practiced / $total',
        icon: Icons.layers_outlined,
        note: '已练习 / 总词数',
      ),
      _MetricItem(
        title: '正确率',
        value: accuracy,
        icon: Icons.insights_outlined,
        note: '最近练习表现',
      ),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '细分指标',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUi.space12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        metrics[i],
                        if (i != metrics.length - 1)
                          const SizedBox(height: AppUi.space8),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: AppUi.space12,
                  runSpacing: AppUi.space12,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: (constraints.maxWidth - AppUi.space12) / 2,
                        child: metric,
                      ),
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

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppUi.radius12),
              ),
              child: Icon(
                Icons.tips_and_updates_outlined,
                color: scheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppUi.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '行动建议',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUi.space8),
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppUi.radius12),
              ),
              child: Icon(
                icon,
                color: scheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: AppUi.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.headlineSmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.note,
  });

  final String title;
  final String value;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: scheme.onPrimaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: AppUi.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
