import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';

class MultipleChoicePage extends StatefulWidget {
  const MultipleChoicePage({
    super.key,
    required this.reloadTick,
    required this.onResultSaved,
    this.forcedWordId,
  });

  final int reloadTick;
  final int? forcedWordId;
  final VoidCallback onResultSaved;

  @override
  State<MultipleChoicePage> createState() => _MultipleChoicePageState();
}

class _MultipleChoicePageState extends State<MultipleChoicePage> {
  final _db = AppDatabase.instance;

  Word? _currentWord;
  List<String> _options = [];
  bool _loading = true;
  bool _answering = false;
  int _lastReloadTick = -1;
  String? _lastConsumedForcedRequestKey;

  @override
  void initState() {
    super.initState();
    _lastReloadTick = widget.reloadTick;
    _loadQuestion();
  }

  @override
  void didUpdateWidget(covariant MultipleChoicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadTick != _lastReloadTick || oldWidget.forcedWordId != widget.forcedWordId) {
      _lastReloadTick = widget.reloadTick;
      _loadQuestion();
    }
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _answering = false;
    });

    Word? word;
    final forcedId = widget.forcedWordId;
    final forcedRequestKey = forcedId == null ? null : '$forcedId:${widget.reloadTick}';
    if (forcedId != null && _lastConsumedForcedRequestKey != forcedRequestKey) {
      word = await _db.getWordById(forcedId);
      _lastConsumedForcedRequestKey = forcedRequestKey;
    }
    word ??= await _db.pickPriorityWord();

    if (word == null) {
      if (mounted) {
        setState(() {
          _currentWord = null;
          _options = [];
          _loading = false;
        });
      }
      return;
    }

    final options = await _db.buildOptionsForWord(word);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentWord = word;
      _options = options;
      _loading = false;
    });
  }

  Future<void> _submitAnswer(String selectedMeaning) async {
    if (_currentWord == null || _answering) {
      return;
    }

    setState(() {
      _answering = true;
    });

    final isCorrect = selectedMeaning == _currentWord!.meaning;
    await _db.recordChoiceResult(wordId: _currentWord!.id!, isCorrect: isCorrect);
    widget.onResultSaved();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? '回答正确' : '回答错误，正确答案：${_currentWord!.meaning}',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );

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
          Text('请选择 ${_currentWord!.word} 的正确中文释义', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ..._options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                onPressed: _answering ? null : () => _submitAnswer(option),
                child: Text(option),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('提示：优先复习错题，其次随机出题。', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
