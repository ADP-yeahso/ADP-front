import 'package:flutter/material.dart';

class EmotionModel {
  final String name;
  final Color color;

  const EmotionModel({
    required this.name,
    required this.color,
  });
}

class EmotionData {
  static const List<EmotionModel> emotions = [
    EmotionModel(name: '분노/답답', color: Color(0xFFE36887)),
    EmotionModel(name: '불안/초조', color: Color(0xFFF5F5F5)),
    EmotionModel(name: '슬픔/소진', color: Color(0xFF5EA7FF)),
    EmotionModel(name: '중립', color: Color(0xFF88C24D)),
    EmotionModel(name: '죄책감/자책', color: Color(0xFFD09ED7)),
    EmotionModel(name: '감사/안도', color: Color(0xFFFFE367)),
    EmotionModel(name: '애틋/수용', color: Color(0xFFFF9131)),
  ];
}
