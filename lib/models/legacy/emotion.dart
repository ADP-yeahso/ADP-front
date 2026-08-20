import 'package:flutter/material.dart';

enum Emotion { anger, anxiety, sadness, guilt, gratitude, affection }

extension EmotionInfo on Emotion {
  String get label => switch (this) {
        Emotion.anger => '분노',
        Emotion.anxiety => '불안',
        Emotion.sadness => '슬픔',
        Emotion.guilt => '죄책감',
        Emotion.gratitude => '감사',
        Emotion.affection => '애정',
      };

  Color get color => switch (this) {
        Emotion.anger => const Color(0xFFE1613B),
        Emotion.anxiety => const Color(0xFFF6B93B),
        Emotion.sadness => const Color(0xFF6B93D1),
        Emotion.guilt => const Color(0xFF9B7FC7),
        Emotion.gratitude => const Color(0xFF6FBF8B),
        Emotion.affection => const Color(0xFFF48FB1),
      };

  IconData get flowerIcon => switch (this) {
        Emotion.anger => Icons.whatshot,
        Emotion.anxiety => Icons.warning,
        Emotion.sadness => Icons.water_drop,
        Emotion.guilt => Icons.dark_mode,
        Emotion.gratitude => Icons.volunteer_activism,
        Emotion.affection => Icons.favorite,
      };
}
