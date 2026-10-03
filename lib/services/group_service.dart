import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class GroupException implements Exception {
  const GroupException(this.message);

  final String message;
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberCount,
    required this.createdAt,
    this.profileImageUrl,
  });

  final int id;
  final String name;
  final String inviteCode;
  final int memberCount;
  final DateTime createdAt;
  final String? profileImageUrl;

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['group_name'];
    if (id is! int || name is! String || name.isEmpty) {
      throw const GroupException('그룹 정보 응답 형식이 올바르지 않습니다.');
    }
    return GroupSummary(
      id: id,
      name: name,
      inviteCode: json['invite_code'] as String? ?? '',
      memberCount: json['member_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      profileImageUrl: json['group_profile_image_url'] as String?,
    );
  }
}

class GroupService {
  GroupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<GroupSummary>> listGroups(AuthTokens tokens) async {
    final response = await _send(
      () => _client.get(_uri('/groups'), headers: _headers(tokens)),
    );
    final body = _bodyOrThrow(response);
    if (body is! List) {
      throw const GroupException('그룹 목록 응답 형식이 올바르지 않습니다.');
    }
    return body
        .whereType<Map<String, dynamic>>()
        .map(GroupSummary.fromJson)
        .toList();
  }

  Future<GroupSummary> joinGroup({
    required AuthTokens tokens,
    required String inviteCode,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/groups/join'),
        headers: _headers(tokens),
        body: jsonEncode({'invite_code': inviteCode.trim()}),
      ),
    );
    final body = _bodyOrThrow(response);
    if (body is! Map<String, dynamic>) {
      throw const GroupException('그룹 참여 응답 형식이 올바르지 않습니다.');
    }
    return GroupSummary.fromJson(body);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 20));
    } on Exception {
      throw const GroupException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
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
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    if (response.statusCode == 401) {
      throw const GroupException('로그인이 만료되었습니다. 다시 로그인해주세요.');
    }
    final detail = body is Map<String, dynamic> ? body['detail'] : null;
    if (detail is String && detail.isNotEmpty) throw GroupException(detail);
    if (response.statusCode == 422) {
      throw const GroupException('초대 코드를 다시 확인해주세요.');
    }
    throw const GroupException('그룹 처리에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers(AuthTokens tokens) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${tokens.accessToken}',
  };
}
