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
}
