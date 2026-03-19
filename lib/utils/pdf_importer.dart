import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/word.dart';

class PdfImportResult {
  PdfImportResult({
    required this.words,
    required this.skippedLines,
    required this.totalTextLength,
    required this.preview,
  });

  final List<Word> words;
  final int skippedLines;
  final int totalTextLength;
  final String preview;
}

class PdfImporter {
  static final RegExp _lineSlashRegExp =
      RegExp(r"^([A-Za-z][A-Za-z'-]*)\s*/([^/]{1,80})/\s*(.+)$");
  static final RegExp _lineBracketRegExp =
      RegExp(r"^([A-Za-z][A-Za-z'-]*)\s*\[([^\]]{1,80})\]\s*(.+)$");
  static final RegExp _lineNoPhoneticRegExp =
      RegExp(r"^([A-Za-z][A-Za-z'-]*)\s+(.+)$");
  static final RegExp _fullTextSlashRegExp = RegExp(
    r"([A-Za-z][A-Za-z'-]*)\s*/([^/]{1,80})/\s*(.+?)(?=(?:\s+[A-Za-z][A-Za-z'-]*\s*(?:/[^/]{1,80}/|\[[^\]]{1,80}\]))|$)",
    dotAll: true,
  );
  static final RegExp _fullTextBracketRegExp = RegExp(
    r"([A-Za-z][A-Za-z'-]*)\s*\[([^\]]{1,80})\]\s*(.+?)(?=(?:\s+[A-Za-z][A-Za-z'-]*\s*(?:/[^/]{1,80}/|\[[^\]]{1,80}\]))|$)",
    dotAll: true,
  );
  static final RegExp _posPrefixRegExp =
      RegExp(r'^(n\.|v\.|vt\.|vi\.|adj\.|adv\.|prep\.|conj\.|pron\.)\s*', caseSensitive: false);
  static final RegExp _leadingPhoneticRegExp =
      RegExp(r"^(?:\[?[^\u4e00-\u9fff]{1,40}\]?)\s*");
  static final RegExp _chineseRegExp = RegExp(r'[\u4e00-\u9fff]');

  Future<String?> pickPdfPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.single.path;
  }

  Future<PdfImportResult> parsePdf(String path) async {
    final text = await _extractPdfText(path);
    final lines = text.split(RegExp(r'\r?\n'));

    final words = <Word>[];
    final seenWords = <String>{};
    var skipped = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final parsed = _tryParseLine(line);
      if (parsed == null || !seenWords.add(parsed.word)) {
        skipped++;
        continue;
      }
      words.add(parsed);
    }

    if (words.isEmpty) {
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      for (final match in _fullTextSlashRegExp.allMatches(normalized)) {
        final word = (match.group(1) ?? '').trim().toLowerCase();
        final phonetic = (match.group(2) ?? '').trim();
        final meaning = _normalizeMeaning((match.group(3) ?? '').trim());
        if (!_isValidWordEntry(word, meaning) || !seenWords.add(word)) {
          continue;
        }
        words.add(Word(word: word, phonetic: phonetic, meaning: meaning));
      }

      if (words.isEmpty) {
        for (final match in _fullTextBracketRegExp.allMatches(normalized)) {
          final word = (match.group(1) ?? '').trim().toLowerCase();
          final phonetic = (match.group(2) ?? '').trim();
          final meaning = _normalizeMeaning((match.group(3) ?? '').trim());
          if (!_isValidWordEntry(word, meaning) || !seenWords.add(word)) {
            continue;
          }
          words.add(Word(word: word, phonetic: phonetic, meaning: meaning));
        }
      }
    }

    final preview = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return PdfImportResult(
      words: words,
      skippedLines: skipped,
      totalTextLength: text.length,
      preview: preview.length > 180 ? preview.substring(0, 180) : preview,
    );
  }

  Word? _tryParseLine(String line) {
    final slashMatch = _lineSlashRegExp.firstMatch(line);
    if (slashMatch != null) {
      final word = (slashMatch.group(1) ?? '').trim().toLowerCase();
      final phonetic = (slashMatch.group(2) ?? '').trim();
      final meaning = _normalizeMeaning((slashMatch.group(3) ?? '').trim());
      if (_isValidWordEntry(word, meaning)) {
        return Word(word: word, phonetic: phonetic, meaning: meaning);
      }
    }

    final bracketMatch = _lineBracketRegExp.firstMatch(line);
    if (bracketMatch != null) {
      final word = (bracketMatch.group(1) ?? '').trim().toLowerCase();
      final phonetic = (bracketMatch.group(2) ?? '').trim();
      final meaning = _normalizeMeaning((bracketMatch.group(3) ?? '').trim());
      if (_isValidWordEntry(word, meaning)) {
        return Word(word: word, phonetic: phonetic, meaning: meaning);
      }
    }

    final noPhoneticMatch = _lineNoPhoneticRegExp.firstMatch(line);
    if (noPhoneticMatch != null) {
      final word = (noPhoneticMatch.group(1) ?? '').trim().toLowerCase();
      final meaning = _normalizeMeaning((noPhoneticMatch.group(2) ?? '').trim());
      if (_isValidWordEntry(word, meaning)) {
        return Word(word: word, phonetic: '', meaning: meaning);
      }
    }

    return null;
  }

  String _normalizeMeaning(String value) {
    var meaning = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    meaning = meaning.replaceFirst(_leadingPhoneticRegExp, '').trim();
    meaning = meaning.replaceFirst(_posPrefixRegExp, '').trim();
    final firstChinese = meaning.indexOf(RegExp(r'[\u4e00-\u9fff]'));
    if (firstChinese >= 0) {
      meaning = meaning.substring(firstChinese).trim();
    }
    return meaning;
  }

  bool _isValidWordEntry(String word, String meaning) {
    if (word.isEmpty || meaning.isEmpty) {
      return false;
    }

    final validWord = RegExp(r"^[a-z][a-z'-]*$").hasMatch(word);
    if (!validWord) {
      return false;
    }

    // Prefer lines with Chinese meaning to reduce false positives.
    return _chineseRegExp.hasMatch(meaning);
  }

  Future<String> _extractPdfText(String path) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final document = await PDFDoc.fromPath(path);
      return document.text;
    }

    return _extractPdfTextWithSyncfusion(path);
  }

  Future<String> _extractPdfTextWithSyncfusion(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      return extractor.extractText();
    } finally {
      document.dispose();
    }
  }
}
