import 'package:flutter/material.dart';

import '../models/word.dart';
import '../ui/app_theme.dart';

class CardStudyPage extends StatefulWidget {
  const CardStudyPage({
    super.key,
    required this.words,
  });

  final List<Word> words;

  @override
  State<CardStudyPage> createState() => _CardStudyPageState();
}

class _CardStudyPageState extends State<CardStudyPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, bool> _meaningVisibleByIndex = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isMeaningVisible(int index) => _meaningVisibleByIndex[index] ?? false;

  void _toggleMeaning([int? index]) {
    if (widget.words.isEmpty) {
      return;
    }

    final targetIndex = index ?? _currentIndex;
    setState(() {
      _meaningVisibleByIndex[targetIndex] =
          !(_meaningVisibleByIndex[targetIndex] ?? false);
    });
  }

  void _jumpToPage(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.words.length) {
      return;
    }

    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片学习'),
      ),
      body: SafeArea(
        child: words.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppUi.space16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppUi.space12),
                      Text(
                        '当前没有可学习的单词',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUi.space8),
                      Text(
                        '先导入 PDF，再回到单词本开始卡片学习。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: words.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final word = words[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppUi.space16,
                            AppUi.space12,
                            AppUi.space16,
                            AppUi.space8,
                          ),
                          child: _StudyCard(
                            word: word,
                            currentIndex: index + 1,
                            totalCount: words.length,
                            meaningVisible: _isMeaningVisible(index),
                            onToggleMeaning: () => _toggleMeaning(index),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppUi.space16,
                      0,
                      AppUi.space16,
                      AppUi.space16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _currentIndex > 0
                                ? () => _jumpToPage(_currentIndex - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('上一张'),
                          ),
                        ),
                        const SizedBox(width: AppUi.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppUi.space12,
                            vertical: AppUi.space8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppUi.radius12,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${words.length}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: AppUi.space12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _currentIndex < words.length - 1
                                ? () => _jumpToPage(_currentIndex + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('下一张'),
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

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.word,
    required this.currentIndex,
    required this.totalCount,
    required this.meaningVisible,
    required this.onToggleMeaning,
  });

  final Word word;
  final int currentIndex;
  final int totalCount;
  final bool meaningVisible;
  final VoidCallback onToggleMeaning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleMeaning,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppUi.space16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text('$currentIndex / $totalCount'),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    '点击中文区域可显示/隐藏',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppUi.space24),
              Center(
                child: Column(
                  children: [
                    Text(
                      word.word,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppUi.space12),
                    Text(
                      word.phonetic.isEmpty ? '音标暂无' : word.phonetic,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleMeaning,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppUi.space16),
                  decoration: BoxDecoration(
                    color: meaningVisible
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppUi.radius16),
                    border: Border.all(
                      color: meaningVisible
                          ? theme.colorScheme.primary.withValues(alpha: 0.35)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '中文',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUi.space8),
                      AnimatedCrossFade(
                        firstChild: Text(
                          '点击显示中文释义',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        secondChild: Text(
                          word.meaning.isEmpty ? '暂无释义' : word.meaning,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        crossFadeState: meaningVisible
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                        sizeCurve: Curves.easeOut,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppUi.space12),
              Text(
                '左右滑动可切换单词',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
