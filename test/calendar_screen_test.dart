import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/calendar/calendar_screen.dart';

Widget _buildTestApp(AppData appData) {
  return ChangeNotifierProvider<AppData>.value(
    value: appData,
    child: const MaterialApp(home: CalendarScreen()),
  );
}

Future<void> _openMonth(WidgetTester tester, DateTime date) async {
  final month = find.text('${date.month}월');

  await tester.ensureVisible(month);
  await tester.pumpAndSettle();

  await tester.tap(month);
  await tester.pumpAndSettle();
}

Future<void> _openDay(WidgetTester tester, DateTime date) async {
  await _openMonth(tester, date);

  final day = find.byKey(
    ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
  );

  await tester.ensureVisible(day);
  await tester.pumpAndSettle();

  await tester.tap(day);
  await tester.pumpAndSettle();
}

String _dayTitle(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}. $month. $day';
}

Future<void> _openStandaloneCalendar(
  WidgetTester tester,
  AppData data,
  CalendarScreen screen,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppData>.value(
      value: data,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => screen)),
              child: const Text('캘린더 열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('캘린더 열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('따로 연 월간 달력의 뒤로가기는 이전 화면으로 돌아간다', (tester) async {
    final data = AppData();
    addTearDown(data.dispose);
    await _openStandaloneCalendar(
      tester,
      data,
      CalendarScreen(initialMonth: DateTime.now()),
    );
    expect(find.byKey(const ValueKey('calendar-close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-back')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsNothing);
    expect(find.text('캘린더 열기'), findsOneWidget);
  });

  testWidgets('닫기는 월간·날짜 상세 어느 단계에서도 달력 전체를 닫는다', (tester) async {
    final data = AppData();
    addTearDown(data.dispose);
    final today = DateTime.now();
    for (final screen in [
      CalendarScreen(initialMonth: today),
      CalendarScreen(initialDay: today),
    ]) {
      await _openStandaloneCalendar(tester, data, screen);
      await tester.tap(find.byKey(const ValueKey('calendar-close')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsNothing);
      expect(find.text('캘린더 열기'), findsOneWidget);
    }
  });

  testWidgets('시스템 뒤로가기는 날짜·월·연간을 거쳐 이전 화면으로 돌아간다', (tester) async {
    final data = AppData();
    addTearDown(data.dispose);
    final today = DateTime.now();
    await _openStandaloneCalendar(tester, data, const CalendarScreen());
    await _openDay(tester, today);
    expect(find.text(_dayTitle(today)), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('${today.year}년 ${today.month}월'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('${today.year}'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsNothing);
    expect(find.text('캘린더 열기'), findsOneWidget);
  });

  testWidgets('연간 달력에서 월간 달력과 날짜 상세로 이동하고 뒤로간다', (WidgetTester tester) async {
    final appData = AppData();
    final today = DateTime.now();

    addTearDown(appData.dispose);

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    expect(find.text('${today.year}'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-close')), findsNothing);

    await _openMonth(tester, today);

    expect(find.text('${today.year}년 ${today.month}월'), findsOneWidget);

    final day = find.byKey(
      ValueKey('calendar-day-${today.year}-${today.month}-${today.day}'),
    );

    await tester.ensureVisible(day);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.text(_dayTitle(today)), findsOneWidget);
    expect(find.bySemanticsLabel('나무 기록'), findsWidgets);
    expect(find.bySemanticsLabel('꽃 기록'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-back')));
    await tester.pumpAndSettle();

    expect(find.text('${today.year}년 ${today.month}월'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-back')));
    await tester.pumpAndSettle();

    expect(find.text('${today.year}'), findsOneWidget);
  });

  testWidgets('날짜 상세는 나무 기록으로 시작하고 꽃 기록으로 전환된다', (WidgetTester tester) async {
    final appData = AppData();
    final today = DateTime.now();

    addTearDown(appData.dispose);

    appData.addMemory(
      date: today,
      title: '기록조회 테스트',
      content: '기록조회 테스트 나무 내용',
    );

    appData.addDiary(date: today, content: '기록조회 테스트 꽃 내용');

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    await _openDay(tester, today);

    expect(find.text('기록조회 테스트 나무 내용'), findsOneWidget);
    expect(find.text('기록조회 테스트 꽃 내용'), findsNothing);

    await tester.tap(find.bySemanticsLabel('꽃 기록').first);
    await tester.pumpAndSettle();

    expect(find.text('기록조회 테스트 나무 내용'), findsNothing);
    expect(find.text('기록조회 테스트 꽃 내용'), findsOneWidget);
  });

  testWidgets('기록이 없는 날짜에서 나무와 꽃 기록 없음 안내를 표시한다', (WidgetTester tester) async {
    final appData = AppData();
    final today = DateTime.now();

    addTearDown(appData.dispose);

    appData.memories.clear();
    appData.diaries.clear();

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    await _openDay(tester, today);

    expect(find.text('이 날짜에는 나무 기록이 없어요.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('꽃 기록'));
    await tester.pumpAndSettle();

    expect(find.text('이 날짜에는 꽃 기록이 없어요.'), findsOneWidget);
  });
}
