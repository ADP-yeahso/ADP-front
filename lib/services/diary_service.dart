import 'dart:convert';

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
  });

  final int id;
  final String name;
  final String emotionName;
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

class DiaryService {
  DiaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DiaryDraft> createDraftAndQuestion({
    required AuthTokens tokens,
    required String situationText,
    String? title,
    required DateTime recordDate,
  }) async {
    final groups = await _get('/groups', tokens);
    if (groups is! List || groups.isEmpty) {
      throw const DiaryException('일기를 작성하려면 먼저 가족 그룹에 참여해주세요.');
    }
    final firstGroup = groups.first;
    if (firstGroup is! Map<String, dynamic> || firstGroup['id'] is! int) {
      throw const DiaryException('가족 그룹 정보를 읽을 수 없습니다.');
    }

    final created = await _post('/diaries', tokens, {
      'group_id': firstGroup['id'],
      'situation_text': situationText,
      if (title != null && title.isNotEmpty) 'title': title,
      'record_date': recordDate.toIso8601String(),
    });
    final diaryId = created['id'];
    if (diaryId is! int) {
      throw const DiaryException('일기 저장 응답 형식이 올바르지 않습니다.');
    }

    final question = await _post(
      '/diaries/$diaryId/ai-question',
      tokens,
      const {},
    );
    final text = question['ai_question_text'];
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
    if (response is! List) {
      throw const DiaryException('감정 태그 추천 응답 형식이 올바르지 않습니다.');
    }

    final tags = <EmotionTagOption>[];
    for (final item in response.whereType<Map<String, dynamic>>()) {
      final emotionName = (item['display_name'] ?? item['emotion'] ?? '감정')
          .toString();
      final rawTags = item['tags'];
      if (rawTags is! List) continue;
      for (final tag in rawTags.whereType<Map<String, dynamic>>()) {
        final id = tag['id'];
        final name = tag['tag_name'];
        if (id is int && name is String) {
          tags.add(
            EmotionTagOption(id: id, name: name, emotionName: emotionName),
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
    if (tagIds.length != 3) {
      throw const DiaryException('감정 태그를 정확히 3개 선택해주세요.');
    }
    await _put('/diaries/$diaryId/emotion-tags', tokens, {
      'emotion_tag_ids': tagIds,
    });
    final result = await _post('/diaries/$diaryId/finalize', tokens, const {});
    final emotion = result['emotion'];
    final flower = result['flower'];
    final emotionMap = emotion is Map<String, dynamic>
        ? emotion
        : const <String, dynamic>{};
    final flowerMap = flower is Map<String, dynamic>
        ? flower
        : const <String, dynamic>{};
    return DiaryFinalization(
      emotionId: emotionMap['id'] as int?,
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
    Map<String, dynamic> body,
  ) => _write(
    () => _client.post(
      _uri(path),
      headers: _headers(tokens),
      body: jsonEncode(body),
    ),
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

  Future<Map<String, dynamic>> _put(
    String path,
    AuthTokens tokens,
    Map<String, dynamic> body,
  ) => _write(
    () => _client.put(
      _uri(path),
      headers: _headers(tokens),
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> _write(
    Future<http.Response> Function() request,
  ) async {
    final response = await _send(request);
    final body = _bodyOrThrow(response);
    if (body is! Map<String, dynamic>) {
      throw const DiaryException('서버 응답 형식이 올바르지 않습니다.');
    }
    return body;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 20));
    } on Exception {
      throw const DiaryException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
    }
  }

  dynamic _bodyOrThrow(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body);
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
