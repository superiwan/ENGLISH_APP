import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';
import '../widgets/section_header.dart';

class MultipleChoicePage extends StatefulWidget {
  const MultipleChoicePage({
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
  State<MultipleChoicePage> createState() => _MultipleChoicePageState();
}

class _MultipleChoicePageState extends State<MultipleChoicePage> {
  final _db = AppDatabase.instance;

  Word? _currentWord;
  final Set<int> _correctlyAnsweredWordIds = <int>{};
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
    if (widget.reloadTick != _lastReloadTick ||
        oldWidget.forcedRequestId != widget.forcedRequestId) {
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

    if (consumedForcedWord && mounted) {
      widget.onForcedWordConsumed();
    }
  }

  Future<void> _submitAnswer(String selectedMeaning) async {
    if (_currentWord == null || _answering) {
      return;
    }

    setState(() {
      _answering = true;
    });

    final isCorrect = selectedMeaning == _currentWord!.meaning;
    await _db.recordChoiceResult(
      wordId: _currentWord!.id!,
      isCorrect: isCorrect,
    );
    if (isCorrect) {
      _correctlyAnsweredWordIds.add(_currentWord!.id!);
    } else {
      _correctlyAnsweredWordIds.remove(_currentWord!.id!);
    }

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isCorrect
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        content: Text(
          isCorrect ? '回答正确' : '回答错误，正确答案：${_currentWord!.meaning}',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );

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
            title: '选择题训练',
            subtitle: '本轮已掌握 ${_correctlyAnsweredWordIds.length} 个单词',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppUi.space16),
              child: Text(
                '请选择 ${_currentWord!.word} 的正确中文释义',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: AppUi.space16),
          ..._options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: AppUi.space12),
              child: FilledButton.tonal(
                onPressed: _answering ? null : () => _submitAnswer(option),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUi.space16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUi.radius12),
                  ),
                ),
                child: Text(
                  option,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppUi.space12),
          Text(
            '提示：优先复习错题，其次随机出题。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
