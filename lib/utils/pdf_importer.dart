import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  static final RegExp _zeroWidthRegExp = RegExp(r'[\u200B-\u200D\uFEFF]');
  static final RegExp _noiseChunkRegExp = RegExp(
    r'(/\s*[^/\n]{1,60}\s*/|\[\s*[^\]\n]{1,60}\s*\]|\(\s*[^\)\n]{1,60}\s*\)|（\s*[^）\n]{1,60}\s*）|【\s*[^】\n]{1,60}\s*】|［\s*[^］\n]{1,60}\s*］)',
  );
  static final RegExp _posPrefixRegExp = RegExp(
      r'^(n\.|v\.|vt\.|vi\.|adj\.|adv\.|prep\.|conj\.|pron\.)\s*',
      caseSensitive: false);
  static final RegExp _chineseRegExp = RegExp(r'[\u4e00-\u9fff]');
  static final RegExp _phoneticCleanupRegExp = RegExp(
      r'[^\u00C0-\u024F\u0250-\u02AF\u02B0-\u02FF\u0300-\u036FA-Za-z0-9.\-:ˈˌːˑʰʲʷʱʔʕɫɚɝɾɹɐɜɞɒɔɛəɪʊθðʃʒŋç]');
  static final RegExp _meaningCleanupRegExp = RegExp(
    r'[^\u4e00-\u9fff，。；：、！？（）()【】《》〈〉「」『』·…—\-~]',
  );
  static final RegExp _meaningTrimRegExp =
      RegExp(r'^[，。；：、！？·…—\-（）()【】《》〈〉]+|[，。；：、！？·…—\-（）()【】《》〈〉]+$');
  static final RegExp _standalonePosRegExp = RegExp(
    r'(^|[，,；;、:：\s])(?:n|v|vt|vi|adj|adv|prep|conj|pron|art|num|int|pl|sb|sth|abbr|aux|modal|imp)\.?(?=[，,；;、:：\s]|$)',
    caseSensitive: false,
  );
  static final RegExp _standaloneNumberRegExp = RegExp(
    r'(^|[，,；;、:：\s])(?:\(?\s*(?:\d+|[①-⑳])\s*[\).、．:]?\s*)(?=[，,；;、:：\s]|$)',
  );
  static final RegExp _danglingNumberRegExp =
      RegExp(r'(?:\s*(?:\d+|[①-⑳])\s*[)）．.、:]?)+$');
  static final RegExp _allNumberRegExp = RegExp(r'[0-9０-９①-⑳]');

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
        final parsed = _buildWord(
          match.group(1) ?? '',
          match.group(2) ?? '',
          match.group(3) ?? '',
        );
        if (!_isValidWordEntry(parsed.word, parsed.meaning) ||
            !seenWords.add(parsed.word)) {
          continue;
        }
        words.add(parsed);
      }

      if (words.isEmpty) {
        for (final match in _fullTextBracketRegExp.allMatches(normalized)) {
          final parsed = _buildWord(
            match.group(1) ?? '',
            match.group(2) ?? '',
            match.group(3) ?? '',
          );
          if (!_isValidWordEntry(parsed.word, parsed.meaning) ||
              !seenWords.add(parsed.word)) {
            continue;
          }
          words.add(parsed);
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

  static Word normalizeImportedWord(Word word) {
    return Word(
      word: word.word.trim().toLowerCase(),
      phonetic: _normalizePhonetic(word.phonetic),
      meaning: _normalizeMeaning(word.meaning),
      phrase: word.phrase,
      prefix: word.prefix,
      suffix: word.suffix,
      similarWords: word.similarWords,
      synonyms: word.synonyms,
      familiarity: word.familiarity,
      wrongCount: word.wrongCount,
      rightCount: word.rightCount,
    );
  }

  Word? _tryParseLine(String line) {
    final slashMatch = _lineSlashRegExp.firstMatch(line);
    if (slashMatch != null) {
      final parsed = _buildWord(
        slashMatch.group(1) ?? '',
        slashMatch.group(2) ?? '',
        slashMatch.group(3) ?? '',
      );
      if (_isValidWordEntry(parsed.word, parsed.meaning)) {
        return parsed;
      }
    }

    final bracketMatch = _lineBracketRegExp.firstMatch(line);
    if (bracketMatch != null) {
      final parsed = _buildWord(
        bracketMatch.group(1) ?? '',
        bracketMatch.group(2) ?? '',
        bracketMatch.group(3) ?? '',
      );
      if (_isValidWordEntry(parsed.word, parsed.meaning)) {
        return parsed;
      }
    }

    final noPhoneticMatch = _lineNoPhoneticRegExp.firstMatch(line);
    if (noPhoneticMatch != null) {
      final parsed = _buildWord(
        noPhoneticMatch.group(1) ?? '',
        '',
        noPhoneticMatch.group(2) ?? '',
      );
      if (_isValidWordEntry(parsed.word, parsed.meaning)) {
        return parsed;
      }
    }

    return null;
  }

  static Word _buildWord(String word, String phonetic, String meaning) {
    return Word(
      word: word.trim().toLowerCase(),
      phonetic: _normalizePhonetic(phonetic),
      meaning: _normalizeMeaning(meaning.trim()),
    );
  }

  static String _normalizeMeaning(String value) {
    var meaning = value.replaceAll(_zeroWidthRegExp, '');
    meaning = meaning.replaceAll(RegExp(r'\s+'), ' ').trim();
    meaning = _removeNoiseChunks(meaning);
    meaning = meaning.replaceFirst(_posPrefixRegExp, '').trim();
    meaning = meaning.replaceFirst(
        RegExp(r'^(?:\(?\s*(?:\d+|[①-⑳])\s*[\).、．:]?\s*)+'), '');
    meaning = _removeNoiseChunks(meaning);
    meaning = meaning.replaceAll(_standalonePosRegExp, r'$1');
    meaning = meaning.replaceAll(_standaloneNumberRegExp, r'$1');
    final firstChinese = meaning.indexOf(RegExp(r'[\u4e00-\u9fff]'));
    if (firstChinese >= 0) {
      meaning = meaning.substring(firstChinese).trim();
    }
    meaning = meaning.replaceAll(_meaningCleanupRegExp, '');
    meaning = meaning.replaceAll(_danglingNumberRegExp, '');
    meaning = meaning.replaceAll(_allNumberRegExp, '');
    meaning = meaning.replaceAll(RegExp(r'\s+'), '');
    meaning = meaning.replaceAll(_meaningTrimRegExp, '');
    return meaning.trim();
  }

  static String _removeNoiseChunks(String value) {
    return value.replaceAllMapped(_noiseChunkRegExp, (match) {
      final chunk = match.group(0) ?? '';
      return _chineseRegExp.hasMatch(chunk) ? chunk : ' ';
    });
  }

  static String _normalizePhonetic(String value) {
    var phonetic = value.replaceAll(_zeroWidthRegExp, '').trim();
    if (phonetic.isEmpty) {
      return '';
    }

    phonetic = phonetic.replaceAll(RegExp(r'\s+'), '');
    phonetic = phonetic.replaceAll(RegExp(r'^[\[/【［\(\{（｛]+'), '');
    phonetic = phonetic.replaceAll(RegExp(r'[\]/】］\)\}）｝]+$'), '');
    phonetic = phonetic.replaceAll(RegExp(r'[【】［］（）(){}<>《》、,，。；;|·•…]'), '');
    phonetic = phonetic.replaceAll(RegExp(r"[“”‘’']"), '');
    phonetic = phonetic.replaceAll(_phoneticCleanupRegExp, '');
    phonetic = phonetic.replaceAll(RegExp(r'/+'), '');
    phonetic = phonetic.trim();
    if (phonetic.isEmpty) {
      return '';
    }

    return '/$phonetic/';
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
