import 'dart:convert';
import 'dart:io';

import '../models/media.dart';
import 'api_service.dart';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class DiaryException implements Exception {
  const DiaryException(this.message);

  final String message;
}

class DiaryDraft {
  const DiaryDraft({required this.id, required this.aiQuestion});

  final int id;
  final String aiQuestion;
}

class EmotionTagOption {
  const EmotionTagOption({
    required this.id,
    required this.name,
    required this.emotionName,
    this.emotionId,
  });

  final int id;
  final String name;
  final String emotionName;
  final int? emotionId;
}

class DiaryFinalization {
  const DiaryFinalization({
    required this.emotionId,
    required this.emotionName,
    required this.flowerName,
    required this.flowerSentence,
  });

  final int? emotionId;
  final String emotionName;
  final String flowerName;
  final String flowerSentence;
}

/// Calendar-only projection of a finalized diary.
///
/// A diary is shown on the calendar on the day its final emotion was decided,
/// rather than on the day its draft was first created.
class CalendarDiaryEntry {
  const CalendarDiaryEntry({
    required this.id,
    required this.emotionId,
    required this.emotionName,
    required this.finalizedAt,
  });

  final int id;
  final int? emotionId;
  final String emotionName;
  final DateTime finalizedAt;

  static CalendarDiaryEntry? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) return null;
    if (json['status'] != 'completed') return null;

    final emotion = json['final_emotion'] ?? json['emotion'];
    final emotionMap = emotion is Map<String, dynamic>
        ? emotion
        : const <String, dynamic>{};
    if (emotionMap.isEmpty && json['final_emotion_id'] is! int) return null;

    final timestamp =
        json['finalized_at'] ??
        json['emotion_finalized_at'] ??
        json['emotion_created_at'] ??
        emotionMap['created_at'] ??
        json['updated_at'];
    final finalizedAt = timestamp is String
        ? DateTime.tryParse(timestamp)
        : null;
    if (finalizedAt == null) return null;

    return CalendarDiaryEntry(
      id: id,
      emotionId: (emotionMap['id'] ?? json['final_emotion_id']) as int?,
      emotionName: (emotionMap['display_name'] ?? emotionMap['emotion'] ?? '')
          .toString(),
      finalizedAt: finalizedAt.toLocal(),
    );
  }
}

class DiaryService {
  DiaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  int? _pendingDraftId;
  String? _pendingKey;
  final Set<String> _uploadedAttachments = {};

  void close() => _client.close();

  /// The list endpoint accepts group and pagination filters. Date filtering is
  /// performed locally using finalized_at, since the server has no date filter.
  Future<List<CalendarDiaryEntry>> fetchFinalizedForMonth({
    required AuthTokens tokens,
    required DateTime month,
    int? groupId,
  }) async {
    final result = <CalendarDiaryEntry>[];
    for (var page = 1; ; page++) {
      final query = Uri(
        queryParameters: {
          'page': '$page',
          'size': '100',
          if (groupId != null) 'group_id': '$groupId',
        },
      ).query;
      final response = await _get('/diaries?$query', tokens);
      if (response is! List) {
        throw const DiaryException('일기 목록 응답 형식이 올바르지 않습니다.');
      }
      for (final row in response.cast<Map<String, dynamic>>()) {
        final entry = CalendarDiaryEntry.fromJson(row);
        if (entry != null &&
            entry.finalizedAt.year == month.year &&
            entry.finalizedAt.month == month.month) {
          result.add(entry);
        }
      }
      if (response.length < 100) return result;
    }
  }

  Future<DiaryDraft> createDraftAndQuestion({
    required AuthTokens tokens,
    required String situationText,
    String? title,
    required DateTime recordDate,
    int? groupId,
    List<Media> mediaList = const [],
  }) async {
    if (groupId == null) {
      final response = await _get('/groups', tokens);
      final groups = response is List
          ? response
          : response is Map<String, dynamic>
          ? (response['groups'] ?? response['items'] ?? response['data'])
          : null;
      if (groups is! List || groups.isEmpty) {
        throw const DiaryException('일기를 작성하려면 먼저 가족 그룹에 참여해주세요.');
      }
      groupId = (groups.first as Map<String, dynamic>)['id'] as int;
    }
    final key = jsonEncode([
      tokens.accessToken,
      groupId,
      title,
      situationText,
      recordDate.toIso8601String(),
    ]);
    if (_pendingKey != key) {
      _pendingDraftId = null;
      _uploadedAttachments.clear();
      _pendingKey = key;
    }
    if (_pendingDraftId == null) {
      final created = await _post('/diaries', tokens, {
        'group_id': groupId,
        'situation_text': situationText,
        if (title != null && title.isNotEmpty) 'title': title,
        'record_date': recordDate.toIso8601String(),
      });
      final id = created['id'] ?? created['diary_id'];
      if (id is! int) throw const DiaryException('일기 저장 응답 형식이 올바르지 않습니다.');
      _pendingDraftId = id;
    }
    final diaryId = _pendingDraftId!;
    for (final media in mediaList) {
      final attachmentKey = '${media.fileUrl}:${media.sortOrder}';
      if (_uploadedAttachments.contains(attachmentKey)) continue;
      try {
        final extension = media.fileUrl.split('.').last.toLowerCase();
        final mimeType = const {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'heic': 'image/heic',
          'webp': 'image/webp',
          'gif': 'image/gif',
          'mp4': 'video/mp4',
          'mov': 'video/quicktime',
          'm4v': 'video/x-m4v',
          'mp3': 'audio/mpeg',
          'm4a': 'audio/mp4',
          'wav': 'audio/wav',
          'aac': 'audio/aac',
          'ogg': 'audio/ogg',
          'flac': 'audio/flac',
        }[extension];
        if (mimeType == null) {
          throw const DiaryException('지원하지 않는 첨부 파일 형식입니다.');
        }
        final file = File(media.fileUrl);
        if (await file.length() > 50 * 1024 * 1024) {
          throw const DiaryException('첨부 파일은 50MB 이하로 선택해주세요.');
        }
        await MediaApi(ApiService(client: _client)).uploadDiary(
          tokens,
          diaryId,
          bytes: await file.readAsBytes(),
          filename: file.uri.pathSegments.last,
          contentType: mimeType,
          duration: media.duration,
          sortOrder: media.sortOrder,
        );
        _uploadedAttachments.add(attachmentKey);
      } on ApiException catch (error) {
        throw DiaryException(error.message);
      } on FileSystemException {
        throw const DiaryException('첨부 파일을 읽을 수 없습니다. 파일을 다시 선택해주세요.');
      }
    }

    final question = await _post(
      '/diaries/$diaryId/ai-question',
      tokens,
      null,
      timeout: const Duration(seconds: 75),
    );
    final text =
        question['ai_question_text'] ??
        question['aiQuestionText'] ??
        question['ai_question'] ??
        question['question'];
    if (text is! String || text.isEmpty) {
      throw const DiaryException('AI 질문을 생성하지 못했습니다.');
    }
    return DiaryDraft(id: diaryId, aiQuestion: text);
  }

  Future<List<EmotionTagOption>> saveAnswerAndGetSuggestions({
    required AuthTokens tokens,
    required int diaryId,
    required String answer,
  }) async {
    await _patch('/diaries/$diaryId/answer', tokens, {
      'question_answer_text': answer,
    });
    final response = await _get(
      '/diaries/$diaryId/emotion-tag-suggestions',
      tokens,
    );
    final rawSuggestions = response is List
        ? response
        : response is Map<String, dynamic>
        ? (response['suggestions'] ?? response['items'] ?? response['data'])
        : null;
    if (rawSuggestions is! List) {
      throw const DiaryException('감정 태그 추천 응답 형식이 올바르지 않습니다.');
    }

    final tags = <EmotionTagOption>[];
    for (final item in rawSuggestions.whereType<Map<String, dynamic>>()) {
      final emotionName = (item['display_name'] ?? item['emotion'] ?? '감정')
          .toString();
      final rawTags = item['tags'];
      if (rawTags is! List) continue;
      for (final tag in rawTags.whereType<Map<String, dynamic>>()) {
        final id = tag['id'];
        final name = tag['tag_name'];
        if (id is int && name is String) {
          tags.add(
            EmotionTagOption(
              id: id,
              name: name,
              emotionName: emotionName,
              emotionId: item['emotion_id'] as int?,
            ),
          );
        }
      }
    }
    if (tags.length < 3) {
      throw const DiaryException('선택할 감정 태그가 충분하지 않습니다.');
    }
    return tags;
  }

  Future<DiaryFinalization> saveTagsAndFinalize({
    required AuthTokens tokens,
    required int diaryId,
    required List<int> tagIds,
  }) async {
    if (tagIds.length != 3 || tagIds.toSet().length != 3) {
      throw const DiaryException('감정 태그를 정확히 3개 선택해주세요.');
    }
    final result = await _post('/diaries/$diaryId/finalize', tokens, {
      'emotion_tag_ids': tagIds,
    });
    final emotion = result['emotion'];
    final flower = result['flower'];
    final emotionMap = emotion is Map<String, dynamic>
        ? emotion
        : const <String, dynamic>{};
    final flowerMap = flower is Map<String, dynamic>
        ? flower
        : const <String, dynamic>{};
    return DiaryFinalization(
      emotionId: (emotionMap['id'] ?? result['final_emotion_id']) as int?,
      emotionName:
          (emotionMap['display_name'] ?? emotionMap['emotion'] ?? '오늘의 감정')
              .toString(),
      flowerName: (flowerMap['flower_name'] ?? '마음의 꽃').toString(),
      flowerSentence: (flowerMap['sentence'] ?? '').toString(),
    );
  }

  Future<dynamic> _get(String path, AuthTokens tokens) async {
    final response = await _send(
      () => _client.get(_uri(path), headers: _headers(tokens)),
    );
    return _bodyOrThrow(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    AuthTokens tokens,
    Map<String, dynamic>? body, {
    Duration timeout = const Duration(seconds: 20),
  }) => _write(
    () => _client.post(
      _uri(path),
      headers: _headers(tokens),
      body: body == null ? null : jsonEncode(body),
    ),
    timeout: timeout,
  );

  Future<Map<String, dynamic>> _patch(
    String path,
    AuthTokens tokens,
    Map<String, dynamic> body,
  ) => _write(
    () => _client.patch(
      _uri(path),
      headers: _headers(tokens),
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> _write(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final response = await _send(request, timeout: timeout);
    final body = _bodyOrThrow(response);
    if (body is! Map<String, dynamic>) {
      throw const DiaryException('서버 응답 형식이 올바르지 않습니다.');
    }
    return body;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await request().timeout(timeout);
    } on Exception {
      throw const DiaryException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
    }
  }

  dynamic _bodyOrThrow(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = const <String, dynamic>{};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401) {
      throw const DiaryException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }
    final detail = body is Map<String, dynamic> ? body['detail'] : null;
    if (detail is String && detail.isNotEmpty) {
      throw DiaryException(detail);
    }
    if (response.statusCode == 422) {
      throw const DiaryException('입력한 내용을 다시 확인해주세요.');
    }
    throw const DiaryException('일기 처리에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers(AuthTokens tokens) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${tokens.accessToken}',
  };
}
