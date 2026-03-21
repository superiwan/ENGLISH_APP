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
  int? _spellingForcedWordId;
  int _spellingForcedRequestId = 0;

  void _refreshAll() {
    setState(() {
      _reloadTick++;
    });
  }

  void _openChoiceRetrain(int wordId) {
    setState(() {
      _choiceForcedWordId = wordId;
      _choiceForcedRequestId++;
      _selectedIndex = 1;
      _reloadTick++;
    });
  }

  void _openSpellingRetrain(int wordId) {
    setState(() {
      _spellingForcedWordId = wordId;
      _spellingForcedRequestId++;
      _selectedIndex = 2;
      _reloadTick++;
    });
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WordBookPage(
        reloadTick: _reloadTick,
        onDataChanged: _refreshAll,
        onOpenChoice: _openChoiceTab,
        onOpenSpelling: _openSpellingTab,
      ),
      MultipleChoicePage(
        forcedWordId: _choiceForcedWordId,
        forcedRequestId: _choiceForcedRequestId,
        reloadTick: _reloadTick,
        onForcedWordConsumed: _clearChoiceForcedWord,
        onResultSaved: _refreshAll,
      ),
      SpellingPage(
        forcedWordId: _spellingForcedWordId,
        forcedRequestId: _spellingForcedRequestId,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('英语单词学习'),
        actions: [
          IconButton(
            tooltip: isDarkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: widget.onToggleThemeMode,
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: '刷新数据',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: '单词本'),
          NavigationDestination(icon: Icon(Icons.quiz), label: '选择题'),
          NavigationDestination(icon: Icon(Icons.spellcheck), label: '拼写'),
          NavigationDestination(icon: Icon(Icons.report_problem), label: '错题本'),
          NavigationDestination(icon: Icon(Icons.insights), label: '统计'),
        ],
      ),
    );
  }
}
