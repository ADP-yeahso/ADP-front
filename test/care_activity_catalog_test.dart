import 'package:care_garden/data/care_activity_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expected = {
    'anger': ['4-4-6 호흡하기', '잠깐 자리 옮기고 물 마시기'],
    'anxiety': ['창밖이나 하늘 바라보기', '나에게 다정한 말 건네기'],
    'sadness': ['좋아하는 노래 한 곡 듣기', '5분 쉬거나 할 일 하나 미루기'],
    'guilt': ['오늘 해낸 돌봄 한 가지 떠올리기', '스스로 칭찬하기'],
    'gratitude': ['좋았던 순간 한 줄 기록하기', '오늘의 나에게 고맙다고 말하기'],
    'tenderness': ['상대가 편안해한다면 손잡거나 다정한 말 건네기', '함께한 사진 한 장 보기'],
    'neutral': ['좋아하는 노래 한 곡 듣기', '함께한 사진 한 장 보기'],
  };
  const colors = [
    0xFFE36887,
    0xFFAEAEAE,
    0xFF5EA7FF,
    0xFFD09ED7,
    0xFFFFE367,
    0xFFFF9131,
    0xFF88C24D,
  ];

  for (final entry in expected.entries) {
    test('${entry.key}: 공통 2개와 요구한 맞춤 활동 2개를 순서대로 제공한다', () {
      final activities = CareActivityCatalog.activitiesFor(entry.key);
      expect(activities, hasLength(4));
      expect(activities.take(2).map((a) => a.title), [
        '익명 편지함 작성하기',
        '치매 관리 매뉴얼 확인하기',
      ]);
      expect(activities.skip(2).map((a) => a.title), entry.value);
      expect(activities.map((a) => a.id).toSet(), hasLength(4));
      expect(activities.where((a) => a.isCommon), hasLength(2));
      final index = expected.keys.toList().indexOf(entry.key);
      expect(
        CareActivityCatalog.groupFor(entry.key)!.color,
        Color(colors[index]),
      );
    });
  }

  test('프론트 affection과 서버 tenderness는 동일한 추천을 사용한다', () {
    expect(
      CareActivityCatalog.groupFor('affection'),
      same(CareActivityCatalog.groupFor('tenderness')),
    );
  });

  test('감정 누락과 미지원 감정은 중립으로 바꾸지 않는다', () {
    for (final code in [null, '', 'unknown']) {
      expect(CareActivityCatalog.groupFor(code), isNull);
      expect(
        CareActivityCatalog.activitiesFor(code),
        CareActivityCatalog.common,
      );
    }
  });
}
