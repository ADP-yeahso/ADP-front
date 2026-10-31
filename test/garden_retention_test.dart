import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/data/garden_range.dart';
import 'package:care_garden/utils/emotion_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flowers remain in the garden for 365 days without a daily reset', () {
    final data = AppData();
    addTearDown(data.dispose);
    final today = DateTime(2026, 11, 1);

    final yesterday = data.addDiary(
      date: today.subtract(const Duration(days: 1)),
      content: '어제 기록',
      emotion: EmotionValues.gratitude,
    );
    final firstDay = data.addDiary(
      date: gardenWindowStart(today),
      content: '365일 범위의 첫 기록',
      emotion: EmotionValues.neutral,
    );
    data.addDiary(
      date: gardenWindowStart(today).subtract(const Duration(days: 1)),
      content: '보존 기간이 지난 기록',
      emotion: EmotionValues.sadness,
    );

    expect(data.diariesForGarden(today).map((diary) => diary.id), [
      firstDay.id,
      yesterday.id,
    ]);
  });

  test('a flower planted today is still present tomorrow', () {
    final data = AppData();
    addTearDown(data.dispose);
    final today = DateTime(2026, 11, 1);
    final flower = data.addDiary(
      date: today,
      content: '오늘 기록',
      emotion: EmotionValues.affection,
    );

    final tomorrow = today.add(const Duration(days: 1));
    expect(data.diariesForGarden(tomorrow).single.id, flower.id);
  });
}
