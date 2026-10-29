import 'package:care_garden/screens/auth/login_screen.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('빈 로그인 제출은 입력 안내를 표시한다', (tester) async {
    tester.view.physicalSize = const Size(351, 727);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.ensureVisible(find.bySemanticsLabel('로그인'));
    await tester.tap(find.bySemanticsLabel('로그인'));
    await tester.pump();
    expect(find.text('이메일과 비밀번호를 입력해주세요.'), findsOneWidget);
    expect(find.text('추천 활동 미리보기 (디버그)'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
