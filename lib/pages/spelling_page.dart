import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/word.dart';
import '../ui/app_theme.dart';
import '../utils/levenshtein.dart';

class SpellingPage extends StatefulWidget {
  const SpellingPage({
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
  State<SpellingPage> createState() => _SpellingPageState();
}

class _SpellingPageState extends State<SpellingPage> {
  final _db = AppDatabase.instance;
  final _controller = TextEditingController();
  static const String _sessionMode = 'spelling';

  Word? _currentWord;
  final Set<int> _correctlyAnsweredWordIds = <int>{};
  bool _loading = true;
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
    final stats = await _db.getProgressStats();
    _totalCount = (stats['total'] ?? 0).round();

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

    if (word != null) {
      await _saveCheckpoint(word);
    }
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
      ).showSnackBar(const SnackBar(content: Text('请输入答案后再提交。')));
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
                      icon: Icons.spellcheck_outlined,
                      title: '暂无拼写题',
                      description: '请先导入单词，再开始拼写训练。',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    masteredCount: masteredCount,
                  ),
                  const SizedBox(height: AppUi.space16),
                  _buildQuestionCard(theme: theme, colorScheme: colorScheme),
                  const SizedBox(height: AppUi.space16),
                  _buildInputCard(theme: theme, colorScheme: colorScheme),
                  const SizedBox(height: AppUi.space12),
                  Text(
                    '学习提示：输入英文后点击提交，系统会自动判断并给出反馈。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
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

  Widget _buildStatusCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int masteredCount,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppUi.radius12),
              ),
              child: Icon(
                Icons.spellcheck,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppUi.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拼写训练',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUi.space8),
                  Text(
                    '本轮已掌握 $masteredCount 个单词',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildQuestionCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.45),
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUi.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请根据中文写出英文',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppUi.space12),
              Text(
                _currentWord!.meaning,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '输入答案',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppUi.space12),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: '输入英文单词',
                hintText: '例如 apple',
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radius12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radius12),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radius12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
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
              child: const Text('提交答案'),
            ),
          ],
        ),
      ),
    );
  }
}
