import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/care_notebook/care_record_view_data.dart';
import 'package:care_garden/services/api_service.dart';
import 'package:care_garden/services/auth_service.dart';
import 'package:care_garden/services/care_notebook_service.dart';
import 'package:care_garden/services/diary_service.dart';

const tokens = AuthTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
  tokenType: 'bearer',
);
const userId = '74dd5081-7a25-4885-b1df-204076c4e139';

http.Response jsonResponse(Object? body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> groupDetail(int id) => {
  'id': id,
  'group_name': '가족 $id',
  'invite_code': 'INVITE$id',
  'member_count': 1,
  'created_at': '2026-10-01T00:00:00Z',
  'members': [
    {'user_id': userId, 'name': '사용자', 'patients_nickname': '아버지'},
  ],
  'patient': {
    'id': 43,
    'patient_name': '환자',
    'patient_birth_date': '1950-01-02',
  },
};

void main() {
  test(
    'selected group hydrates UUID users, server record IDs and signed media',
    () async {
      final requests = <http.Request>[];
      final data = AppData(
        api: ApiService(
          client: MockClient((request) async {
            requests.add(request);
            expect(request.headers['Authorization'], 'Bearer access');
            switch (request.url.path) {
              case '/api/v1/users/me':
                return jsonResponse({'id': userId, 'name': '사용자'});
              case '/api/v1/groups/7':
                return jsonResponse(groupDetail(7));
              case '/api/v1/patients/43/memory-records':
                return jsonResponse([
                  {
                    'id': 81,
                    'patient_id': 43,
                    'user_id': userId,
                    'context': '산책한 날',
                    'title': '산책 기록',
                    'record_date': '2026-10-20',
                  },
                ]);
              case '/api/v1/diaries':
                expect(request.url.queryParameters['group_id'], '7');
                return jsonResponse([
                  {'id': 92, 'status': 'completed', 'final_emotion_id': 5},
                ]);
              case '/api/v1/diaries/92':
                return jsonResponse({
                  'id': 92,
                  'user_id': userId,
                  'situation_text': '고마운 하루',
                  'title': '감사 일기',
                  'finalized_at': '2026-10-21T12:00:00Z',
                  'emotion': {
                    'id': 5,
                    'emotion': 'gratitude',
                    'display_name': '감사/안도',
                  },
                  'flower': {'id': 4, 'flower_name': '꽃', 'sentence': '오늘의 문장'},
                  'media': [
                    {'id': 12},
                  ],
                });
              case '/api/v1/diaries/92/media':
                return jsonResponse([
                  {
                    'id': 12,
                    'diary_id': 92,
                    'file_type': 'image',
                    'file_url': 'diaries/92/photo.jpg',
                    'download_url': 'https://storage.example/photo.jpg',
                  },
                ]);
            }
            fail('Unexpected request: ${request.url}');
          }),
        ),
      );
      addTearDown(data.dispose);
      expect(data.memories, isEmpty);
      expect(data.diaries, isEmpty);
      await data.openGroup(tokens, 7);
      expect(data.currentUserId, userId);
      expect(data.me.name, '사용자');
      expect(data.patientRelationLabel, '아버지');
      expect(data.patient.id, 43);
      expect(data.memories.single.id, 81);
      expect(data.diaries.single.id, 92);
      expect(data.diaries.single.title, '감사 일기');
      expect(data.memories.single.title, '산책 기록');
      expect(
        data.diaries.single.mediaList.single.fileUrl,
        'https://storage.example/photo.jpg',
      );
      expect(data.loadError, isNull);
      expect(
        requests.any((request) => request.url.path.contains('/calendar')),
        isFalse,
      );
    },
  );

  test('logout discards a pending group response', () async {
    final pending = Completer<http.Response>();
    final data = AppData(
      api: ApiService(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/users/me')) return pending.future;
          return jsonResponse(groupDetail(7));
        }),
      ),
    );
    addTearDown(data.dispose);
    final opening = data.openGroup(tokens, 7);
    data.clear();
    pending.complete(jsonResponse({'id': userId, 'name': '사용자'}));
    await opening;
    expect(data.currentUserId, isEmpty);
    expect(data.group.id, 0);
    expect(data.users, isEmpty);
  });

  test(
    'record hydration reads every page rather than only the first 100',
    () async {
      final pages = <String>[];
      final data = AppData(
        api: ApiService(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/users/me')) {
              return jsonResponse({'id': userId});
            }
            if (request.url.path.endsWith('/groups/7')) {
              return jsonResponse(groupDetail(7));
            }
            if (request.url.path.endsWith('/diaries')) return jsonResponse([]);
            final page = request.url.queryParameters['page']!;
            pages.add(page);
            return jsonResponse(
              List.generate(
                page == '1' ? 100 : 1,
                (index) => {
                  'id': page == '1' ? index : 100,
                  'patient_id': 43,
                  'user_id': userId,
                  'context': '기록',
                  'record_date': '2026-10-20',
                },
              ),
            );
          }),
        ),
      );
      addTearDown(data.dispose);
      await data.openGroup(tokens, 7);
      expect(pages, ['1', '2']);
      expect(data.memories, hasLength(101));
    },
  );

  test('diary files use authenticated multipart with a MIME type', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/diaries/91/media');
        expect(request.headers['authorization'], 'Bearer access');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(request.body, contains('filename="photo.png"'));
        expect(request.body, contains('content-type: image/png'));
        expect(request.body, contains('name="sort_order"'));
        return jsonResponse({'id': 71}, 201);
      }),
    );
    addTearDown(api.close);
    final uploaded = await MediaApi(api).uploadDiary(
      tokens,
      91,
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'photo.png',
      contentType: 'image/png',
    );
    expect(uploaded['id'], 71);
  });

  test('profile updates use PUT and FastAPI errors retain status', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/users/me');
        expect(jsonDecode(request.body)['name'], '새 이름');
        return jsonResponse({'detail': '권한이 없습니다.'}, 403);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      UserApi(
        api,
      ).updateProfile(tokens, {'name': '새 이름', 'phone_number': '010'}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 403)
            .having((error) => error.message, 'message', '권한이 없습니다.'),
      ),
    );
  });

  test(
    'care retries reuse successful writes and send required fields',
    () async {
      final requests = <http.Request>[];
      var failVisit = true;
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (request.url.path.endsWith('/daily-conditions')) {
            expect(body['patient_id'], 43);
            expect(body['activity_status'], '적음');
            expect(body['cognitive_status'], '평소와 비슷');
            expect(body['mood_status'], '차분함');
            expect(body['record_date'], '2026-10-20');
            return jsonResponse({'id': 11}, 201);
          }
          if (request.url.path.endsWith('/behavior-logs')) {
            return jsonResponse({'id': 12}, 201);
          }
          if (request.url.path.endsWith('/hospital-visits')) {
            if (failVisit) {
              failVisit = false;
              return jsonResponse({'detail': '잠시 후 재시도'}, 503);
            }
            expect(body['next_visit_date'], '2026-11-20');
            return jsonResponse({'id': 13}, 201);
          }
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/v1/care-notes/daily-conditions/11');
          return jsonResponse({'id': 11});
        }),
      );
      addTearDown(api.close);
      final service = CareNotebookService(api);
      final progress = CareSaveProgress();
      final record = CareRecordViewData(
        date: DateTime(2026, 10, 20),
        mealStatus: '보통',
        sleepStatus: '좋음',
        bowelStatus: '정상',
        medicationStatus: '완료',
        activityStatus: '적음',
        moodStatus: '차분함',
        cognitiveStatus: '평소와 비슷',
        unusualChanges: const ['배회'],
        hasMedicalUpdate: true,
        hospitalDepartment: '우리 병원',
        nextVisitDate: DateTime(2026, 11, 20),
      );
      await expectLater(
        service.save(tokens, 43, record, progress),
        throwsA(isA<ApiException>()),
      );
      await service.save(tokens, 43, record, progress);
      expect(
        requests.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/daily-conditions'),
        ),
        hasLength(1),
      );
      expect(
        requests.where((r) => r.url.path.endsWith('/behavior-logs')),
        hasLength(1),
      );
      expect(progress.visitId, 13);
    },
  );

  test(
    'draft retry keeps the selected group and does not create a second diary',
    () async {
      var creates = 0;
      var questions = 0;
      final service = DiaryService(
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/diaries') {
            creates++;
            expect(jsonDecode(request.body)['group_id'], 7);
            return jsonResponse({'id': 91}, 201);
          }
          expect(request.url.path, '/api/v1/diaries/91/ai-question');
          questions++;
          return questions == 1
              ? jsonResponse({'detail': '재시도'}, 503)
              : jsonResponse({'ai_question_text': '어떤 하루였나요?'});
        }),
      );
      addTearDown(service.close);
      Future<DiaryDraft> create() => service.createDraftAndQuestion(
        tokens: tokens,
        groupId: 7,
        situationText: '오늘의 상황',
        recordDate: DateTime(2026, 10, 20),
      );
      await expectLater(create(), throwsA(isA<DiaryException>()));
      expect((await create()).id, 91);
      expect(creates, 1);
    },
  );
}
