import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:care_garden/main.dart';
import 'package:care_garden/screens/auth/login_screen.dart';

void main() {
  testWidgets('앱은 이메일과 비밀번호를 입력하는 로그인 화면으로 시작한다', (WidgetTester tester) async {
    await tester.pumpWidget(const CareGardenApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.bySemanticsLabel('로그인'), findsOneWidget);
  });
}
