import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../models/emotions.dart';
import '../models/flower.dart';
import '../models/groups.dart';
import '../models/media.dart';
import '../models/memory.dart';
import '../models/patients.dart';
import '../models/users.dart';
import '../models/users_groups.dart';
import 'emotion_analyzer.dart';

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;
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

  /// 현재 로그인한 유저 ID (데모: 실서버 연결 시 교체)
  final int currentUserId = 1;

  // ── 새 모델 더미 데이터 ─────────────────────────────
  Patient _patient = Patient(
    id: 1,
    groupId: 1,
    patientName: '고강민',
    patientBirthDate: 20060515,
    createdAt: DateTime(2024, 1, 1),
  );

  Patient get patient => _patient;

  final Group group = Group(
    id: 1,
    inviteCode: 'ABCD12',
    groupName: '고강민 가족',
    members: 3,
    createdAt: DateTime(2024, 1, 1),
  );

  final List<UserGroup> userGroups = [
    UserGroup(
      id: 1,
      userId: 1,
      groupId: 1,
      patientsNickname: '아버지',
      joinedAt: DateTime(2024, 1, 1),
    ),
    UserGroup(
      id: 2,
      userId: 2,
      groupId: 1,
      patientsNickname: '아버지',
      joinedAt: DateTime(2024, 1, 1),
    ),
    UserGroup(
      id: 3,
      userId: 3,
      groupId: 1,
      patientsNickname: '시아버지',
      joinedAt: DateTime(2024, 1, 1),
    ),
  ];

  /// 현재 유저가 환자를 부르는 호칭 (UserGroup.patientsNickname 기반)
  String get patientRelationLabel {
    try {
      return userGroups
          .firstWhere((ug) => ug.userId == currentUserId)
          .patientsNickname;
    } catch (_) {
      return '환자';
    }
  }

  /// userId가 현재 로그인 유저인지 확인
  bool isCurrentUser(int userId) => userId == currentUserId;

  /// userId에 해당하는 구성원이 환자를 부르는 호칭
  String userRelationOf(int userId) {
    try {
      return userGroups
          .firstWhere((ug) => ug.userId == userId)
          .patientsNickname;
    } catch (_) {
      return '';
    }
  }

  final List<User> users = [
    User(
      id: 1,
      email: 'me@example.com',
      password: '',
      name: '강성윤',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
    User(
      id: 2,
      email: 'son@example.com',
      password: '',
      name: '강지민',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
    User(
      id: 3,
      email: 'inlaw@example.com',
      password: '',
      name: '정인선',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    ),
  ];

  User get me => users.firstWhere((u) => u.id == currentUserId);

  User userById(int id) =>
      users.firstWhere((u) => u.id == id, orElse: () => me);

  void updateCurrentUserProfile({
    required String name,
    required String password,
    required String phoneNumber,
  }) {
    final index = users.indexWhere((user) => user.id == currentUserId);

    if (index == -1) {
      return;
    }

    final currentUser = users[index];

    users[index] = User(
      id: currentUser.id,
      email: currentUser.email,
      password: password,
      name: name,
      phoneNumber: phoneNumber,
      profileImageUrl: currentUser.profileImageUrl,
      createdAt: currentUser.createdAt,
    );

    notifyListeners();
  }

  void updatePatientInfo({
    required String patientName,
    required int patientBirthDate,
    required String patientsNickname,
  }) {
    _patient = Patient(
      id: _patient.id,
      groupId: _patient.groupId,
      patientName: patientName,
      patientBirthDate: patientBirthDate,
      createdAt: _patient.createdAt,
    );

    final relationIndex = userGroups.indexWhere(
      (userGroup) =>
          userGroup.userId == currentUserId &&
          userGroup.groupId == _patient.groupId,
    );

    if (relationIndex != -1) {
      final currentRelation = userGroups[relationIndex];

      userGroups[relationIndex] = UserGroup(
        id: currentRelation.id,
        userId: currentRelation.userId,
        groupId: currentRelation.groupId,
        patientsNickname: patientsNickname,
        joinedAt: currentRelation.joinedAt,
      );
    }

    notifyListeners();
  }

  String get patientBirthDateLabel {
    final value = patient.patientBirthDate.toString().padLeft(8, '0');

    final year = value.substring(0, 4);
    final month = value.substring(4, 6);
    final day = value.substring(6, 8);

    return '$year.$month.$day';
  }

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

    final updatedMedia = mediaList
        .map(
          (m) => Media(
            id: m.id,
            memoryId: memoryId,
            diaryId: null,
            fileUrl: m.fileUrl,
            fileType: m.fileType,
            duration: m.duration,
            thumbnailPath: m.thumbnailPath,
            sortOrder: m.sortOrder,
            createdAt: m.createdAt,
          ),
        )
        .toList();

    memories.add(
      Memory(
        id: memoryId,
        patientId: 1,
        userId: me.id,
        contextText: content,
        mediaList: updatedMedia,
        isPublic: isPublic,
        recordDate: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
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
        .map(
          (m) => Media(
            id: m.id,
            memoryId: null,
            diaryId: diaryId,
            fileUrl: m.fileUrl,
            fileType: m.fileType,
            duration: m.duration,
            thumbnailPath: m.thumbnailPath,
            sortOrder: m.sortOrder,
            createdAt: m.createdAt,
          ),
        )
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

  void _seedEmotionAnalysisTestData() {
    final today = DateTime.now();

    DateTime daysAgo(int days) {
      final date = today.subtract(Duration(days: days));

      return DateTime(date.year, date.month, date.day);
    }

    DateTime monthsAgo(int months, int day) {
      final firstDay = DateTime(today.year, today.month - months, 1);

      final lastDay = DateTime(firstDay.year, firstDay.month + 1, 0).day;

      final safeDay = day > lastDay ? lastDay : day;

      return DateTime(firstDay.year, firstDay.month, safeDay);
    }

    // ── 최근 1주 테스트 데이터 ──────────────────────

    addDiary(
      date: daysAgo(0),
      content: '오늘은 마음이 편안하고 괜찮았다. 잠시 쉴 수 있어서 다행이었다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(1),
      content: '계속 같은 설명을 반복해야 해서 답답하고 짜증이 났다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(2),
      content: '오늘은 많이 지치고 속상해서 눈물이 날 것 같았다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(3),
      content: '오늘은 불안하고 걱정되고 초조했다. 마음이 놓이지 않았다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(4),
      content: '어제 화를 낸 것이 미안하고 계속 후회가 된다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(5),
      content: '오늘은 환하게 웃으셔서 기쁘고 행복했다.',
      isPublic: false,
    );

    addDiary(
      date: daysAgo(6),
      content: '오늘 하루는 비교적 차분하고 평온하게 지나갔다.',
      isPublic: false,
    );

    // ── 지난달 테스트 데이터 ────────────────────────

    addDiary(
      date: monthsAgo(1, 3),
      content: '병원에 다녀온 뒤 많이 지치고 힘들었다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(1, 9),
      content: '내가 조금 더 잘했어야 했다는 생각에 미안하고 후회됐다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(1, 15),
      content: '오랜만에 함께 웃어서 고맙고 행복한 하루였다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(1, 21),
      content: '같은 질문이 반복되어 답답하고 짜증이 났다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(1, 27),
      content: '오늘은 별일 없이 편안하고 괜찮았다.',
      isPublic: false,
    );

    // ── 최근 6개월 테스트 데이터 ────────────────────

    addDiary(
      date: monthsAgo(2, 8),
      content: '오늘은 속상하고 외로운 마음이 크게 느껴졌다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(2, 20),
      content: '잠시 웃어 주셔서 기쁘고 감사했다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(3, 6),
      content: '돌봄이 뜻대로 되지 않아 답답하고 화가 났다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(3, 18),
      content: '오늘은 마음이 차분하고 평온했다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(4, 10),
      content: '내가 짜증을 낸 것 같아 미안하고 자책했다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(4, 23),
      content: '가족과 함께해서 고맙고 행복한 시간이었다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(5, 7),
      content: '너무 지치고 힘들어서 눈물이 났다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(5, 19),
      content: '오늘은 비교적 편안하고 괜찮은 하루였다.',
      isPublic: false,
    );

    // ── 1년 그래프 테스트용 데이터 ─────────────────

    addDiary(
      date: monthsAgo(6, 12),
      content: '오랜만에 웃는 모습을 보니 기쁘고 고마웠다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(7, 14),
      content: '계속 반복되는 상황이 답답하고 짜증이 났다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(8, 16),
      content: '오늘은 많이 지치고 외롭고 슬펐다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(9, 18),
      content: '내가 잘못한 것 같아 미안하고 후회가 됐다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(10, 20),
      content: '평온하고 차분하게 하루를 마무리했다.',
      isPublic: false,
    );

    addDiary(
      date: monthsAgo(11, 22),
      content: '함께 웃을 수 있어서 기쁘고 행복했다.',
      isPublic: false,
    );
  }

  void _seed() {
    final today = DateTime.now();
    DateTime d(int monthsAgo, int day) =>
        DateTime(today.year, today.month - monthsAgo, day);

    addMemory(
      date: d(2, 6),
      title: '함께 본 옛날 사진',
      content: '$patientRelationLabel과 함께 젊은 시절 사진을 꺼내 보았다. 잠시 웃으셨다.',
      mediaList: [],
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
      mediaList: [],
    );

    addDiary(date: d(2, 8), content: '오늘은 유난히 지치고 눈물이 났다. 혼자 감당하기 힘든 하루였다.');
    addDiary(
      date: d(1, 15),
      content: '$patientRelationLabel이 나를 못 알아봐서 속상하고 화가 났다.',
    );
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
    _seedEmotionAnalysisTestData();
  }
}
