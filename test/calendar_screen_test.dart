import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:full_svg_flutter/full_svg_flutter.dart' as full_svg;
import 'package:provider/provider.dart';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/calendar/calendar_screen.dart';

Finder _svgAsset(String assetName) {
  return find.byWidgetPredicate((widget) {
    if (widget is svg.SvgPicture) {
      final loader = widget.bytesLoader;
      return loader is svg.SvgAssetLoader && loader.assetName == assetName;
    }
    if (widget is full_svg.SvgPicture) {
      final loader = widget.bytesLoader;
      return loader is full_svg.SvgAssetLoader && loader.assetName == assetName;
    }
    return false;
  });
}

Widget _buildTestApp(AppData appData) {
  return ChangeNotifierProvider<AppData>.value(
    value: appData,
    child: const MaterialApp(
      home: CalendarScreen(),
    ),
  );
}

Finder _dayNumber(DateTime date) {
  final String asset;
  if (date.weekday == DateTime.sunday) {
    asset = 'assets/page2/numbers/red/red_${date.day}.svg';
  } else if (date.weekday == DateTime.saturday) {
    asset = 'assets/page2/numbers/blue/blue_${date.day}.svg';
  } else {
    asset = 'assets/page2/numbers/black/${date.day}.svg';
  }
  return _svgAsset(asset);
}

Future<void> _tapBack(WidgetTester tester) async {
  final back = _svgAsset('assets/page2/record_detail/back_button.svg');
  await tester.ensureVisible(back);
  await tester.pumpAndSettle();
  await tester.tap(back);
}

Future<void> _openMonth(
  WidgetTester tester,
  DateTime date,
) async {
  final month = find.text('${date.month}월');

  await tester.ensureVisible(month);
  await tester.pumpAndSettle();

  await tester.tap(month);
  await tester.pumpAndSettle();
}

Future<void> _openDay(
  WidgetTester tester,
  DateTime date,
) async {
  await _openMonth(tester, date);

  final day = _dayNumber(date);

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

void main() {
  testWidgets(
    '연간 달력에서 월간 달력과 날짜 상세로 이동하고 뒤로간다',
    (WidgetTester tester) async {
      final appData = AppData();
      final today = DateTime.now();

      addTearDown(appData.dispose);

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      expect(
        find.text('${today.year}'),
        findsOneWidget,
      );

      await _openMonth(tester, today);

      expect(
        find.text('${today.year}년 ${today.month}월'),
        findsOneWidget,
      );

      final day = _dayNumber(today);

      await tester.ensureVisible(day);
      await tester.pumpAndSettle();
      await tester.tap(day);
      await tester.pumpAndSettle();

      expect(
        find.text(_dayTitle(today)),
        findsOneWidget,
      );
      expect(_svgAsset('assets/page2/record_detail/tree_record_label.svg'), findsWidgets);
      expect(_svgAsset('assets/page2/record_detail/flower_record_label.svg'), findsOneWidget);

      await _tapBack(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('${today.year}년 ${today.month}월'),
        findsOneWidget,
      );

      await _tapBack(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('${today.year}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '날짜 상세는 나무 기록으로 시작하고 꽃 기록으로 전환된다',
    (WidgetTester tester) async {
      final appData = AppData();
      final today = DateTime.now();

      addTearDown(appData.dispose);

      appData.addMemory(
        date: today,
        title: '기록조회 테스트',
        content: '기록조회 테스트 나무 내용',
      );

      appData.addDiary(
        date: today,
        content: '기록조회 테스트 꽃 내용',
      );

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      await _openDay(tester, today);

      expect(
        find.text('기록조회 테스트 나무 내용'),
        findsOneWidget,
      );
      expect(
        find.text('기록조회 테스트 꽃 내용'),
        findsNothing,
      );

      await tester.tap(_svgAsset('assets/page2/record_detail/flower_record_label.svg'));
      await tester.pumpAndSettle();

      expect(
        find.text('기록조회 테스트 나무 내용'),
        findsNothing,
      );
      expect(
        find.text('기록조회 테스트 꽃 내용'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '기록이 없는 날짜에서 나무와 꽃 기록 없음 안내를 표시한다',
    (WidgetTester tester) async {
      final appData = AppData();
      final today = DateTime.now();

      addTearDown(appData.dispose);

      appData.memories.clear();
      appData.diaries.clear();

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      await _openDay(tester, today);

      expect(
        find.text('이 날짜에는 나무 기록이 없어요.'),
        findsOneWidget,
      );

      await tester.tap(_svgAsset('assets/page2/record_detail/flower_record_label.svg'));
      await tester.pumpAndSettle();

      expect(
        find.text('이 날짜에는 꽃 기록이 없어요.'),
        findsOneWidget,
      );
    },
  );
}