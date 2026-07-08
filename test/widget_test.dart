import 'package:flutter_test/flutter_test.dart';

import 'package:care_garden/main.dart';

void main() {
  testWidgets('App launches to the garden home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CareGardenApp());
    await tester.pumpAndSettle();

    expect(find.text('마음정원'), findsWidgets);
  });
}
