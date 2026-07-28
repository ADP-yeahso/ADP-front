import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/family_member.dart';
import '../models/patient_leaf.dart';
import 'emotion_analyzer.dart';

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class AppData extends ChangeNotifier {
  AppData() {
    _seed();
  }

  final String patientRelationLabel = '아버지';

  final List<FamilyMember> familyMembers = [
    const FamilyMember(
      id: 'me',
      nickname: '닉네임 1',
      relation: '딸',
      color: Color(0xFF6B93D1),
      isMe: true,
    ),
    const FamilyMember(
      id: 'f2',
      nickname: '닉네임 2',
      relation: '아들',
      color: Color(0xFF6FBF8B),
    ),
    const FamilyMember(
      id: 'f3',
      nickname: '닉네임 3',
      relation: '며느리',
      color: Color(0xFF9B7FC7),
    ),
  ];

  FamilyMember get me => familyMembers.firstWhere((m) => m.isMe);

  FamilyMember memberById(String id) =>
      familyMembers.firstWhere((m) => m.id == id, orElse: () => me);

  final List<PatientLeaf> leaves = [];
  final List<DiaryEntry> diaries = [];

  int _idCounter = 1000;
  String _nextId() => (_idCounter++).toString();

  void addLeaf({
    required DateTime date,
    required String title,
    required String content,
    bool hasPhoto = false,
    bool isPublic = true,
  }) {
    leaves.add(PatientLeaf(
      id: _nextId(),
      date: date,
      title: title,
      content: content,
      authorId: me.id,
      hasPhoto: hasPhoto,
      isPublic: isPublic,
    ));
    notifyListeners();
  }

  DiaryEntry addDiary({
    required DateTime date,
    required String content,
    bool isPublic = true,
  }) {
    final analysis = analyzeEmotion(content);
    final entry = DiaryEntry(
      id: _nextId(),
      date: date,
      content: content,
      authorId: me.id,
      emotion: analysis.primary,
      emotionScores: analysis.scores,
      recommendation: recommendationFor(analysis.primary),
      isPublic: isPublic,
    );
    diaries.add(entry);
    notifyListeners();
    return entry;
  }

  DiaryEntry? diaryById(String id) {
    try {
      return diaries.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void toggleLeafPublic(String id) {
    final leaf = leaves.firstWhere((l) => l.id == id);
    leaf.isPublic = !leaf.isPublic;
    notifyListeners();
  }

  void toggleDiaryPublic(String id) {
    final diary = diaries.firstWhere((d) => d.id == id);
    diary.isPublic = !diary.isPublic;
    notifyListeners();
  }

  List<PatientLeaf> leavesForMonth(DateTime month) =>
      leaves.where((l) => isSameMonth(l.date, month)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<DiaryEntry> diariesForMonth(DateTime month) =>
      diaries.where((d) => isSameMonth(d.date, month)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<DateTime> entryDatesForMonth(DateTime month) => {
        ...leavesForMonth(month).map((l) => l.date),
        ...diariesForMonth(month).map((d) => d.date),
      }.toList();

  List<DiaryEntry> get sharedDiaries =>
      diaries.where((d) => d.isPublic).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<PatientLeaf> get sharedLeaves =>
      leaves.where((l) => l.isPublic).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Emotion? latestEmotionFor(String authorId) {
    final entries = diaries.where((d) => d.authorId == authorId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (entries.isEmpty) return null;
    return entries.first.emotion;
  }

  void _seed() {
    final today = DateTime.now();
    DateTime d(int monthsAgo, int day) =>
        DateTime(today.year, today.month - monthsAgo, day);

    addLeaf(
      date: d(2, 6),
      title: '함께 본 옛날 사진',
      content: '$patientRelationLabel과 함께 젊은 시절 사진을 꺼내 보았다. 잠시 웃으셨다.',
      hasPhoto: true,
    );
    addLeaf(
      date: d(1, 12),
      title: '병원 정기 검진',
      content: '정기 검진을 다녀왔다. 컨디션은 평소와 비슷하다는 소견을 들었다.',
    );
    addLeaf(
      date: d(0, 3),
      title: '산책',
      content: '날씨가 좋아 근처 공원을 함께 걸었다. $patientRelationLabel이 꽃 이름을 물으셨다.',
      hasPhoto: true,
    );

    addDiary(date: d(2, 8), content: '오늘은 유난히 지치고 눈물이 났다. 혼자 감당하기 힘든 하루였다.');
    addDiary(date: d(1, 15), content: '$patientRelationLabel이 나를 못 알아봐서 속상하고 화가 났다.');
    addDiary(
      date: d(1, 22),
      content: '$patientRelationLabel이 옛날 이야기를 하며 웃어서 오늘은 참 고맙고 행복했다.',
    );
    addDiary(
      date: d(0, 2),
      content: '어제 짜증을 낸 것 같아 미안하고 후회된다. 더 잘해드리고 싶다.',
      isPublic: false,
    );
    addDiary(date: d(0, 5), content: '오늘은 그냥 편안하고 괜찮은 하루였다.');
  }
}
