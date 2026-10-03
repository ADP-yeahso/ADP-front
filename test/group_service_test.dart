import 'dart:convert';

import 'package:care_garden/services/auth_service.dart';
import 'package:care_garden/services/group_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const tokens = AuthTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'bearer',
  );

  test('내 그룹 목록을 인증 토큰과 함께 가져온다', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/groups');
      expect(request.headers['authorization'], 'Bearer access-token');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'id': 7,
              'group_name': '우리 가족',
              'invite_code': 'ABCDEFGH',
              'member_count': 3,
              'created_at': '2026-10-03T10:00:00Z',
            },
          ]),
        ),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final groups = await GroupService(client: client).listGroups(tokens);

    expect(groups, hasLength(1));
    expect(groups.single.name, '우리 가족');
    expect(groups.single.memberCount, 3);
  });

  test('초대 코드로 그룹에 참여한다', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/groups/join');
      expect(request.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(request.body), {'invite_code': 'ABCDEFGH'});
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'id': 7,
            'group_name': '우리 가족',
            'invite_code': 'ABCDEFGH',
            'member_count': 3,
            'created_at': '2026-10-03T10:00:00Z',
          }),
        ),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final group = await GroupService(
      client: client,
    ).joinGroup(tokens: tokens, inviteCode: ' ABCDEFGH ');

    expect(group.id, 7);
    expect(group.name, '우리 가족');
  });
}
