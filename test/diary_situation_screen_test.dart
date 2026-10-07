import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/screens/record/write/diary_situation_screen.dart';

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
}
