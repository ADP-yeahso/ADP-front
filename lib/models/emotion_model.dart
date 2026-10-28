import 'package:flutter/material.dart';

class EmotionModel {
  final String name;
  final Color color;

  const EmotionModel({
    required this.name,
    required this.color,
  });
}

class EmotionCategory {
  final int id;
  final String label;
  final Color color;
  final List<String> subEmotionNames;

  const EmotionCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.subEmotionNames,
  });

  List<EmotionModel> get subEmotions {
    return subEmotionNames
        .map((name) => EmotionModel(name: name, color: color))
        .toList();
  }
}

class EmotionCategories {
  static const Map<String, EmotionCategory> categories = {
    '1': EmotionCategory(
      id: 1,
      label: '분노/답답함',
      color: Color(0xFFE36887), // SVG 3-2-5 분노답답 컬러박스 (#E36887)
      subEmotionNames: ['억울함', '짜증', '무력감', '원망스러움', '속상함'],
    ),
    '2': EmotionCategory(
      id: 2,
      label: '불안/초조',
      color: Color(0xFFAEAEAE), // SVG 3-2-5 슬픔/불안 메인 블루 계열 (#5EA7FF)
      subEmotionNames: ['막막함', '예민함', '압박감', '당혹감', '두려움'],
    ),
    '3': EmotionCategory(
      id: 3,
      label: '슬픔/소진',
      color: Color(0xFF5EA7FF), // 퍼플 슬레이트 계열 (#8C80C8)
      subEmotionNames: ['상실감', '탈진', '서러움', '허무함', '안타까움'],
    ),
    '4': EmotionCategory(
      id: 4,
      label: '죄책감/자책',
      color: Color(0xFFD09ED7), // SVG 3-2-5 죄책감자책 컬러박스 (#D09ED7)
      subEmotionNames: ['자책감', '미안함', '부족함', '후회스러움', '부끄러움'],
    ),
    '5': EmotionCategory(
      id: 5,
      label: '감사/안도',
      color: Color(0xFFFFE367), // SVG 3-2-5 감사안도 컬러박스 (#FFE367)
      subEmotionNames: ['다행스러움', '따뜻함', '편안함', '고마움', '뿌듯함'],
    ),
    '6': EmotionCategory(
      id: 6,
      label: '애틋함/수용',
      color: Color(0xFFFF9131), // 공식 EmotionData 오렌지 계열 (#FF9131)
      subEmotionNames: ['그리움', '뭉클함', '사랑스러움', '소중함', '안쓰러움'],
    ),
    '0': EmotionCategory(
      id: 0,
      label: '중립/일상',
      color: Color(0xFF88C24D), // SVG 3-2-5 중립 컬러박스 (#88C24D)
      subEmotionNames: ['담담함', '무탈함', '여유로움', '무심함', '차분함'],
    ),
  };

  /// AI 감정 분석 결과 라벨 (예: 1, 5 또는 '분노/답답함')을 입력 받아 하위 감정 5개 리스트 반환
  static List<EmotionModel>? getSubEmotionsForCategory(dynamic categoryKey) {
    if (categoryKey == null) return null;
    final keyStr = categoryKey.toString().trim();

    for (final entry in categories.entries) {
      if (entry.key == keyStr ||
          entry.value.id.toString() == keyStr ||
          entry.value.label == keyStr ||
          entry.value.label.replaceAll('/', '') == keyStr.replaceAll('/', '')) {
        return entry.value.subEmotions;
      }
    }
    return null;
  }
}

class EmotionData {
  static const List<EmotionModel> emotions = [
    EmotionModel(name: '분노/답답', color: Color(0xFFE36887)),
    EmotionModel(name: '불안/초조', color: Color(0xFFAEAEAE)),
    EmotionModel(name: '슬픔/소진', color: Color(0xFF5EA7FF)),
    EmotionModel(name: '중립', color: Color(0xFF88C24D)),
    EmotionModel(name: '죄책감/자책', color: Color(0xFFD09ED7)),
    EmotionModel(name: '감사/안도', color: Color(0xFFFFE367)),
    EmotionModel(name: '애틋/수용', color: Color(0xFFFF9131)),
  ];
}

