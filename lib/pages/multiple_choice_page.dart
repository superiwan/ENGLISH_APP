import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';

class MultipleChoicePage extends StatefulWidget {
  const MultipleChoicePage({
    super.key,
    required this.reloadTick,
    required this.forcedRequestId,
    required this.sessionModule,
    required this.sessionSubgroup,
    required this.onForcedWordConsumed,
    required this.onResultSaved,
    this.forcedWordId,
  });

  final int reloadTick;
  final int forcedRequestId;
  final String sessionModule;
  final String sessionSubgroup;
  final int? forcedWordId;
  final VoidCallback onForcedWordConsumed;
  final VoidCallback onResultSaved;

  @override
  State<MultipleChoicePage> createState() => _MultipleChoicePageState();
}

class _MultipleChoicePageState extends State<MultipleChoicePage> {
  final _db = AppDatabase.instance;
  static const String _sessionMode = 'choice';

  Word? _currentWord;
  final Set<int> _correctlyAnsweredWordIds = <int>{};
  List<String> _options = [];
  bool _loading = true;
  bool _answering = false;
  int _totalCount = 0;
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
    final stats = await _db.getProgressStats();
    _totalCount = (stats['total'] ?? 0).round();

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

    await _saveCheckpoint(word);
  }

  Future<void> _saveCheckpoint(Word word) async {
    final wordId = word.id;
    if (wordId == null) {
      return;
    }
    final currentIndex = _correctlyAnsweredWordIds.length + 1;
    final module = widget.sessionModule.trim().isEmpty
        ? 'allWords'
        : widget.sessionModule.trim();
    final subgroup = widget.sessionSubgroup.trim().isEmpty
        ? 'daily'
        : widget.sessionSubgroup.trim();
    final sessionKey = '$_sessionMode|$module|$subgroup';
    await _db.upsertLearningSession(
      sessionKey: sessionKey,
      mode: _sessionMode,
      module: module,
      subgroup: subgroup,
      currentWordId: wordId,
      currentIndex: currentIndex,
      totalCount: _totalCount,
    );
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
          isCorrect ? '回答正确' : '回答错误，正确释义：${_currentWord!.meaning}',
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
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppUi.space16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildEmptyStateCard(
                      context: context,
                      icon: Icons.quiz_outlined,
                      title: '暂无选择题',
                      description: '请先导入单词，再开始选择题训练。',
                      color: colorScheme,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final masteredCount = _correctlyAnsweredWordIds.length;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppUi.space16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusBar(
                      context: context,
                      masteredCount: masteredCount,
                    ),
                    const SizedBox(height: AppUi.space16),
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(AppUi.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '题干',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppUi.space12),
                            Text(
                              _currentWord!.word,
                              style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ) ??
                                  theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: AppUi.space8),
                            Text(
                              '请选择它的正确中文释义',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppUi.space16),
                    Text(
                      '选项',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppUi.space12),
                    ..._options.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                                bottom: entry.key == _options.length - 1
                                    ? 0
                                    : AppUi.space12),
                            child: SizedBox(
                              height: 56,
                              child: FilledButton.tonal(
                                onPressed: _answering
                                    ? null
                                    : () => _submitAnswer(entry.value),
                                style: FilledButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppUi.space16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppUi.radius12),
                                  ),
                                  textStyle:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: Text(
                                  entry.value,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: AppUi.space16),
                    Container(
                      padding: const EdgeInsets.all(AppUi.space12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppUi.radius12),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        '学习提示：优先复习错题，其次随机出题。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(AppUi.radius12),
              ),
              child: Icon(icon, color: color.onPrimaryContainer, size: 28),
            ),
            const SizedBox(height: AppUi.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: AppUi.space8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar({
    required BuildContext context,
    required int masteredCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppUi.space16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppUi.radius16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择题训练',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '本轮优先巩固已经答对的单词',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppUi.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUi.space12,
              vertical: AppUi.space8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppUi.radius12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '本轮掌握数',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$masteredCount',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
