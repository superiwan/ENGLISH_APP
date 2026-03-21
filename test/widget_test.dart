import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:english_word_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App boots with navigation labels', (WidgetTester tester) async {
    await tester.pumpWidget(const EnglishWordApp());

    expect(find.text('单词本'), findsOneWidget);
    expect(find.text('选择题'), findsOneWidget);
    expect(find.text('拼写'), findsOneWidget);
  });
}
