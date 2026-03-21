import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_header.dart';

class WordDetailPage extends StatelessWidget {
  const WordDetailPage({super.key, required this.wordId});

  final int wordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单词详情')),
      body: FutureBuilder<Word?>(
        future: AppDatabase.instance.getWordById(wordId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final word = snapshot.data;
          if (word == null) {
            return const Center(child: Text('未找到该单词'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppUi.space16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppUi.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.word,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppUi.space8),
                      Text(
                        word.phonetic.isEmpty ? '暂无音标' : word.phonetic,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppUi.space12),
                      _buildMeaningChip(context, word.meaning),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppUi.space12),
              const SectionHeader(title: '学习状态'),
              MetricCard(
                title: '熟练度',
                value: '${word.familiarity}',
                icon: Icons.trending_up,
              ),
              const SizedBox(height: AppUi.space8),
              MetricCard(
                title: '错误次数',
                value: '${word.wrongCount}',
                icon: Icons.warning_amber_outlined,
              ),
              const SizedBox(height: AppUi.space12),
              const SectionHeader(title: '构词与扩展'),
              _infoTile('词组搭配', word.phrase),
              _infoTile('前缀', word.prefix),
              _infoTile('后缀', word.suffix),
              _infoTile('形近词', word.similarWords),
              _infoTile('同义词', word.synonyms),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMeaningChip(BuildContext context, String meaning) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.space12,
        vertical: AppUi.space8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppUi.radius12),
      ),
      child: Text(
        meaning,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppUi.space8),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text((value == null || value.isEmpty) ? '暂无' : value),
      ),
    );
  }
}
