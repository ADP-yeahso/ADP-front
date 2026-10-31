import 'dart:async';
import 'dart:convert';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/services/api_service.dart';
import 'package:care_garden/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tokens = AuthTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
  tokenType: 'bearer',
);
const _user = '74dd5081-7a25-4885-b1df-204076c4e139';
const _memory = {
  'id': 81,
  'patient_id': 43,
  'user_id': _user,
  'title': '산책',
  'context': '함께 걸었어요.',
  'record_date': '2026-10-20',
};
const _diary = {
  'id': 92,
  'user_id': _user,
  'status': 'completed',
  'title': '평온한 날',
  'situation_text': '함께 쉬었어요.',
  'final_emotion_id': 0,
  'record_date': '2026-10-20T12:00:00Z',
  'finalized_at': '2026-10-20T12:00:00Z',
  'emotion': {'id': 0, 'emotion': 'neutral', 'display_name': '중립'},
  'flower': {'id': 4, 'flower_name': '평온의 꽃', 'sentence': '편안한 하루'},
};

http.Response _response(Object? value, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(value)),
      status,
      headers: {'content-type': 'application/json'},
    );

Future<AppData> _loadData({
  Future<http.Response> Function(http.Request)? mutation,
  Future<http.Response> Function()? memoryList,
}) async {
  final data = AppData(
    api: ApiService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer access');
        if (request.method != 'GET') {
          if (mutation != null) return mutation(request);
          fail('Unexpected mutation: ${request.method} ${request.url.path}');
        }
        switch (request.url.path) {
          case '/api/v1/users/me':
            return _response({'id': _user});
          case '/api/v1/groups/7':
            return _response({
              'id': 7,
              'group_name': '가족',
              'invite_code': 'INVITE',
              'member_count': 1,
              'members': [
                {'user_id': _user},
              ],
              'patient': {'id': 43, 'patient_name': '환자'},
            });
          case '/api/v1/patients/43/memory-records':
            return memoryList == null ? _response([_memory]) : memoryList();
          case '/api/v1/diaries':
            return _response([
              _diary,
              {'id': 93, 'status': 'draft', 'final_emotion_id': 1},
            ]);
          case '/api/v1/diaries/92':
            return _response(_diary);
        }
        fail('Unexpected read: ${request.url}');
      }),
    ),
  );
  addTearDown(data.dispose);
  await data.openGroup(_tokens, 7);
  return data;
}

void main() {
  test(
    'memory creation uses the selected patient and caches the server ID',
    () async {
      final data = await _loadData(
        mutation: (request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/patients/43/memory-records');
          expect(jsonDecode(request.body), {
            'title': '새 기록',
            'context': '내용',
            'record_date': '2026-10-21',
          });
          return _response({..._memory, 'id': 82, 'title': '새 기록'}, 201);
        },
      );
      expect(
        await data.createMemory({
          'title': '새 기록',
          'context': '내용',
          'record_date': '2026-10-21',
        }),
        isTrue,
      );
      expect(data.memories.last.id, 82);
      expect(data.memories.last.title, '새 기록');
    },
  );

  test(
    'hydrates server titles and neutral 0, excluding drafts with AI results',
    () async {
      final data = await _loadData();
      expect(data.diaries, hasLength(1));
      expect(data.diaries.single.flowerType.emotionId.id, 0);
      expect(data.diaries.single.title, '평온한 날');
      expect(data.memories.single.title, '산책');
    },
  );

  test(
    'memory editing waits for PATCH and uses the saved server response',
    () async {
      final pending = Completer<http.Response>();
      final data = await _loadData(
        mutation: (request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/v1/memory-records/81');
          expect(jsonDecode(request.body), {
            'title': '수정 제목',
            'context': '새 내용',
          });
          return pending.future;
        },
      );
      final saving = data.updateMemoryText(81, '수정 제목', ' 새 내용 ');
      expect(data.memories.single.title, '산책');
      pending.complete(
        _response({..._memory, 'title': '서버 제목', 'context': '서버 내용'}),
      );
      expect(await saving, isTrue);
      expect(data.memories.single.title, '서버 제목');
      expect(data.memories.single.contextText, '서버 내용');
    },
  );

  test('completed diary edit rejection preserves the original text', () async {
    final data = await _loadData(
      mutation: (request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/diaries/92');
        expect(jsonDecode(request.body), {
          'title': null,
          'situation_text': '변경 내용',
        });
        return _response({'detail': 'Finalized diary cannot be edited'}, 409);
      },
    );
    await expectLater(
      data.updateDiaryText(92, null, '변경 내용'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
    expect(data.diaries.single.title, '평온한 날');
    expect(data.diaries.single.context, '함께 쉬었어요.');
  });

  test(
    'successful DELETE removes memory and diary from shared screen data',
    () async {
      final paths = <String>[];
      final data = await _loadData(
        mutation: (request) async {
          expect(request.method, 'DELETE');
          paths.add(request.url.path);
          return http.Response('', 204);
        },
      );
      expect(await data.deleteMemory(81), isTrue);
      expect(await data.deleteDiary(92), isTrue);
      expect(paths, ['/api/v1/memory-records/81', '/api/v1/diaries/92']);
      expect(data.memories, isEmpty);
      expect(data.diaries, isEmpty);
      expect(data.diariesForGarden(DateTime(2026, 10, 31)), isEmpty);
      expect(data.sharedMemories, isEmpty);
    },
  );

  test('failed DELETE keeps both records available for retry', () async {
    final data = await _loadData(
      mutation: (_) async => _response({'detail': '삭제할 권한이 없습니다.'}, 403),
    );
    await expectLater(data.deleteMemory(81), throwsA(isA<ApiException>()));
    await expectLater(data.deleteDiary(92), throwsA(isA<ApiException>()));
    expect(data.memories.single.id, 81);
    expect(data.diaries.single.id, 92);
  });

  test('logout discards a pending successful edit', () async {
    final pending = Completer<http.Response>();
    final data = await _loadData(mutation: (_) => pending.future);
    final saving = data.updateMemoryText(81, '새 제목', '새 내용');
    data.clear();
    pending.complete(_response({..._memory, 'title': '새 제목'}));
    expect(await saving, isFalse);
    expect(data.memories, isEmpty);
  });

  test(
    'a refresh started before DELETE cannot restore the deleted record',
    () async {
      var reads = 0;
      final pending = Completer<http.Response>();
      final data = await _loadData(
        memoryList: () async =>
            ++reads == 1 ? _response([_memory]) : pending.future,
        mutation: (_) async => http.Response('', 204),
      );
      final refreshing = data.refreshRecords();
      await data.deleteMemory(81);
      pending.complete(_response([_memory]));
      await refreshing;
      expect(data.memories, isEmpty);
    },
  );
}
