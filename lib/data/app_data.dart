import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/emotion_utils.dart';
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
import '../services/api_service.dart';
import '../services/auth_service.dart';

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

extension UserUIInfo on User {
  String get nickname => name;
  Color get color => const [
    Color(0xFF6B93D1),
    Color(0xFF6FBF8B),
    Color(0xFF9B7FC7),
  ][id.codeUnits.fold<int>(0, (sum, value) => sum + value) % 3];
}

class AppData extends ChangeNotifier {
  AppData({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  AuthTokens? _tokens;
  int _generation = 0;
  int _recordsRequest = 0;
  String currentUserId = '';
  String? loadError;
  bool isLoading = false;
  bool get hasPatient => _patient.id > 0;
  final Map<int, Map<String, dynamic>> _createdPatients = {};

  Patient _patient = Patient(
    id: 0,
    groupId: 0,
    patientName: '',
    patientBirthDate: 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
  Patient get patient => _patient;
  Group group = Group(
    id: 0,
    inviteCode: '',
    groupName: '',
    members: 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
  final List<UserGroup> userGroups = [];
  final List<User> users = [];
  List<Group> _joinedGroups = const [];

  List<Group> get joinedGroups => _joinedGroups;

  void updateJoinedGroups(List<Group> groups) {
    _joinedGroups = List.unmodifiable(groups);
    notifyListeners();
  }

  Future<void> refreshJoinedGroups(AuthTokens tokens) async {
    final generation = _generation;
    final rows = await GroupApi(_api).list(tokens);
    if (generation != _generation) return;
    updateJoinedGroups(
      rows
          .map(
            (row) => Group(
              id: row['id'] as int,
              groupName: (row['group_name'] ?? row['name'] ?? '가족 그룹')
                  .toString(),
              inviteCode: (row['invite_code'] ?? '').toString(),
              groupProfileImageUrl: row['group_profile_image_url'] as String?,
              members: row['member_count'] as int? ?? 0,
              createdAt: _time(row['created_at']),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> patientDetails = {};
  bool patientLookupAvailable = false;

  String get patientRelationLabel => userRelationOf(currentUserId).isEmpty
      ? '환자'
      : userRelationOf(currentUserId);

  bool isCurrentUser(String userId) => userId == currentUserId;

  String userRelationOf(String userId) {
    for (final membership in userGroups) {
      if (membership.userId == userId) return membership.patientsNickname;
    }
    return '';
  }

  void clear() {
    _generation++;
    _tokens = null;
    currentUserId = '';
    users.clear();
    _joinedGroups = const [];
    userGroups.clear();
    memories.clear();
    diaries.clear();
    comments.clear();
    _publicDiaryIds.clear();
    _createdPatients.clear();
    patientDetails = {};
    patientLookupAvailable = false;
    _patient = Patient(
      id: 0,
      groupId: 0,
      patientName: '',
      patientBirthDate: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    group = Group(
      id: 0,
      inviteCode: '',
      groupName: '',
      members: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    loadError = null;
    isLoading = false;
    notifyListeners();
  }

  void rememberPatient(int groupId, Map<String, dynamic> patient) {
    _createdPatients[groupId] = patient;
    if (group.id == groupId) {
      _setPatient(patient);
      notifyListeners();
    }
  }

  Future<void> openGroup(AuthTokens tokens, int groupId) async {
    final generation = ++_generation;
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final profile = await UserApi(_api).profile(tokens);
      final detail = await GroupApi(_api).detail(tokens, groupId);
      if (generation != _generation) return;
      _tokens = tokens;
      currentUserId = profile['id'] as String;
      users
        ..clear()
        ..add(_user(profile));
      userGroups.clear();
      memories.clear();
      diaries.clear();
      comments.clear();
      _publicDiaryIds.clear();
      group = Group(
        id: groupId,
        inviteCode: detail['invite_code'] as String,
        groupName: detail['group_name'] as String,
        groupProfileImageUrl: detail['group_profile_image_url'] as String?,
        members: detail['member_count'] as int,
        createdAt: _time(detail['created_at']),
      );
      for (final member
          in (detail['members'] as List).cast<Map<String, dynamic>>()) {
        final id = member['user_id'] as String;
        if (id != currentUserId) users.add(_user({...member, 'id': id}));
        userGroups.add(
          UserGroup(
            id: userGroups.length,
            userId: id,
            groupId: groupId,
            patientsNickname: (member['patients_nickname'] ?? '환자').toString(),
            joinedAt: _time(member['joined_at']),
          ),
        );
      }
      patientLookupAvailable = detail.containsKey('patient');
      final rawPatient = patientLookupAvailable
          ? detail['patient']
          : _createdPatients[groupId];
      _setPatient(rawPatient is Map<String, dynamic> ? rawPatient : {});
      notifyListeners();
      await refreshRecords();
    } finally {
      if (generation == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void _setPatient(Map<String, dynamic> value) {
    patientDetails = value;
    final birth = DateTime.tryParse('${value['patient_birth_date']}');
    _patient = Patient(
      id: value['id'] as int? ?? 0,
      groupId: group.id,
      patientName: (value['patient_name'] ?? '').toString(),
      patientBirthDate: birth == null
          ? 0
          : birth.year * 10000 + birth.month * 100 + birth.day,
      createdAt: _time(value['created_at']),
    );
  }

  Future<void> refreshGroup() async {
    final tokens = _tokens;
    if (tokens == null) return;
    try {
      await openGroup(tokens, group.id);
    } on ApiException catch (error) {
      loadError = error.message;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _allPages(
    String path,
    AuthTokens tokens,
  ) async {
    final entries = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      final value = await _api.get(
        '$path${path.contains('?') ? '&' : '?'}page=$page&size=100',
        tokens,
      );
      if (value is! List) throw const ApiException('기록 목록 응답 형식이 올바르지 않습니다.');
      entries.addAll(value.cast<Map<String, dynamic>>());
      if (value.length < 100) return entries;
    }
  }

  Future<Map<String, dynamic>> _diaryDetail(int id, AuthTokens tokens) async {
    final value =
        await _api.get('/diaries/$id', tokens) as Map<String, dynamic>;
    if ((value['media'] as List? ?? []).isNotEmpty) {
      value['media'] = await _api.get('/diaries/$id/media', tokens);
    }
    return value;
  }

  Future<void> refreshRecords() async {
    final tokens = _tokens;
    if (tokens == null) return;
    final generation = _generation;
    final request = ++_recordsRequest;
    try {
      final memoryRows = hasPatient
          ? await _allPages('/patients/${patient.id}/memory-records', tokens)
          : <Map<String, dynamic>>[];
      final diaryRows = await _allPages(
        '/diaries?group_id=${group.id}',
        tokens,
      );
      final details = <Map<String, dynamic>>[];
      for (final row in diaryRows) {
        if (row['final_emotion_id'] == null ||
            (row['status'] != 'completed' &&
                row['correct_emotion_id'] is! int) ||
            row['deleted_at'] != null) {
          continue;
        }
        final detail = {
          ...row,
          ...await _diaryDetail(row['id'] as int, tokens),
        };
        if (Diary.hasSavedEmotion(detail)) details.add(detail);
      }
      if (generation != _generation || request != _recordsRequest) return;
      final loadedMemories = memoryRows.map(_memory).toList();
      final loadedDiaries = details.map(_diary).toList();
      memories
        ..clear()
        ..addAll(loadedMemories);
      diaries
        ..clear()
        ..addAll(loadedDiaries);
      _publicDiaryIds.clear();
      loadError = null;
    } on ApiException catch (error) {
      if (generation != _generation) return;
      loadError = error.message;
    }
    if (generation == _generation) notifyListeners();
  }

  Future<void> refreshDiary(int id) async {
    final tokens = _tokens;
    if (tokens == null) return;
    final generation = _generation;
    _recordsRequest++;
    try {
      final value = await _diaryDetail(id, tokens);
      if (generation != _generation) return;
      diaries.removeWhere((item) => item.id == id);
      if (Diary.hasSavedEmotion(value)) diaries.add(_diary(value));
    } on ApiException catch (error) {
      if (generation != _generation) return;
      loadError = error.message;
    }
    notifyListeners();
  }

  void cacheMemory(Map<String, dynamic> value) {
    _recordsRequest++;
    final memory = _memory(value);
    memories.removeWhere((item) => item.id == memory.id);
    memories.add(memory);
    notifyListeners();
  }

  Future<bool> createMemory(Map<String, dynamic> body) async {
    final tokens = _requireTokens();
    if (!hasPatient) throw const ApiException('환자 정보를 먼저 불러와주세요.');
    final generation = _generation;
    _recordsRequest++;
    final value = await MemoryRecordApi(_api).create(tokens, patient.id, body);
    if (generation != _generation) return false;
    cacheMemory(value);
    return true;
  }

  User _user(Map<String, dynamic> value) => User(
    id: value['id'] as String,
    email: (value['email'] ?? '').toString(),
    password: '',
    name: (value['name'] ?? '가족').toString(),
    phoneNumber: (value['phone_number'] ?? '').toString(),
    profileImageUrl: value['profile_image_url'] as String?,
    createdAt: _time(value['created_at']),
  );

  List<Media> _media(dynamic value) => value is List
      ? value
            .cast<Map<String, dynamic>>()
            .map(
              (item) => Media(
                id: item['id'] as int,
                memoryId: item['memory_record_id'] as int?,
                diaryId: item['diary_id'] as int?,
                fileUrl: (item['download_url'] ?? item['file_url']) as String,
                fileType: item['file_type'] as String,
                duration: item['duration'] as int?,
                sortOrder: item['sort_order'] as int? ?? 0,
                createdAt: _time(item['created_at']),
              ),
            )
            .toList()
      : [];

  Memory _memory(Map<String, dynamic> value) => Memory(
    id: value['id'] as int,
    patientId: value['patient_id'] as int,
    userId: value['user_id'] as String,
    title: value['title'] as String?,
    contextText: value['context'] as String?,
    mediaList: _media(value['media']),
    isPublic: true,
    recordDate: _time(value['record_date']),
    createdAt: _time(value['created_at']),
    updatedAt: _time(value['updated_at'] ?? value['created_at']),
  );

  Diary _diary(Map<String, dynamic> value) {
    final emotion = value['emotion'] as Map<String, dynamic>? ?? {};
    final flower = value['flower'] as Map<String, dynamic>? ?? {};
    final emotionId =
        value['final_emotion_id'] as int? ?? emotion['id'] as int? ?? 0;
    final fallback = EmotionValues.values.firstWhere(
      (item) => item.id == emotionId,
      orElse: () => EmotionValues.neutral,
    );
    final matchesFinalEmotion = emotion['id'] == emotionId;
    return Diary(
      id: value['id'] as int,
      userId: value['user_id'] as String,
      title: value['title'] as String?,
      context: (value['situation_text'] ?? '').toString(),
      flowerType: Flower(
        id: flower['id'] as int? ?? 0,
        emotionId: Emotion(
          id: emotionId,
          name: matchesFinalEmotion
              ? (emotion['emotion'] ?? fallback.name).toString()
              : fallback.name,
          displayName: matchesFinalEmotion
              ? (emotion['display_name'] ?? fallback.displayName).toString()
              : fallback.displayName,
        ),
        flowerName: (flower['flower_name'] ?? '').toString(),
        colorCode: '',
        sentence: (flower['sentence'] ?? '').toString(),
      ),
      mediaList: _media(value['media']),
      recordDate: _time(
        value['finalized_at'] ??
            (value['status'] == 'draft' ? value['updated_at'] : null) ??
            value['record_date'],
      ),
      createdAt: _time(value['created_at']),
      updatedAt: _time(value['updated_at']),
      isFinalized: value['status'] == 'completed',
    );
  }

  DateTime _time(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _generation++;
    _api.close();
    super.dispose();
  }

  User get me => users.firstWhere(
    (user) => user.id == currentUserId,
    orElse: () => User(
      id: currentUserId,
      email: '',
      password: '',
      name: '',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );

  User userById(String id) => users.firstWhere(
    (user) => user.id == id,
    orElse: () => User(
      id: id,
      email: '',
      password: '',
      name: '가족',
      phoneNumber: '',
      profileImageUrl: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );

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
    if (!hasPatient || patient.patientBirthDate == 0) return '등록된 환자 없음';
    final value = patient.patientBirthDate.toString().padLeft(8, '0');

    final year = value.substring(0, 4);
    final month = value.substring(4, 6);
    final day = value.substring(6, 8);

    return '$year.$month.$day';
  }

  final List<Memory> memories = [];
  final List<Diary> diaries = [];
  final List<Comment> comments = [];

  List<Comment> commentsForMemory(int memoryRecordId) {
    return comments
        .where((c) => c.memoryRecordId == memoryRecordId && c.deletedAt == null)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void addMemoryComment({
    required int memoryRecordId,
    required String commentText,
    String? userId,
  }) {
    final text = commentText.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    comments.add(
      Comment(
        id: _nextId(),
        memoryRecordId: memoryRecordId,
        userId: userId ?? currentUserId,
        commentText: text,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
  }

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
        patientId: patient.id,
        userId: me.id,
        title: title,
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
    String? title,
    Emotion? emotion,
    List<Media> mediaList = const [],
    bool isPublic = true,
  }) {
    final analysis = analyzeEmotion(content);
    final finalEmotion = emotion ?? analysis.primary;

    final flower = Flower(
      id: finalEmotion.id,
      emotionId: finalEmotion,
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
      title: title,
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
        title: old.title,
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

  Future<bool> updateMemoryText(int id, String? title, String content) async {
    if (content.trim().isEmpty) return false;
    if (!memories.any((m) => m.id == id)) return false;
    final tokens = _requireTokens();
    final generation = _generation;
    _recordsRequest++;
    final value = await MemoryRecordApi(
      _api,
    ).update(tokens, id, {'title': title, 'context': content.trim()});
    if (generation != _generation) return false;
    cacheMemory(value);
    return true;
  }

  Future<bool> updateDiaryText(int id, String? title, String content) async {
    if (content.trim().isEmpty) return false;
    if (!diaries.any((d) => d.id == id)) return false;
    final tokens = _requireTokens();
    final generation = _generation;
    _recordsRequest++;
    final value =
        await _api.patch('/diaries/$id', tokens, {
              'title': title,
              'situation_text': content.trim(),
            })
            as Map<String, dynamic>;
    if (generation != _generation) return false;
    final index = diaries.indexWhere((d) => d.id == id);
    if (index == -1) return false;
    final old = diaries[index];
    _recordsRequest++;
    if (value['status'] != 'completed' && value['correct_emotion_id'] == null) {
      diaries.removeAt(index);
      notifyListeners();
      return true;
    }
    diaries[index] = Diary(
      id: old.id,
      userId: old.userId,
      title: value['title'] as String?,
      context: value['situation_text'] as String,
      flowerType: old.flowerType,
      mediaList: old.mediaList,
      recordDate: old.recordDate,
      createdAt: old.createdAt,
      updatedAt: _time(value['updated_at']),
      deletedAt: old.deletedAt,
      isFinalized: old.isFinalized,
    );
    notifyListeners();
    return true;
  }

  AuthTokens _requireTokens() =>
      _tokens ?? (throw const ApiException('로그인 후 기록을 변경할 수 있어요.'));

  Future<bool> deleteMemory(int id) async {
    if (!memories.any((m) => m.id == id)) return false;
    final tokens = _requireTokens();
    final generation = _generation;
    _recordsRequest++;
    await MemoryRecordApi(_api).remove(tokens, id);
    if (generation != _generation) return false;
    _recordsRequest++;
    memories.removeWhere((m) => m.id == id);
    comments.removeWhere((c) => c.memoryRecordId == id);
    notifyListeners();
    return true;
  }

  Future<bool> deleteDiary(int id) async {
    if (!diaries.any((d) => d.id == id)) return false;
    final tokens = _requireTokens();
    final generation = _generation;
    _recordsRequest++;
    await _api.delete('/diaries/$id', tokens);
    if (generation != _generation) return false;
    _recordsRequest++;
    diaries.removeWhere((d) => d.id == id);
    _publicDiaryIds.remove(id);
    notifyListeners();
    return true;
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

  Emotion? latestEmotionFor(String userId) {
    final entries = diaries.where((d) => d.userId == userId).toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
    if (entries.isEmpty) return null;
    return entries.first.flowerType.emotionId;
  }
}
