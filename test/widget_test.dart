import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/main.dart';
import 'package:care_garden/screens/auth/login_screen.dart';

void main() {
  testWidgets('App launches to the garden home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CareGardenApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}
