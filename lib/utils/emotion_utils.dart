import 'package:flutter/material.dart';
import '../models/emotions.dart';

class EmotionValues {
  static final anger = Emotion(id: 1, name: 'anger', displayName: '분노');
  static final anxiety = Emotion(id: 2, name: 'anxiety', displayName: '불안');
  static final sadness = Emotion(id: 3, name: 'sadness', displayName: '슬픔');
  static final guilt = Emotion(id: 4, name: 'guilt', displayName: '죄책감');
  static final gratitude = Emotion(id: 5, name: 'gratitude', displayName: '감사');
  static final affection = Emotion(id: 6, name: 'affection', displayName: '애정');

  static final values = [anger, anxiety, sadness, guilt, gratitude, affection];
}

extension EmotionInfo on Emotion {
  String get label => displayName;

  Color get color {
    switch (name) {
      case 'anger': return const Color(0xFFE1613B);
      case 'anxiety': return const Color(0xFFF6B93B);
      case 'sadness': return const Color(0xFF6B93D1);
      case 'guilt': return const Color(0xFF9B7FC7);
      case 'gratitude': return const Color(0xFF6FBF8B);
      case 'affection': return const Color(0xFFF48FB1);
      default: return Colors.grey;
    }
  }

  IconData get flowerIcon {
    switch (name) {
      case 'anger': return Icons.whatshot;
      case 'anxiety': return Icons.warning;
      case 'sadness': return Icons.water_drop;
      case 'guilt': return Icons.dark_mode;
      case 'gratitude': return Icons.volunteer_activism;
      case 'affection': return Icons.favorite;
      default: return Icons.circle;
    }
  }
}
