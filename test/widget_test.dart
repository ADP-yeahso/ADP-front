import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/main.dart';
import 'package:care_garden/screens/auth/login_screen.dart';

void main() {
  testWidgets('App launches to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CareGardenApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
