import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../models/emotions.dart';
import '../models/flower.dart';
import '../models/media.dart';
import '../models/memory.dart';
import '../models/users.dart';
import 'emotion_analyzer.dart';

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

extension UserUIInfo on User {
  bool get isMe => id == 1;
  String get nickname => name;
  String get relation {
    if (id == 1) return '딸';
    if (id == 2) return '아들';
    return '며느리';
  }
  Color get color {
    if (id == 1) return const Color(0xFF6B93D1);
    if (id == 2) return const Color(0xFF6FBF8B);
    return const Color(0xFF9B7FC7);
  }
}

class AppData extends ChangeNotifier {
  AppData() {
    _seed();
  }

  final String patientRelationLabel = '아버지';

  final List<User> users = [
    User(
      id: 1,
      email: 'me@example.com',
      password: '',
      name: '닉네임 1',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
    User(
      id: 2,
      email: 'son@example.com',
      password: '',
      name: '닉네임 2',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
    User(
      id: 3,
      email: 'inlaw@example.com',
      password: '',
      name: '닉네임 3',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
  ];

  User get me => users.firstWhere((u) => u.isMe);

  User userById(int id) => users.firstWhere((u) => u.id == id, orElse: () => me);

  final List<Memory> memories = [];
  final List<Diary> diaries = [];
  
  // To keep track of public states since Diary doesn't have isPublic
  final Set<int> _publicDiaryIds = {};

  int _idCounter = 1000;
  int _nextId() => _idCounter++;

  void addMemory({
    required DateTime date,
    required String title, // Used as mock UI title if needed
    required String content,
    List<Media> mediaList = const [],
    bool hasPhoto = false,
    bool isPublic = true,
  }) {
    List<Media> targetMedia = mediaList;
    if (targetMedia.isEmpty && hasPhoto) {
      targetMedia = [
        Media(
          id: _nextId(),
          memoryId: null,
          diaryId: null,
          fileUrl: 'dummy.jpg',
          fileType: 'image',
          duration: 0,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      ];
    }

    // 메모리 저장 시 각 미디어의 연관 ID 세팅
    final memoryId = _nextId();
    final updatedMedia = targetMedia
        .map((m) => Media(
              id: m.id,
              memoryId: memoryId,
              diaryId: null,
              fileUrl: m.fileUrl,
              fileType: m.fileType,
              duration: m.duration,
              sortOrder: m.sortOrder,
              createdAt: m.createdAt,
            ))
        .toList();

    memories.add(Memory(
      id: memoryId,
      patientId: 1,
      userId: me.id,
      contextText: content,
      mediaList: updatedMedia,
      isPublic: isPublic,
      recordDate: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Diary addDiary({
    required DateTime date,
    required String content,
    List<Media> mediaList = const [],
    bool isPublic = true,
  }) {
    final analysis = analyzeEmotion(content);
    final flower = Flower(
      id: analysis.primary.id,
      emotionId: analysis.primary,
      flowerName: 'Mock Flower',
      colorCode: '#000000',
      sentence: 'Mock sentence',
    );

    final diaryId = _nextId();
    final updatedMedia = mediaList
        .map((m) => Media(
              id: m.id,
              memoryId: null,
              diaryId: diaryId,
              fileUrl: m.fileUrl,
              fileType: m.fileType,
              duration: m.duration,
              sortOrder: m.sortOrder,
              createdAt: m.createdAt,
            ))
        .toList();

    final entry = Diary(
      id: diaryId,
      userId: me.id,
      context: content,
      flowerType: flower,
      mediaList: updatedMedia,
      recordDate: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    diaries.add(entry);
    if (isPublic) {
      _publicDiaryIds.add(entry.id);
    }
    notifyListeners();
    return entry;
  }

  Diary? diaryById(int id) {
    try {
      return diaries.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
  
  bool isDiaryPublic(int id) => _publicDiaryIds.contains(id);

  void toggleMemoryPublic(int id) {
    final idx = memories.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final old = memories[idx];
      memories[idx] = Memory(
        id: old.id,
        patientId: old.patientId,
        userId: old.userId,
        contextText: old.contextText,
        mediaList: old.mediaList,
        isPublic: !old.isPublic,
        recordDate: old.recordDate,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void toggleDiaryPublic(int id) {
    if (_publicDiaryIds.contains(id)) {
      _publicDiaryIds.remove(id);
    } else {
      _publicDiaryIds.add(id);
    }
    notifyListeners();
  }

  List<Memory> memoriesForMonth(DateTime month) =>
      memories.where((m) => isSameMonth(m.recordDate, month)).toList()
        ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

  List<Diary> diariesForMonth(DateTime month) =>
      diaries.where((d) => isSameMonth(d.recordDate, month)).toList()
        ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

  List<DateTime> entryDatesForMonth(DateTime month) => {
        ...memoriesForMonth(month).map((m) => m.recordDate),
        ...diariesForMonth(month).map((d) => d.recordDate),
      }.toList();

  List<Diary> get sharedDiaries =>
      diaries.where((d) => _publicDiaryIds.contains(d.id)).toList()
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

  List<Memory> get sharedMemories =>
      memories.where((m) => m.isPublic).toList()
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

  Emotion? latestEmotionFor(int userId) {
    final entries = diaries.where((d) => d.userId == userId).toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
    if (entries.isEmpty) return null;
    return entries.first.flowerType.emotionId;
  }

  void _seed() {
    final today = DateTime.now();
    DateTime d(int monthsAgo, int day) =>
        DateTime(today.year, today.month - monthsAgo, day);

    addMemory(
      date: d(2, 6),
      title: '함께 본 옛날 사진',
      content: '$patientRelationLabel과 함께 젊은 시절 사진을 꺼내 보았다. 잠시 웃으셨다.',
      mediaList: [
        Media(
          id: 0,
          memoryId: null,
          diaryId: null,
          fileUrl: 'dummy.jpg',
          fileType: 'image',
          duration: 0,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      ],
    );
    addMemory(
      date: d(1, 12),
      title: '병원 정기 검진',
      content: '정기 검진을 다녀왔다. 컨디션은 평소와 비슷하다는 소견을 들었다.',
    );
    addMemory(
      date: d(0, 3),
      title: '산책',
      content: '날씨가 좋아 근처 공원을 함께 걸었다. $patientRelationLabel이 꽃 이름을 물으셨다.',
      mediaList: [
        Media(
          id: 0,
          memoryId: null,
          diaryId: null,
          fileUrl: 'dummy.jpg',
          fileType: 'image',
          duration: 0,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      ],
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
