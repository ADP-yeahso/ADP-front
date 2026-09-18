import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final body = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final accessToken = body['access_token'];
    final refreshToken = body['refresh_token'];
    if (accessToken is! String || refreshToken is! String) {
      throw const AuthException('로그인 응답 형식이 올바르지 않습니다.');
    }
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    await _post(
      '/auth/signup',
      {
        'email': email,
        'password': password,
        'name': name,
        'phone_number': phoneNumber,
      },
      successCodes: const {201},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    Set<int> successCodes = const {200},
  }) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw const AuthException('서버에 연결할 수 없습니다. 네트워크를 확인해주세요.');
    }
    final decoded = _decode(response.body);
    if (successCodes.contains(response.statusCode)) return decoded;
    if (response.statusCode == 401)
      throw const AuthException('이메일 또는 비밀번호가 올바르지 않습니다.');
    if (response.statusCode == 400 || response.statusCode == 409)
      throw const AuthException('이미 가입됐거나 사용할 수 없는 이메일입니다.');
    if (response.statusCode == 422)
      throw const AuthException('입력 정보를 다시 확인해주세요.');
    throw AuthException(_detail(decoded) ?? '인증 처리에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }

  Map<String, dynamic> _decode(String source) {
    try {
      final value = jsonDecode(source);
      return value is Map<String, dynamic> ? value : const {};
    } on FormatException {
      return const {};
    }
  }

  String? _detail(Map<String, dynamic> body) =>
      body['detail'] is String ? body['detail'] as String : null;
}
