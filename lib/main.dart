import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/app_database.dart';
import 'pages/mistakes_page.dart';
import 'pages/multiple_choice_page.dart';
import 'pages/progress_page.dart';
import 'pages/spelling_page.dart';
import 'pages/word_book_page.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await AppDatabase.instance.normalizeExistingWords();

  runApp(const EnglishWordApp());
}

class EnglishWordApp extends StatefulWidget {
  const EnglishWordApp({super.key});

  @override
  State<EnglishWordApp> createState() => _EnglishWordAppState();
}

class _EnglishWordAppState extends State<EnglishWordApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Word App',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: _themeMode,
      home: HomeShell(
        themeMode: _themeMode,
        onToggleThemeMode: _toggleThemeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onToggleThemeMode,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  int _reloadTick = 0;
  int? _choiceForcedWordId;
  int _choiceForcedRequestId = 0;
  String _choiceSessionModule = 'allWords';
  String _choiceSessionSubgroup = 'daily';
  int? _spellingForcedWordId;
  int _spellingForcedRequestId = 0;
  String _spellingSessionModule = 'allWords';
  String _spellingSessionSubgroup = 'daily';

  void _refreshAll() {
    setState(() {
      _reloadTick++;
    });
  }

  void _openChoiceTraining({
    int? wordId,
    String module = 'allWords',
    String subgroup = 'daily',
  }) {
    setState(() {
      _choiceForcedWordId = wordId;
      if (wordId != null) {
        _choiceForcedRequestId++;
      }
      _choiceSessionModule = module;
      _choiceSessionSubgroup = subgroup;
      _selectedIndex = 1;
      _reloadTick++;
    });
  }

  void _openSpellingTraining({
    int? wordId,
    String module = 'allWords',
    String subgroup = 'daily',
  }) {
    setState(() {
      _spellingForcedWordId = wordId;
      if (wordId != null) {
        _spellingForcedRequestId++;
      }
      _spellingSessionModule = module;
      _spellingSessionSubgroup = subgroup;
      _selectedIndex = 2;
      _reloadTick++;
    });
  }

  void _openChoiceSession(int? wordId, String module, String subgroup) {
    _openChoiceTraining(wordId: wordId, module: module, subgroup: subgroup);
  }

  void _openSpellingSession(int? wordId, String module, String subgroup) {
    _openSpellingTraining(wordId: wordId, module: module, subgroup: subgroup);
  }

  void _openChoiceRetrain(int wordId) {
    _openChoiceTraining(wordId: wordId, module: 'mistakes', subgroup: 'choice');
  }

  void _openSpellingRetrain(int wordId) {
    _openSpellingTraining(
      wordId: wordId,
      module: 'mistakes',
      subgroup: 'spelling',
    );
  }

  void _openChoiceTab() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openSpellingTab() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _clearChoiceForcedWord() {
    if (!mounted) {
      return;
    }
    setState(() {
      _choiceForcedWordId = null;
    });
  }

  void _clearSpellingForcedWord() {
    if (!mounted) {
      return;
    }
    setState(() {
      _spellingForcedWordId = null;
    });
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.56)
        : const Color(0xFFF1F4FA);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WordBookPage(
        reloadTick: _reloadTick,
        onDataChanged: _refreshAll,
        onOpenChoice: _openChoiceTab,
        onOpenSpelling: _openSpellingTab,
        onContinueChoice: _openChoiceSession,
        onContinueSpelling: _openSpellingSession,
      ),
      MultipleChoicePage(
        forcedWordId: _choiceForcedWordId,
        forcedRequestId: _choiceForcedRequestId,
        sessionModule: _choiceSessionModule,
        sessionSubgroup: _choiceSessionSubgroup,
        reloadTick: _reloadTick,
        onForcedWordConsumed: _clearChoiceForcedWord,
        onResultSaved: _refreshAll,
      ),
      SpellingPage(
        forcedWordId: _spellingForcedWordId,
        forcedRequestId: _spellingForcedRequestId,
        sessionModule: _spellingSessionModule,
        sessionSubgroup: _spellingSessionSubgroup,
        reloadTick: _reloadTick,
        onForcedWordConsumed: _clearSpellingForcedWord,
        onResultSaved: _refreshAll,
      ),
      MistakesPage(
        reloadTick: _reloadTick,
        onTrainChoice: _openChoiceRetrain,
        onTrainSpelling: _openSpellingRetrain,
      ),
      ProgressPage(reloadTick: _reloadTick),
    ];
    final isDarkMode = widget.themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final navBorderColor = isDarkMode
        ? colorScheme.outlineVariant.withValues(alpha: 0.42)
        : const Color(0xFFE3E8F2);
    final navShadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.36)
        : const Color(0x1F0B1020);
    return Scaffold(
      appBar: AppBar(
        title: const Text('英语单词学习'),
        actions: [
          _buildAppBarAction(
            icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
            tooltip: isDarkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: widget.onToggleThemeMode,
          ),
          _buildAppBarAction(
            icon: Icons.refresh,
            tooltip: '刷新数据',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: navBorderColor),
              boxShadow: [
                BoxShadow(
                  color: navShadowColor,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  _buildDestination(
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book,
                    label: '单词本',
                  ),
                  _buildDestination(
                    icon: Icons.quiz_outlined,
                    selectedIcon: Icons.quiz,
                    label: '选择题',
                  ),
                  _buildDestination(
                    icon: Icons.spellcheck_outlined,
                    selectedIcon: Icons.spellcheck,
                    label: '拼写',
                  ),
                  _buildDestination(
                    icon: Icons.report_problem_outlined,
                    selectedIcon: Icons.report_problem,
                    label: '错题本',
                  ),
                  _buildDestination(
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights,
                    label: '统计',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
