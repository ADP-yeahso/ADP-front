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
    bool hasPhoto = false,
    bool isPublic = true,
  }) {
    List<Media> media = [];
    if (hasPhoto) {
      media.add(
        Media(
          id: _nextId(),
          memoryId: _idCounter,
          diaryId: null,
          fileUrl: 'dummy.jpg',
          fileType: 'image',
          duration: 0,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      );
    }
    memories.add(
      Memory(
        id: _nextId(),
        patientId: 1,
        userId: me.id,
        contextText: content,
        mediaList: media,
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

    final entry = Diary(
      id: _nextId(),
      userId: me.id,
      context: content,
      flowerType: flower,
      mediaList: [],
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
      hasPhoto: true,
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
      hasPhoto: true,
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
  }
}
