import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/screens/record/write/diary_emotion_explore_screen.dart';
import 'package:care_garden/screens/record/write/diary_situation_screen.dart';
import 'package:care_garden/services/auth_service.dart';
import 'package:care_garden/services/diary_service.dart';

void main() {
  testWidgets('입력 중에도 본문과 다음 버튼을 유지하고 화면을 스크롤할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DiarySituationScreen()));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    expect(find.text('다음'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.tap(fields.first);
    await tester.pump();

    expect(fields, findsNWidgets(2));
    expect(find.text('다음'), findsOneWidget);

    await tester.tap(fields.at(1));
    await tester.pump();

    final bodyField = tester.widget<TextField>(fields.at(1));
    expect(bodyField.focusNode?.hasFocus, isTrue);
    expect(bodyField.minLines, 6);
    expect(find.text('다음'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('AI 질문 답변 중에는 질문과 입력창 및 다음 버튼을 유지한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: DiaryEmotionExploreScreen(
          draft: DiaryDraft(id: 1, aiQuestion: '그때 어떤 마음이 들었나요?'),
          tokens: AuthTokens(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            tokenType: 'bearer',
          ),
        ),
      ),
    );

    expect(find.text('그때 어떤 마음이 들었나요?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final answerField = tester.widget<TextField>(find.byType(TextField));
    expect(answerField.focusNode?.hasFocus, isTrue);
    expect(find.text('그때 어떤 마음이 들었나요?'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
