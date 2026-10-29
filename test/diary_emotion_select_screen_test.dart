import 'package:care_garden/screens/record/write/diary_emotion_select_screen.dart';
import 'package:care_garden/services/diary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('emotion rows fit on a narrow phone screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const names = [
      '당당함',
      '그리움',
      '무탈함',
      '뭉클함',
      '여유로움',
      '사랑스러움',
      '무심함',
      '소중함',
      '차분함',
      '안쓰러움',
    ];
    final suggestions = List.generate(
      names.length,
      (index) => EmotionTagOption(
        id: index + 1,
        name: names[index],
        emotionName: index.isEven ? '애틋수용' : '중립일상',
        emotionId: index.isEven ? 5 : 7,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DiaryEmotionSelectScreen(
          draft: const DiaryDraft(id: 1, aiQuestion: ''),
          suggestions: suggestions,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
