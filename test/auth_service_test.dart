import 'dart:convert';

import 'package:care_garden/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthService.signup', () {
    test('회원가입 정보를 API 규격에 맞춰 전송하고 응답을 반환한다', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/signup');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'Password1!',
          'name': '사용자',
          'phone_number': '010-1234-5678',
        });

        return http.Response(
          jsonEncode({
            'id': 'user-id',
            'email': 'user@example.com',
            'name': '사용자',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AuthService(client: client).signup(
        email: 'user@example.com',
        password: 'Password1!',
        name: '사용자',
        phoneNumber: '010-1234-5678',
      );

      expect(result.id, 'user-id');
      expect(result.email, 'user@example.com');
      expect(result.name, '사용자');
    });

    test('중복 또는 사용할 수 없는 가입 정보는 사용자 오류로 변환한다', () async {
      final client = MockClient((_) async => http.Response('{}', 400));

      expect(
        () => AuthService(client: client).signup(
          email: 'user@example.com',
          password: 'Password1!',
          name: '사용자',
          phoneNumber: '010-1234-5678',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('이미 가입된 이메일'),
          ),
        ),
      );
    });
  });
}
