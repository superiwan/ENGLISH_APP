import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                word.word,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(word.phonetic, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _infoTile('中文释义', word.meaning),
              _infoTile('词组搭配', word.phrase),
              _infoTile('前缀', word.prefix),
              _infoTile('后缀', word.suffix),
              _infoTile('形近词', word.similarWords),
              _infoTile('同义词', word.synonyms),
              const SizedBox(height: 12),
              Text('熟练度: ${word.familiarity}'),
              Text('错误次数: ${word.wrongCount}'),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text((value == null || value.isEmpty) ? '暂无' : value),
        ],
      ),
    );
  }
}
