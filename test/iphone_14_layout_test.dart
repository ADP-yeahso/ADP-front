import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/calendar/calendar_screen.dart';
import 'package:care_garden/screens/record/write/diary_situation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  void usePhoneSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('iPhone 14 너비에서 월간 달력 셀이 넘치지 않는다', (tester) async {
    usePhoneSize(tester, const Size(390, 844));
    final appData = AppData();
    addTearDown(appData.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppData>.value(
        value: appData,
        child: MaterialApp(
          home: CalendarScreen(initialMonth: DateTime(2026, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone 14에서 키보드가 열려도 기록 화면이 넘치지 않는다', (tester) async {
    usePhoneSize(tester, const Size(390, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const MaterialApp(home: DiarySituationScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone 14 Pro에서도 기록 asset과 입력 영역이 넘치지 않는다', (tester) async {
    usePhoneSize(tester, const Size(393, 852));

    await tester.pumpWidget(const MaterialApp(home: DiarySituationScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
