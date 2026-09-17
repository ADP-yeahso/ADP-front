import 'package:flutter/material.dart';
import '../models/emotions.dart';

class EmotionValues {
  // 1. 분노 / 답답함
  static final anger = Emotion(
    id: 1,
    name: 'anger',
    displayName: '분노/답답함',
  );

  // 2. 불안 / 초조
  static final anxiety = Emotion(
    id: 2,
    name: 'anxiety',
    displayName: '불안/초조',
  );

  // 3. 슬픔 / 소진
  static final sadness = Emotion(
    id: 3,
    name: 'sadness',
    displayName: '슬픔/소진',
  );

  // 4. 죄책감 / 자책
  static final guilt = Emotion(
    id: 4,
    name: 'guilt',
    displayName: '죄책감/자책',
  );

  // 5. 감사 / 안도
  static final gratitude = Emotion(
    id: 5,
    name: 'gratitude',
    displayName: '감사/안도',
  );

  // 6. 애틋함 / 수용
  static final affection = Emotion(
    id: 6,
    name: 'affection',
    displayName: '애틋함/수용',
  );

  // 7. 중립
  static final neutral = Emotion(
    id: 7,
    name: 'neutral',
    displayName: '중립',
  );

  static final values = [
    anger,
    anxiety,
    sadness,
    guilt,
    gratitude,
    affection,
    neutral,
  ];
}

extension EmotionInfo on Emotion {
  String get label => displayName;

  Color get color {
    switch (id) {
      case 1:
        return const Color(0xFFE36887); // 분노/답답함 - 임시 핑크

      case 2:
        return const Color(0xFFF5F5F5); // 불안/초조 - 임시 연회색

      case 3:
        return const Color(0xFF5EA7FF); // 슬픔/소진 - 임시 파랑

      case 4:
        return const Color(0xFFD09ED7); // 죄책감/자책 - 임시 보라

      case 5:
        return const Color(0xFFFFE367); // 감사/안도 - 임시 노랑

      case 6:
        return const Color(0xFFFF9131); // 애틋함/수용 - 임시 주황

      case 7:
        return const Color(0xFF88C24D); // 중립 - 임시 초록

      default:
        return Colors.grey;
    }
  }

  IconData get flowerIcon {
    switch (id) {
      case 1:
        return Icons.whatshot;

      case 2:
        return Icons.air_rounded;

      case 3:
        return Icons.water_drop;

      case 4:
        return Icons.dark_mode;

      case 5:
        return Icons.wb_sunny_outlined;

      case 6:
        return Icons.favorite_border_rounded;

      case 7:
        return Icons.spa;

      default:
        return Icons.circle;
    }
  }
}