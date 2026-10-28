import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/models/emotions.dart';
import 'package:care_garden/screens/profile/emotion_analysis_screen.dart';
import 'package:care_garden/utils/emotion_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'charts use saved API emotions instead of classifying the text again',
    (tester) async {
      final data = AppData();
      addTearDown(data.dispose);
      final now = DateTime.now();
      data.addDiary(
        date: now,
        content: '화나고 불안하고 슬퍼요.',
        emotion: EmotionValues.gratitude,
      );
      data.addDiary(
        date: now,
        content: '행복하고 감사해요.',
        emotion: Emotion(id: 0, name: 'neutral', displayName: '중립'),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppData>.value(
          value: data,
          child: const MaterialApp(home: EmotionAnalysisScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections, hasLength(2));
      expect(chart.data.sections.map((section) => section.value), [50, 50]);
      expect(chart.data.sections.map((section) => section.color), [
        EmotionValues.gratitude.color,
        EmotionValues.neutral.color,
      ]);
    },
  );
}
