import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/mistakes_page.dart';
import 'pages/multiple_choice_page.dart';
import 'pages/progress_page.dart';
import 'pages/spelling_page.dart';
import 'pages/word_book_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const EnglishWordApp());
}

class EnglishWordApp extends StatelessWidget {
  const EnglishWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Word App 898989',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  int _reloadTick = 0;
  int? _choiceForcedWordId;
  int? _spellingForcedWordId;

  void _refreshAll() {
    setState(() {
      _reloadTick++;
    });
  }

  void _openChoiceRetrain(int wordId) {
    setState(() {
      _choiceForcedWordId = wordId;
      _selectedIndex = 1;
      _reloadTick++;
    });
  }

  void _openSpellingRetrain(int wordId) {
    setState(() {
      _spellingForcedWordId = wordId;
      _selectedIndex = 2;
      _reloadTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WordBookPage(
        reloadTick: _reloadTick,
        onDataChanged: _refreshAll,
      ),
      MultipleChoicePage(
        forcedWordId: _choiceForcedWordId,
        reloadTick: _reloadTick,
        onResultSaved: _refreshAll,
      ),
      SpellingPage(
        forcedWordId: _spellingForcedWordId,
        reloadTick: _reloadTick,
        onResultSaved: _refreshAll,
      ),
      MistakesPage(
        reloadTick: _reloadTick,
        onTrainChoice: _openChoiceRetrain,
        onTrainSpelling: _openSpellingRetrain,
      ),
      ProgressPage(reloadTick: _reloadTick),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('英语单词学习'),
        actions: [
          IconButton(
            tooltip: '刷新数据',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: pages[_selectedIndex],
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

