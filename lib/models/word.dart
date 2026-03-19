class Word {
  Word({
    this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    this.phrase,
    this.prefix,
    this.suffix,
    this.similarWords,
    this.synonyms,
    this.familiarity = 0,
    this.wrongCount = 0,
    this.rightCount = 0,
  });

  final int? id;
  final String word;
  final String phonetic;
  final String meaning;
  final String? phrase;
  final String? prefix;
  final String? suffix;
  final String? similarWords;
  final String? synonyms;
  final int familiarity;
  final int wrongCount;
  final int rightCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'phrase': phrase,
      'prefix': prefix,
      'suffix': suffix,
      'similar_words': similarWords,
      'synonyms': synonyms,
      'familiarity': familiarity,
      'wrong_count': wrongCount,
      'right_count': rightCount,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String? ?? '',
      phonetic: map['phonetic'] as String? ?? '',
      meaning: map['meaning'] as String? ?? '',
      phrase: map['phrase'] as String?,
      prefix: map['prefix'] as String?,
      suffix: map['suffix'] as String?,
      similarWords: map['similar_words'] as String?,
      synonyms: map['synonyms'] as String?,
      familiarity: map['familiarity'] as int? ?? 0,
      wrongCount: map['wrong_count'] as int? ?? 0,
      rightCount: map['right_count'] as int? ?? 0,
    );
  }

  Word copyWith({
    int? id,
    String? word,
    String? phonetic,
    String? meaning,
    String? phrase,
    String? prefix,
    String? suffix,
    String? similarWords,
    String? synonyms,
    int? familiarity,
    int? wrongCount,
    int? rightCount,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      meaning: meaning ?? this.meaning,
      phrase: phrase ?? this.phrase,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      similarWords: similarWords ?? this.similarWords,
      synonyms: synonyms ?? this.synonyms,
      familiarity: familiarity ?? this.familiarity,
      wrongCount: wrongCount ?? this.wrongCount,
      rightCount: rightCount ?? this.rightCount,
    );
  }
}
