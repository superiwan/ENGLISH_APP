import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../utils/levenshtein.dart';

class SpellingPage extends StatefulWidget {
  const SpellingPage({
    super.key,
    required this.reloadTick,
    required this.onResultSaved,
    this.forcedWordId,
  });

  final int reloadTick;
  final int? forcedWordId;
  final VoidCallback onResultSaved;

  @override
  State<SpellingPage> createState() => _SpellingPageState();
}

class _SpellingPageState extends State<SpellingPage> {
  final _db = AppDatabase.instance;
  final _controller = TextEditingController();

  Word? _currentWord;
  bool _loading = true;
  int _lastReloadTick = -1;
  String? _lastConsumedForcedRequestKey;

  @override
  void initState() {
    super.initState();
    _lastReloadTick = widget.reloadTick;
    _loadQuestion();
  }

  @override
  void didUpdateWidget(covariant SpellingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadTick != _lastReloadTick || oldWidget.forcedWordId != widget.forcedWordId) {
      _lastReloadTick = widget.reloadTick;
      _loadQuestion();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
    });

    Word? word;
    final forcedId = widget.forcedWordId;
    final forcedRequestKey = forcedId == null ? null : '$forcedId:${widget.reloadTick}';
    if (forcedId != null && _lastConsumedForcedRequestKey != forcedRequestKey) {
      word = await _db.getWordById(forcedId);
      _lastConsumedForcedRequestKey = forcedRequestKey;
    }
    word ??= await _db.pickPriorityWord();

    if (!mounted) {
      return;
    }

    _controller.clear();
    setState(() {
      _currentWord = word;
      _loading = false;
    });
  }

  Future<void> _checkSpelling() async {
    final word = _currentWord;
    if (word == null) {
      return;
    }

    final input = _controller.text.trim().toLowerCase();
    final expected = word.word.toLowerCase();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入拼写后再提交。')));
      return;
    }

    final distance = levenshteinDistance(expected, input);
    final isCorrect = distance == 0;

    await _db.recordSpellingResult(wordId: word.id!, isCorrect: isCorrect);
    widget.onResultSaved();

    if (!mounted) {
      return;
    }

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('拼写正确')));
    } else if (distance <= 2) {
      final hint = mismatchHint(expected, input);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拼写接近正确。$hint 正确答案：$expected')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拼写错误。正确答案：$expected')),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWord == null) {
      return const Center(child: Text('暂无题目，请先导入单词。'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('请根据中文写出英文', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_currentWord!.meaning, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '输入英文单词',
            ),
            onSubmitted: (_) => _checkSpelling(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _checkSpelling,
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}
