import 'package:flutter/material.dart';
import '../models/emotions.dart';

class EmotionValues {
  static final joy = Emotion(id: 1, name: 'joy', displayName: '기쁨');
  static final calm = Emotion(id: 2, name: 'calm', displayName: '평온');
  static final sadness = Emotion(id: 3, name: 'sadness', displayName: '슬픔');
  static final anger = Emotion(id: 4, name: 'anger', displayName: '분노');
  static final guilt = Emotion(id: 5, name: 'guilt', displayName: '죄책감');

  static final values = [joy, calm, sadness, anger, guilt];
}

extension EmotionInfo on Emotion {
  String get label => displayName;

  Color get color {
    switch (id) {
      case 1: return const Color(0xFFF6B93B); // joy
      case 2: return const Color(0xFF6FBF8B); // calm
      case 3: return const Color(0xFF6B93D1); // sadness
      case 4: return const Color(0xFFE1613B); // anger
      case 5: return const Color(0xFF9B7FC7); // guilt
      default: return Colors.grey;
    }
  }

  IconData get flowerIcon {
    switch (id) {
      case 1: return Icons.local_florist;
      case 2: return Icons.spa;
      case 3: return Icons.water_drop;
      case 4: return Icons.whatshot;
      case 5: return Icons.dark_mode;
      default: return Icons.circle;
    }
  }
}
