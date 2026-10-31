import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:full_svg_flutter/full_svg_flutter.dart' as full_svg;
import 'package:provider/provider.dart';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/calendar/day_record_detail_view.dart';

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

final DateTime _selectedDay = DateTime(2026, 8, 10);

AppData _createEmptyAppData() {
  final appData = AppData();

  appData.memories.clear();
  appData.diaries.clear();

  return appData;
}

Widget _buildTestApp(AppData appData) {
  return ChangeNotifierProvider<AppData>.value(
    value: appData,
    child: MaterialApp(
      home: Scaffold(
        body: DayRecordDetailView(
          day: _selectedDay,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    '선택한 날짜의 나무 기록만 표시하고 꽃 기록으로 전환한다',
    (WidgetTester tester) async {
      final appData = _createEmptyAppData();

      addTearDown(appData.dispose);

      appData.addMemory(
        date: _selectedDay,
        title: '선택 날짜 나무 기록',
        content: '선택한 날짜의 나무 기록 내용',
      );

      appData.addMemory(
        date: _selectedDay.add(const Duration(days: 1)),
        title: '다른 날짜 나무 기록',
        content: '다른 날짜의 나무 기록 내용',
      );

      appData.addDiary(
        date: _selectedDay,
        content: '선택한 날짜의 꽃 기록 내용',
      );

      appData.addDiary(
        date: _selectedDay.add(const Duration(days: 1)),
        content: '다른 날짜의 꽃 기록 내용',
      );

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      expect(_svgAsset('assets/page2/record_detail/tree_record_label.svg'), findsWidgets);
      expect(_svgAsset('assets/page2/record_detail/flower_record_label.svg'), findsOneWidget);

      expect(
        find.text('선택한 날짜의 나무 기록 내용'),
        findsOneWidget,
      );
      expect(
        find.text('다른 날짜의 나무 기록 내용'),
        findsNothing,
      );

      expect(
        find.text('선택한 날짜의 꽃 기록 내용'),
        findsNothing,
      );

      await tester.tap(_svgAsset('assets/page2/record_detail/flower_record_label.svg'));
      await tester.pumpAndSettle();

      expect(
        find.text('선택한 날짜의 나무 기록 내용'),
        findsNothing,
      );

      expect(
        find.text('선택한 날짜의 꽃 기록 내용'),
        findsOneWidget,
      );
      expect(
        find.text('다른 날짜의 꽃 기록 내용'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '기록이 없으면 나무 기록과 꽃 기록의 빈 화면을 표시한다',
    (WidgetTester tester) async {
      final appData = _createEmptyAppData();

      addTearDown(appData.dispose);

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

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

      expect(
        find.text('이 날짜에는 나무 기록이 없어요.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '나무 기록 카드를 누르면 기존 나무 기록 상세 시트가 열린다',
    (WidgetTester tester) async {
      final appData = _createEmptyAppData();

      addTearDown(appData.dispose);

      appData.addMemory(
        date: _selectedDay,
        title: '상세 확인용 나무 기록',
        content: '나무 기록 상세 열기 테스트',
      );

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      expect(
        find.text('나무 기록 상세 열기 테스트'),
        findsOneWidget,
      );

      await tester.tap(
        find.text('나무 기록 상세 열기 테스트'),
      );
      await tester.pumpAndSettle();

      expect(find.text('가족 기록'), findsOneWidget);
      expect(find.text('가족에게 공개'), findsOneWidget);
    },
  );

  testWidgets(
    '꽃 기록 카드를 누르면 기존 감정 일기 상세 시트가 열린다',
    (WidgetTester tester) async {
      final appData = _createEmptyAppData();

      addTearDown(appData.dispose);

      appData.addDiary(
        date: _selectedDay,
        content: '꽃 기록 상세 열기 테스트',
      );

      await tester.pumpWidget(_buildTestApp(appData));
      await tester.pumpAndSettle();

      await tester.tap(_svgAsset('assets/page2/record_detail/flower_record_label.svg'));
      await tester.pumpAndSettle();

      expect(
        find.text('꽃 기록 상세 열기 테스트'),
        findsOneWidget,
      );

      await tester.tap(
        find.text('꽃 기록 상세 열기 테스트'),
      );
      await tester.pumpAndSettle();

      expect(find.text('감정 일기'), findsOneWidget);
    },
  );
}