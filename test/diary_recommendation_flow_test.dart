import 'package:care_garden/data/care_activity_catalog.dart';
import 'package:care_garden/data/garden_nav_controller.dart';
import 'package:care_garden/screens/debug/care_activity_preview_screen.dart';
import 'package:care_garden/screens/record/write/diary_care_content_screen.dart';
import 'package:care_garden/screens/record/write/diary_result_screen.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:care_garden/utils/emotion_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final emotion in EmotionValues.values) {
    testWidgets('${emotion.name}: 결과 화면에서 같은 감정을 추천에 전달한다', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final nav = GardenNavController();
      addTearDown(nav.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: nav,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CareActivityPreviewScreen(),
          ),
        ),
      );
      final group = CareActivityCatalog.groupFor(emotion.name)!;
      final label = find.text(group.label);
      await tester.ensureVisible(label);
      await tester.tap(label);
      await tester.pumpAndSettle();
      final result = tester.widget<DiaryResultScreen>(
        find.byType(DiaryResultScreen),
      );
      expect(result.emotion, same(emotion));
      await tester.ensureVisible(find.text('다음'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      final care = tester.widget<DiaryCareContentScreen>(
        find.byType(DiaryCareContentScreen),
      );
      expect(care.emotion, same(emotion));
      for (final activity in CareActivityCatalog.activitiesFor(emotion.name)) {
        expect(find.text(activity.title), findsOneWidget);
      }
      await tester.tap(find.byTooltip('홈으로'));
      await tester.pumpAndSettle();
      expect(find.byType(CareActivityPreviewScreen), findsOneWidget);
      expect(nav.pendingDate, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('감정 없이 결과 화면에 진입해도 중립으로 추정해 추천하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const DiaryResultScreen()),
    );
    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    final care = tester.widget<DiaryCareContentScreen>(
      find.byType(DiaryCareContentScreen),
    );
    expect(care.emotion, isNull);
    expect(find.textContaining('맞춤 활동을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('좋아하는 노래 한 곡 듣기'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
