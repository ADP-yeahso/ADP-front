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
    bool isPublic = true,
  }) {
    // 메모리 저장 시 각 미디어의 연관 ID 세팅
    final memoryId = _nextId();
    final updatedMedia = mediaList.map((m) => Media(
      id: m.id,
      memoryId: memoryId,
      diaryId: null,
      fileUrl: m.fileUrl,
      fileType: m.fileType,
      duration: m.duration,
      sortOrder: m.sortOrder,
      createdAt: m.createdAt,
    )).toList();

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
    required Emotion emotion,
    List<Media> mediaList = const [],
    bool isPublic = true,
  }) {
    final flower = Flower(
      id: emotion.id,
      emotionId: emotion,
      flowerName: 'Mock Flower',
      colorCode: '#000000',
      sentence: 'Mock sentence',
    );
    
    final diaryId = _nextId();
    final updatedMedia = mediaList.map((m) => Media(
      id: m.id,
      memoryId: null,
      diaryId: diaryId,
      fileUrl: m.fileUrl,
      fileType: m.fileType,
      duration: m.duration,
      sortOrder: m.sortOrder,
      createdAt: m.createdAt,
    )).toList();
    
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
        Media(id: 0, memoryId: null, diaryId: null, fileUrl: 'dummy.jpg', fileType: 'image', duration: 0, sortOrder: 1, createdAt: DateTime.now())
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
        Media(id: 0, memoryId: null, diaryId: null, fileUrl: 'dummy.jpg', fileType: 'image', duration: 0, sortOrder: 1, createdAt: DateTime.now())
      ],
    );
    addMemory(
      date: d(0, 8),
      title: '가족 모임',
      content: '오랜만에 온 가족이 모여 식사를 했다. $patientRelationLabel이 무척 즐거워하셨다.',
    );
    addMemory(
      date: d(0, 11),
      title: '옛 동네 방문',
      content: '예전에 살던 동네를 차로 둘러보았다. 기억이 조금씩 나시는 듯했다.',
      mediaList: [
        Media(id: 0, memoryId: null, diaryId: null, fileUrl: 'dummy.jpg', fileType: 'image', duration: 0, sortOrder: 1, createdAt: DateTime.now())
      ],
    );
    addMemory(
      date: d(0, 18),
      title: '좋아하시는 노래',
      content: '라디오에서 옛날 노래가 나오자 따라 부르셨다.',
    );
    addMemory(
      date: d(0, 22),
      title: '손주와의 영상통화',
      content: '손주와 영상통화를 하며 활짝 웃으시는 모습을 보니 내 마음도 따뜻해졌다.',
      mediaList: [
        Media(id: 0, memoryId: null, diaryId: null, fileUrl: 'dummy.jpg', fileType: 'image', duration: 0, sortOrder: 1, createdAt: DateTime.now())
      ],
    );

    addDiary(date: d(0, 2), content: '오늘은 정말 화가 나고 짜증나는 하루였다. 너무 답답하다.', emotion: EmotionValues.anger);
    addDiary(date: d(0, 5), content: '내일 있을 일이 자꾸 걱정되고 불안해서 초조하다.', emotion: EmotionValues.anxiety);
    addDiary(date: d(0, 8), content: '문득 옛날 생각이 나서 너무 외롭고 슬프고 눈물이 났다.', emotion: EmotionValues.sadness);
    addDiary(date: d(0, 11), content: '내가 잘못한 것 같아 너무 미안하고 죄책감이 든다.', emotion: EmotionValues.guilt);
    addDiary(date: d(0, 14), content: '오늘 나를 도와준 친구에게 정말 고맙고 감사하다. 다행이다.', emotion: EmotionValues.gratitude);
    addDiary(date: d(0, 17), content: '가족들과 함께 시간을 보내며 깊은 애정과 사랑을 느꼈다.', emotion: EmotionValues.affection);
  }
}
