import 'package:care_garden/screens/auth/family_group_list_screen.dart';
import 'package:care_garden/screens/auth/login_screen.dart';
import 'package:care_garden/screens/debug/care_activity_preview_screen.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('기존 로그인 버튼은 서버 없이 기존 가족 그룹 화면으로 이동한다', (tester) async {
    tester.view.physicalSize = const Size(351, 727);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.ensureVisible(find.bySemanticsLabel('로그인'));
    await tester.tap(find.bySemanticsLabel('로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(FamilyGroupListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('디버그 버튼은 인증 상태 없이 추천 미리보기를 연다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    final entry = find.text('추천 활동 미리보기 (디버그)');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(CareActivityPreviewScreen), findsOneWidget);
    for (final label in [
      '분노·답답함',
      '불안·초조',
      '슬픔·소진',
      '죄책감·자책',
      '감사·안도',
      '애틋함·수용',
      '중립',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
