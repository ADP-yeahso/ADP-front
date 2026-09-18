import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class DiaryException implements Exception {
  const DiaryException(this.message);
  final String message;

  @override
  String toString() => message;
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
  });
  final int id;
  final String name;
  final String emotionName;
}

class DiaryFinalization {
  const DiaryFinalization({
    required this.emotionName,
    required this.flowerName,
    required this.flowerSentence,
  });
  final String emotionName;
  final String flowerName;
  final String flowerSentence;
}

class DiaryService {
  DiaryService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<DiaryDraft> createDraftAndQuestion({
    required AuthTokens tokens,
    required String title,
    required String situationText,
  }) async {
    final groups = await _get('/groups', tokens);
    if (groups is! List ||
        groups.isEmpty ||
        groups.first is! Map<String, dynamic>) {
      throw const DiaryException('일기를 작성하려면 먼저 가족 그룹에 참여해주세요.');
    }
    final groupId = (groups.first as Map<String, dynamic>)['id'];
    if (groupId is! int) throw const DiaryException('가족 그룹 정보를 읽을 수 없습니다.');
    final created = await _write('/diaries', tokens, {
      'group_id': groupId,
      'title': title,
      'situation_text': situationText,
      'record_date': DateTime.now().toIso8601String(),
    });
    final id = created['id'];
    if (id is! int) throw const DiaryException('일기 저장 응답 형식이 올바르지 않습니다.');
    final question = await _write(
      '/diaries/$id/ai-question',
      tokens,
      const {},
      timeout: const Duration(seconds: 75),
    );
    final text = question['ai_question_text'];
    if (text is! String || text.trim().isEmpty)
      throw const DiaryException('AI 질문을 생성하지 못했습니다.');
    return DiaryDraft(id: id, aiQuestion: text);
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
    if (response is! List)
      throw const DiaryException('감정 태그 추천 응답 형식이 올바르지 않습니다.');
    final tags = <EmotionTagOption>[];
    for (final item in response.whereType<Map<String, dynamic>>()) {
      final emotion = (item['display_name'] ?? item['emotion'] ?? '감정')
          .toString();
      for (final tag
          in (item['tags'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        if (tag['id'] is int && tag['tag_name'] is String) {
          tags.add(
            EmotionTagOption(
              id: tag['id'] as int,
              name: tag['tag_name'] as String,
              emotionName: emotion,
            ),
          );
        }
      }
    }
    if (tags.length < 3) throw const DiaryException('추천 감정 태그가 충분하지 않습니다.');
    return tags;
  }

  Future<DiaryFinalization> saveTagsAndFinalize({
    required AuthTokens tokens,
    required int diaryId,
    required List<int> tagIds,
  }) async {
    if (tagIds.length != 3) throw const DiaryException('감정 태그를 정확히 3개 선택해주세요.');
    await _put('/diaries/$diaryId/emotion-tags', tokens, {
      'emotion_tag_ids': tagIds,
    });
    final result = await _write('/diaries/$diaryId/finalize', tokens, const {});
    final emotion = result['emotion'] as Map<String, dynamic>? ?? const {};
    final flower = result['flower'] as Map<String, dynamic>? ?? const {};
    return DiaryFinalization(
      emotionName: (emotion['display_name'] ?? emotion['emotion'] ?? '오늘의 감정')
          .toString(),
      flowerName: (flower['flower_name'] ?? '마음의 꽃').toString(),
      flowerSentence: (flower['sentence'] ?? '').toString(),
    );
  }

  Future<dynamic> _get(String path, AuthTokens tokens) async => _body(
    await _send(() => _client.get(_uri(path), headers: _headers(tokens))),
  );
  Future<Map<String, dynamic>> _write(
    String path,
    AuthTokens tokens,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 20),
  }) async => _map(
    await _send(
      () => _client.post(
        _uri(path),
        headers: _headers(tokens),
        body: jsonEncode(data),
      ),
      timeout: timeout,
    ),
  );
  Future<Map<String, dynamic>> _patch(
    String path,
    AuthTokens tokens,
    Map<String, dynamic> data,
  ) async => _map(
    await _send(
      () => _client.patch(
        _uri(path),
        headers: _headers(tokens),
        body: jsonEncode(data),
      ),
    ),
  );
  Future<Map<String, dynamic>> _put(
    String path,
    AuthTokens tokens,
    Map<String, dynamic> data,
  ) async => _map(
    await _send(
      () => _client.put(
        _uri(path),
        headers: _headers(tokens),
        body: jsonEncode(data),
      ),
    ),
  );

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await request().timeout(timeout);
    } on Exception {
      throw const DiaryException('서버에 연결할 수 없습니다. 네트워크를 확인해주세요.');
    }
  }

  Map<String, dynamic> _map(http.Response response) {
    final value = _body(response);
    if (value is! Map<String, dynamic>)
      throw const DiaryException('서버 응답 형식이 올바르지 않습니다.');
    return value;
  }

  dynamic _body(http.Response response) {
    dynamic value;
    try {
      value = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      value = const <String, dynamic>{};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return value;
    if (response.statusCode == 401)
      throw const DiaryException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    final detail = value is Map<String, dynamic> ? value['detail'] : null;
    throw DiaryException(
      detail is String && detail.isNotEmpty
          ? detail
          : '일기 처리에 실패했습니다. 잠시 후 다시 시도해주세요.',
    );
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');
  Map<String, String> _headers(AuthTokens tokens) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${tokens.accessToken}',
  };
}
