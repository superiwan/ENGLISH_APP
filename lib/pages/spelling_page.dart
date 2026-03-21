import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';
import '../utils/levenshtein.dart';
import '../widgets/section_header.dart';

class SpellingPage extends StatefulWidget {
  const SpellingPage({
    super.key,
    required this.reloadTick,
    required this.forcedRequestId,
    required this.onForcedWordConsumed,
    required this.onResultSaved,
    this.forcedWordId,
  });

  final int reloadTick;
  final int forcedRequestId;
  final int? forcedWordId;
  final VoidCallback onForcedWordConsumed;
  final VoidCallback onResultSaved;

  @override
  State<SpellingPage> createState() => _SpellingPageState();
}

class _SpellingPageState extends State<SpellingPage> {
  final _db = AppDatabase.instance;
  final _controller = TextEditingController();

  Word? _currentWord;
  final Set<int> _correctlyAnsweredWordIds = <int>{};
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
    if (widget.reloadTick != _lastReloadTick ||
        oldWidget.forcedRequestId != widget.forcedRequestId) {
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
    final forcedRequestKey =
        forcedId == null ? null : '$forcedId:${widget.forcedRequestId}';
    var consumedForcedWord = false;
    if (forcedId != null && _lastConsumedForcedRequestKey != forcedRequestKey) {
      word = await _db.getWordById(forcedId);
      _lastConsumedForcedRequestKey = forcedRequestKey;
      consumedForcedWord = true;
    }
    word ??= await _db.pickPriorityWord(
      excludedWordIds: _correctlyAnsweredWordIds.toList(),
    );

    if (!mounted) {
      return;
    }

    _controller.clear();
    setState(() {
      _currentWord = word;
      _loading = false;
    });

    if (consumedForcedWord && mounted) {
      widget.onForcedWordConsumed();
    }
  }

  Future<void> _checkSpelling() async {
    final word = _currentWord;
    if (word == null) {
      return;
    }

    final input = _controller.text.trim().toLowerCase();
    final expected = word.word.toLowerCase();

    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入拼写后再提交。')));
      return;
    }

    final distance = levenshteinDistance(expected, input);
    final isCorrect = distance == 0;

    await _db.recordSpellingResult(wordId: word.id!, isCorrect: isCorrect);
    if (isCorrect) {
      _correctlyAnsweredWordIds.add(word.id!);
    } else {
      _correctlyAnsweredWordIds.remove(word.id!);
    }

    if (!mounted) {
      return;
    }

    if (isCorrect) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          content: const Text('拼写正确'),
        ),
      );
    } else if (distance <= 2) {
      final hint = mismatchHint(expected, input);
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text('拼写接近正确。$hint 正确答案：$expected'),
        ),
      );
    } else {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text('拼写错误。正确答案：$expected'),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    widget.onResultSaved();
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
      padding: const EdgeInsets.all(AppUi.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: '拼写训练',
            subtitle: '本轮已掌握 ${_correctlyAnsweredWordIds.length} 个单词',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppUi.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '请根据中文写出英文',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppUi.space8),
                  Text(
                    _currentWord!.meaning,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppUi.space16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: '输入英文单词'),
            onSubmitted: (_) => _checkSpelling(),
          ),
          const SizedBox(height: AppUi.space12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppUi.radius12),
              ),
            ),
            onPressed: _checkSpelling,
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}
