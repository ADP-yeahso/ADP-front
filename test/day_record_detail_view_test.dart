import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:full_svg_flutter/full_svg_flutter.dart' as full_svg;
import 'package:provider/provider.dart';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/data/flower_catalog.dart';
import 'package:care_garden/models/diary.dart';
import 'package:care_garden/models/flower.dart';
import 'package:care_garden/models/media.dart';
import 'package:care_garden/screens/calendar/day_record_detail_view.dart';
import 'package:care_garden/screens/garden/entry_detail_sheet.dart';
import 'package:care_garden/utils/emotion_utils.dart';

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
      home: Scaffold(body: DayRecordDetailView(day: _selectedDay)),
    ),
  );
}

void main() {
  testWidgets('선택한 날짜의 나무 기록만 표시하고 꽃 기록으로 전환한다', (WidgetTester tester) async {
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

    appData.addDiary(date: _selectedDay, content: '선택한 날짜의 꽃 기록 내용');

    appData.addDiary(
      date: _selectedDay.add(const Duration(days: 1)),
      content: '다른 날짜의 꽃 기록 내용',
    );

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    expect(
      _svgAsset('assets/page2/record_detail/tree_record_label.svg'),
      findsWidgets,
    );
    expect(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
      findsOneWidget,
    );

    expect(find.text('선택한 날짜의 나무 기록 내용'), findsOneWidget);
    expect(find.text('다른 날짜의 나무 기록 내용'), findsNothing);

    expect(find.text('선택한 날짜의 꽃 기록 내용'), findsNothing);

    await tester.tap(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
    );
    await tester.pumpAndSettle();

    expect(find.text('선택한 날짜의 나무 기록 내용'), findsNothing);

    expect(find.text('선택한 날짜의 꽃 기록 내용'), findsOneWidget);
    expect(find.text('다른 날짜의 꽃 기록 내용'), findsNothing);
  });

  testWidgets('기록이 없으면 나무 기록과 꽃 기록의 빈 화면을 표시한다', (WidgetTester tester) async {
    final appData = _createEmptyAppData();

    addTearDown(appData.dispose);

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    expect(find.text('이 날짜에는 나무 기록이 없어요.'), findsOneWidget);

    await tester.tap(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 날짜에는 꽃 기록이 없어요.'), findsOneWidget);

    expect(find.text('이 날짜에는 나무 기록이 없어요.'), findsNothing);
  });

  testWidgets('나무 기록 카드를 누르면 기존 나무 기록 상세 시트가 열린다', (WidgetTester tester) async {
    final appData = _createEmptyAppData();

    addTearDown(appData.dispose);

    appData.addMemory(
      date: _selectedDay,
      title: '상세 확인용 나무 기록',
      content: '나무 기록 상세 열기 테스트',
      mediaList: [
        Media(
          id: 501,
          memoryId: null,
          diaryId: null,
          fileUrl: 'assets/images/flower.png',
          fileType: 'image',
          duration: null,
          sortOrder: 0,
          createdAt: _selectedDay,
        ),
      ],
    );
    final memoryId = appData.memories.single.id;

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    expect(find.text('나무 기록 상세 열기 테스트'), findsOneWidget);

    await tester.tap(find.text('나무 기록 상세 열기 테스트'));
    await tester.pumpAndSettle();

    expect(find.text('가족 기록'), findsOneWidget);
    expect(find.text('가족에게 공개'), findsOneWidget);
    expect(
      find.byKey(ValueKey('memory-detail-photo-$memoryId-501')),
      findsOneWidget,
    );
    expect(find.text('사진이 첨부되었어요'), findsNothing);
  });

  testWidgets('꽃 기록 카드를 누르면 기존 감정 일기 상세 시트가 열린다', (WidgetTester tester) async {
    final appData = _createEmptyAppData();

    addTearDown(appData.dispose);

    appData.addDiary(date: _selectedDay, content: '꽃 기록 상세 열기 테스트');

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();

    await tester.tap(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
    );
    await tester.pumpAndSettle();

    expect(find.text('꽃 기록 상세 열기 테스트'), findsOneWidget);

    await tester.tap(find.text('꽃 기록 상세 열기 테스트'));
    await tester.pumpAndSettle();

    expect(find.text('감정 일기'), findsOneWidget);
  });

  testWidgets('완료된 꽃 기록의 더보기에는 수정 버튼을 표시하지 않는다', (tester) async {
    final appData = _createEmptyAppData();
    addTearDown(appData.dispose);
    appData.addDiary(date: _selectedDay, content: '수정할 수 없는 완료 기록');

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();
    await tester.tap(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
    );
    await tester.pumpAndSettle();
    await tester.tap(_svgAsset('assets/page2/record_detail/more_icon.svg'));
    await tester.pumpAndSettle();

    expect(_svgAsset('assets/page2/record_detail/edit.svg'), findsNothing);
    expect(_svgAsset('assets/page2/record_detail/delete.svg'), findsOneWidget);
  });

  testWidgets('서버 꽃이 없어도 AI 1순위 최종 감정의 꽃 카드를 표시한다', (tester) async {
    final appData = _createEmptyAppData();
    addTearDown(appData.dispose);
    final emotion = EmotionValues.affection;
    const diaryId = 91;
    final expectedCard = FlowerCatalog.randomCardForEmotion(
      emotion,
      random: Random(diaryId),
    );
    final now = DateTime(2026, 8, 10, 12);
    final diary = Diary(
      id: diaryId,
      userId: 'user-1',
      context: 'AI 분석 결과로 만든 꽃 카드',
      flowerType: Flower(
        id: 0,
        emotionId: emotion,
        flowerName: '',
        colorCode: '',
        sentence: '',
      ),
      mediaList: const [],
      recordDate: _selectedDay,
      createdAt: now,
      updatedAt: now,
      isFinalized: false,
    );
    appData.diaries.add(diary);

    await tester.pumpWidget(_buildTestApp(appData));
    await tester.pumpAndSettle();
    await tester.tap(
      _svgAsset('assets/page2/record_detail/flower_record_label.svg'),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('diary-flower-card-91')),
    );
    expect((image.image as AssetImage).assetName, expectedCard.assetPath);
    expect(find.text(expectedCard.name), findsOneWidget);
    expect(find.text(expectedCard.meaning), findsOneWidget);
  });

  testWidgets('나무 기억보기 목록에도 첨부 사진을 썸네일로 표시한다', (tester) async {
    final appData = _createEmptyAppData();
    addTearDown(appData.dispose);
    appData.addMemory(
      date: _selectedDay,
      title: '사진 기록',
      content: '함께 올린 사진',
      mediaList: [
        Media(
          id: 502,
          memoryId: null,
          diaryId: null,
          fileUrl: 'assets/images/flower.png',
          fileType: 'image',
          duration: null,
          sortOrder: 0,
          createdAt: _selectedDay,
        ),
      ],
    );
    final memory = appData.memories.single;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppData>.value(
        value: appData,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMemoryListSheet(context, [memory]),
              child: const Text('기억 보기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('기억 보기'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('memory-list-photo-${memory.id}')),
      findsOneWidget,
    );
  });
}
