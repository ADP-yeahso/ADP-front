import 'package:flutter/material.dart';

enum Emotion { joy, calm, sadness, anger, guilt }

extension EmotionInfo on Emotion {
  String get label => switch (this) {
        Emotion.joy => '기쁨',
        Emotion.calm => '평온',
        Emotion.sadness => '슬픔',
        Emotion.anger => '분노',
        Emotion.guilt => '죄책감',
      };

  Color get color => switch (this) {
        Emotion.joy => const Color(0xFFF6B93B),
        Emotion.calm => const Color(0xFF6FBF8B),
        Emotion.sadness => const Color(0xFF6B93D1),
        Emotion.anger => const Color(0xFFE1613B),
        Emotion.guilt => const Color(0xFF9B7FC7),
      };

  IconData get flowerIcon => switch (this) {
        Emotion.joy => Icons.local_florist,
        Emotion.calm => Icons.spa,
        Emotion.sadness => Icons.water_drop,
        Emotion.anger => Icons.whatshot,
        Emotion.guilt => Icons.dark_mode,
      };
}
