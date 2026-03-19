class MistakeRecord {
  MistakeRecord({
    required this.wordId,
    required this.type,
    required this.count,
    this.word,
    this.meaning,
  });

  final int wordId;
  final String type;
  final int count;
  final String? word;
  final String? meaning;

  factory MistakeRecord.fromMap(Map<String, dynamic> map) {
    return MistakeRecord(
      wordId: map['word_id'] as int,
      type: map['type'] as String,
      count: map['count'] as int? ?? 0,
      word: map['word'] as String?,
      meaning: map['meaning'] as String?,
    );
  }
}
