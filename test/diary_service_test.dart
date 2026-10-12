import 'dart:convert';

import 'package:care_garden/services/auth_service.dart';
import 'package:care_garden/services/diary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const tokens = AuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'bearer',
  );

  test('일기 생성 후 AI 질문을 받아온다', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['authorization'], 'Bearer access-token');
      if (request.url.path == '/api/v1/groups') {
        return http.Response(
          jsonEncode([
            {'id': 7},
          ]),
          200,
        );
      }
      if (request.url.path == '/api/v1/diaries') {
        expect(jsonDecode(request.body), containsPair('group_id', 7));
        return http.Response(jsonEncode({'id': 42}), 201);
      }
      if (request.url.path == '/api/v1/diaries/42/ai-question') {
        return http.Response(
          jsonEncode({
            'diary_id': 42,
            'ai_question_text': '오늘 가장 힘들었던 순간은 언제였나요?',
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{}', 404);
    });

    final result = await DiaryService(client: client).createDraftAndQuestion(
      tokens: tokens,
      title: '오늘의 기록',
      situationText: '돌봄이 힘들었지만 가족과 대화했다.',
      recordDate: DateTime(2026, 9, 17),
    );

    expect(result.id, 42);
    expect(result.aiQuestion, contains('힘들었던'));
    expect(requests.map((request) => request.method), ['GET', 'POST', 'POST']);
  });

  test('답변을 저장하고 AI 감정 태그 추천을 받아온다', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['authorization'], 'Bearer access-token');
      if (request.method == 'PATCH' &&
          request.url.path == '/api/v1/diaries/42/answer') {
        expect(
          jsonDecode(request.body),
          containsPair('question_answer_text', '혼자 감당하는 기분이 들었어요.'),
        );
        return http.Response('{}', 200);
      }
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/diaries/42/emotion-tag-suggestions') {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode([
              {
                'display_name': '불안',
                'tags': [
                  {'id': 1, 'tag_name': '걱정'},
                  {'id': 2, 'tag_name': '초조함'},
                ],
              },
              {
                'display_name': '슬픔',
                'tags': [
                  {'id': 3, 'tag_name': '외로움'},
                ],
              },
            ]),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{}', 404);
    });

    final tags = await DiaryService(client: client).saveAnswerAndGetSuggestions(
      tokens: tokens,
      diaryId: 42,
      answer: '혼자 감당하는 기분이 들었어요.',
    );

    expect(tags.map((tag) => tag.name), ['걱정', '초조함', '외로움']);
    expect(tags.first.emotionName, '불안');
    expect(requests.map((request) => request.method), ['PATCH', 'GET']);
  });

  test('확정 감정의 timestamp를 기준으로 월간 일기를 가져온다', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/diaries');
      expect(request.url.queryParameters['start_date'], '2026-09-01');
      expect(request.url.queryParameters['end_date'], '2026-09-30');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'id': 12,
              'emotion': {'id': 2, 'display_name': '불안/초조'},
              'finalized_at': '2026-09-17T23:30:00Z',
            },
            {
              'id': 13,
              'emotion': {'id': 5, 'display_name': '감사/안도'},
              'finalized_at': '2026-10-01T00:00:00Z',
            },
          ]),
        ),
        200,
      );
    });

    final entries = await DiaryService(
      client: client,
    ).fetchFinalizedForMonth(tokens: tokens, month: DateTime(2026, 9));

    expect(entries, hasLength(1));
    expect(entries.single.id, 12);
    expect(entries.single.emotionId, 2);
    expect(entries.single.finalizedAt.day, 18);
  });
}
