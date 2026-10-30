import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/main.dart';
import 'package:care_garden/screens/auth/login_screen.dart';

void main() {
  testWidgets('앱 실행 시 로그인 화면의 입력창과 버튼을 표시한다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CareGardenApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.bySemanticsLabel('로그인'), findsOneWidget);

    expect(
      find.image(
        const AssetImage('assets/auth/login/login_button.png'),
      ),
      findsOneWidget,
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                'assets/auth/login/signup_text.svg',
      ),
      findsOneWidget,
    );
  });
}