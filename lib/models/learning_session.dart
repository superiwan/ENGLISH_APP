class LearningSession {
  LearningSession({
    required this.sessionKey,
    required this.mode,
    required this.module,
    required this.subgroup,
    this.currentWordId,
    required this.currentIndex,
    required this.totalCount,
    required this.updatedAt,
  });

  final String sessionKey;
  final String mode;
  final String module;
  final String subgroup;
  final int? currentWordId;
  final int currentIndex;
  final int totalCount;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'session_key': sessionKey,
      'mode': mode,
      'module': module,
      'subgroup': subgroup,
      'current_word_id': currentWordId,
      'current_index': currentIndex,
      'total_count': totalCount,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      sessionKey: map['session_key'] as String? ?? '',
      mode: map['mode'] as String? ?? '',
      module: map['module'] as String? ?? '',
      subgroup: map['subgroup'] as String? ?? '',
      currentWordId: map['current_word_id'] as int?,
      currentIndex: map['current_index'] as int? ?? 0,
      totalCount: map['total_count'] as int? ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? 0,
      ),
    );
  }

  LearningSession copyWith({
    String? sessionKey,
    String? mode,
    String? module,
    String? subgroup,
    int? currentWordId,
    int? currentIndex,
    int? totalCount,
    DateTime? updatedAt,
  }) {
    return LearningSession(
      sessionKey: sessionKey ?? this.sessionKey,
      mode: mode ?? this.mode,
      module: module ?? this.module,
      subgroup: subgroup ?? this.subgroup,
      currentWordId: currentWordId ?? this.currentWordId,
      currentIndex: currentIndex ?? this.currentIndex,
      totalCount: totalCount ?? this.totalCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
