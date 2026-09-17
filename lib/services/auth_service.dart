import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
}

class SignupResult {
  const SignupResult({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
              'phone_number': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
    }

    final body = _decodeBody(response.body);
    if (response.statusCode == 201) {
      final id = body['id'] as String?;
      final responseEmail = body['email'] as String?;
      final responseName = body['name'] as String?;
      if (id == null || responseEmail == null || responseName == null) {
        throw const AuthException('회원가입 응답 형식이 올바르지 않습니다.');
      }
      return SignupResult(id: id, email: responseEmail, name: responseName);
    }

    // 현재 백엔드는 Supabase 가입 실패를 400으로 변환하고, 명세에는
    // 중복 계정이 409로 정의되어 있어 두 상태를 함께 처리합니다.
    if (response.statusCode == 400 || response.statusCode == 409) {
      throw const AuthException('이미 가입된 이메일이거나 사용할 수 없는 계정 정보입니다.');
    }
    if (response.statusCode == 422) {
      throw const AuthException('입력한 회원 정보를 다시 확인해주세요.');
    }
    throw const AuthException('회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
    }

    final body = _decodeBody(response.body);
    if (response.statusCode == 200) {
      final accessToken = body['access_token'] as String?;
      final refreshToken = body['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw const AuthException('로그인 응답 형식이 올바르지 않습니다.');
      }
      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: body['token_type'] as String? ?? 'bearer',
      );
    }

    if (response.statusCode == 401) {
      throw const AuthException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }
    if (response.statusCode == 422) {
      throw const AuthException('이메일과 비밀번호 형식을 확인해주세요.');
    }
    throw const AuthException('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
