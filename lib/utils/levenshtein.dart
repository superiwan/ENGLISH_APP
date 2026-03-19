int levenshteinDistance(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }

  final matrix = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );

  for (var i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }

  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }

  return matrix[a.length][b.length];
}

String mismatchHint(String expected, String input) {
  final maxLen = expected.length > input.length ? expected.length : input.length;
  final mismatchPositions = <int>[];

  for (var i = 0; i < maxLen; i++) {
    final expectedChar = i < expected.length ? expected[i] : '(空)';
    final inputChar = i < input.length ? input[i] : '(空)';
    if (expectedChar != inputChar) {
      mismatchPositions.add(i + 1);
    }
  }

  if (mismatchPositions.isEmpty) {
    return '拼写接近正确，但仍有格式差异。';
  }

  final positions = mismatchPositions.take(4).join('、');
  return '第 $positions 个字符可能有误，请再检查一下。';
}
