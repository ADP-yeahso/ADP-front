import 'dart:ui' as ui;

import 'package:care_garden/data/care_activity_catalog.dart';
import 'package:care_garden/data/garden_nav_controller.dart';
import 'package:care_garden/screens/record/write/diary_care_content_screen.dart';
import 'package:care_garden/models/emotions.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Emotion? emotionFor(String? code) =>
    code == null ? null : Emotion(id: 42, name: code, displayName: '감정');

Widget app(
  String? code, {
  double scale = 1,
  VoidCallback? letter,
  VoidCallback? manual,
}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: DiaryCareContentScreen(
    emotion: emotionFor(code),
    onOpenLetter: letter,
    onOpenManual: manual,
  ),
);

Finder card(String id) => find.byKey(ValueKey('care-activity-$id'));

void main() {
  for (final code in [
    'anger',
    'anxiety',
    'sadness',
    'guilt',
    'gratitude',
    'tenderness',
    'neutral',
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$code: 320px 화면과 글자 배율 $scale 에서 카드가 잘리지 않는다', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(code, scale: scale));
        final activities = CareActivityCatalog.activitiesFor(code);
        for (final activity in activities) {
          expect(find.text(activity.title), findsOneWidget);
          await tester.ensureVisible(card(activity.id));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            tester.widget<Text>(find.text(activity.title)).maxLines,
            isNull,
          );
        }
        expect(
          tester.getTopLeft(card('letter')).dy,
          tester.getTopLeft(card('manual')).dy,
        );
        expect(
          tester.getTopLeft(card(activities[2].id)).dy,
          greaterThan(tester.getTopLeft(card('letter')).dy),
        );
        expect(find.byTooltip('홈으로').hitTestable(), findsOneWidget);
      });
    }
  }

  testWidgets('활동 완료만 체크하고 재열기와 나중에도 완료를 유지한다', (tester) async {
    await tester.pumpWidget(app('anger'));
    final semantics = tester.getSemantics(
      find.bySemanticsLabel('4-4-6 호흡하기, 활동 보기'),
    );
    expect(
      semantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.ensureVisible(card('anger_breathe'));
    await tester.tap(card('anger_breathe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('숨을 참기 불편하면'), findsOneWidget);
    await tester.tap(find.text('나중에 할게요'));
    await tester.pumpAndSettle();
    expect(find.text('완료했어요'), findsNothing);
    await tester.tap(card('anger_breathe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('활동 완료'));
    await tester.pumpAndSettle();
    expect(find.text('완료했어요'), findsOneWidget);
    expect(find.bySemanticsLabel('4-4-6 호흡하기, 완료'), findsOneWidget);
    await tester.tap(card('anger_breathe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 할게요'));
    await tester.pumpAndSettle();
    expect(find.text('완료했어요'), findsOneWidget);
  });

  testWidgets('안내창을 뒤로 닫으면 완료되지 않는다', (tester) async {
    await tester.pumpWidget(app('neutral'));
    await tester.ensureVisible(card('neutral_music'));
    await tester.tap(card('neutral_music'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('활동 완료'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('완료했어요'), findsNothing);
  });

  testWidgets('연결되지 않은 공통 활동은 준비 중 안내를 표시한다', (tester) async {
    await tester.pumpWidget(app('anger'));
    await tester.tap(card('letter'));
    await tester.pump();
    expect(find.text('익명 편지함은 준비 중이에요.'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(card('letter')),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(card('manual'));
    await tester.pump();
    expect(find.text('치매 관리 매뉴얼은 준비 중이에요.'), findsOneWidget);
    expect(find.text('활동 완료'), findsNothing);
    expect(find.text('완료했어요'), findsNothing);
  });

  testWidgets('공통 활동은 제공된 기존 화면 연결 함수를 호출한다', (tester) async {
    var letters = 0;
    var manuals = 0;
    await tester.pumpWidget(
      app('anger', letter: () => letters++, manual: () => manuals++),
    );
    await tester.tap(card('letter'));
    await tester.tap(card('manual'));
    expect(letters, 1);
    expect(manuals, 1);
    expect(find.text('활동 완료'), findsNothing);
  });

  testWidgets('모르는 감정은 공통 활동만 제공한다', (tester) async {
    await tester.pumpWidget(app('unknown'));
    expect(card('letter'), findsOneWidget);
    expect(card('manual'), findsOneWidget);
    expect(find.textContaining('맞춤 활동을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('좋아하는 노래 한 곡 듣기'), findsNothing);
  });

  testWidgets('홈 버튼은 오늘 날짜를 요청하고 첫 화면으로 돌아간다', (tester) async {
    final nav = GardenNavController();
    addTearDown(nav.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: nav,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DiaryCareContentScreen(emotion: emotionFor('neutral')),
                  ),
                ),
                child: const Text('기존 홈'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('기존 홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('홈으로'));
    await tester.pumpAndSettle();
    expect(find.text('기존 홈'), findsOneWidget);
    expect(find.byType(DiaryCareContentScreen), findsNothing);
    expect(
      nav.pendingDate!.difference(DateTime.now()).inSeconds.abs(),
      lessThan(5),
    );
  });
}
