import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin client for the endpoints in API_X.pdf.
/// Feature services should use this class so auth headers and error handling
/// stay identical across the app.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path, AuthTokens tokens) =>
      _send(() => _client.get(_uri(path), headers: _headers(tokens)), tokens);

  Future<dynamic> post(
    String path,
    AuthTokens tokens, {
    Object? body,
    int? expectedStatus,
  }) => _send(
    () => _client.post(
      _uri(path),
      headers: _headers(tokens),
      body: body == null ? null : jsonEncode(body),
    ),
    tokens,
    expectedStatus: expectedStatus,
  );

  Future<dynamic> patch(String path, AuthTokens tokens, Object body) => _send(
    () => _client.patch(
      _uri(path),
      headers: _headers(tokens),
      body: jsonEncode(body),
    ),
    tokens,
  );

  Future<dynamic> put(String path, AuthTokens tokens, {Object? body}) => _send(
    () => _client.put(
      _uri(path),
      headers: _headers(tokens),
      body: body == null ? null : jsonEncode(body),
    ),
    tokens,
  );

  Future<void> delete(String path, AuthTokens tokens) async {
    await _send(
      () => _client.delete(_uri(path), headers: _headers(tokens)),
      tokens,
    );
  }

  Future<dynamic> uploadBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final response = await _client.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('파일 업로드에 실패했습니다.', statusCode: response.statusCode);
    }
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers(AuthTokens tokens) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${tokens.accessToken}',
  };

  Future<dynamic> _send(
    Future<http.Response> Function() request,
    AuthTokens tokens, {
    int? expectedStatus,
  }) async {
    try {
      final response = await request().timeout(const Duration(seconds: 30));
      final body = response.body.isEmpty ? null : _decode(response.body);
      final okay = expectedStatus == null
          ? response.statusCode >= 200 && response.statusCode < 300
          : response.statusCode == expectedStatus;
      if (!okay) {
        final detail = body is Map<String, dynamic> ? body['detail'] : null;
        throw ApiException(
          detail is String && detail.isNotEmpty ? detail : 'API 요청에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException('서버에 연결할 수 없습니다. 네트워크와 서버 주소를 확인해주세요.');
    }
  }

  dynamic _decode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }
}

class GroupApi {
  GroupApi(this._api);
  final ApiService _api;

  Future<List<Map<String, dynamic>>> list(AuthTokens tokens) async {
    final response = await _api.get('/groups', tokens);
    if (response is List) return _maps(response);
    if (response is Map<String, dynamic>) {
      for (final key in ['groups', 'items', 'data']) {
        final value = response[key];
        if (value is List) return _maps(value);
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> create(
    AuthTokens tokens, {
    required String groupName,
    String? profileImageUrl,
  }) async => _map(
    await _api.post(
      '/groups',
      tokens,
      body: {
        'group_name': groupName,
        if (profileImageUrl != null) 'group_profile_image_url': profileImageUrl,
      },
    ),
  );

  Future<Map<String, dynamic>> join(
    AuthTokens tokens,
    String inviteCode,
  ) async => _map(
    await _api.post('/groups/join', tokens, body: {'invite_code': inviteCode}),
  );

  Future<Map<String, dynamic>> detail(AuthTokens tokens, int groupId) async =>
      _map(await _api.get('/groups/$groupId', tokens));

  Future<List<Map<String, dynamic>>> members(
    AuthTokens tokens,
    int groupId,
  ) async => _maps(await _api.get('/groups/$groupId/members', tokens));

  Future<Map<String, dynamic>> updateMembership(
    AuthTokens tokens,
    int groupId, {
    String? patientsNickname,
    String? patientRelation,
  }) async => _map(
    await _api.patch('/groups/$groupId/members/me', tokens, {
      if (patientsNickname != null) 'patients_nickname': patientsNickname,
      if (patientRelation != null) 'patient_relation': patientRelation,
    }),
  );
}

class PatientApi {
  PatientApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> create(
    AuthTokens tokens,
    int groupId,
    Map<String, dynamic> body,
  ) async =>
      _map(await _api.post('/groups/$groupId/patients', tokens, body: body));

  Future<Map<String, dynamic>> get(AuthTokens tokens, int patientId) async =>
      _map(await _api.get('/patients/$patientId', tokens));

  Future<Map<String, dynamic>> update(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(await _api.patch('/patients/$patientId', tokens, body));
}

class MemoryRecordApi {
  MemoryRecordApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> create(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post('/patients/$patientId/memory-records', tokens, body: body),
  );

  Future<List<Map<String, dynamic>>> list(
    AuthTokens tokens,
    int patientId, {
    int page = 1,
    int size = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{'page': '$page', 'size': '$size'};
    if (fromDate != null) query['from_date'] = _date(fromDate);
    if (toDate != null) query['to_date'] = _date(toDate);
    final suffix = Uri(queryParameters: query).query;
    return _maps(
      await _api.get('/patients/$patientId/memory-records?$suffix', tokens),
    );
  }

  Future<Map<String, dynamic>> detail(AuthTokens tokens, int id) async =>
      _map(await _api.get('/memory-records/$id', tokens));

  Future<Map<String, dynamic>> update(
    AuthTokens tokens,
    int id,
    Map<String, dynamic> body,
  ) async => _map(await _api.patch('/memory-records/$id', tokens, body));

  Future<void> remove(AuthTokens tokens, int id) =>
      _api.delete('/memory-records/$id', tokens);

  Future<bool> setBookmark(AuthTokens tokens, int id, bool value) async {
    if (value) {
      final body = await _api.put('/memory-records/$id/bookmark', tokens);
      return (body as Map<String, dynamic>)['bookmarked'] == true;
    }
    await _api.delete('/memory-records/$id/bookmark', tokens);
    return false;
  }

  Future<List<Map<String, dynamic>>> comments(
    AuthTokens tokens,
    int id,
  ) async => _maps(await _api.get('/memory-records/$id/comments', tokens));

  Future<Map<String, dynamic>> addComment(
    AuthTokens tokens,
    int id,
    String text,
  ) async => _map(
    await _api.post(
      '/memory-records/$id/comments',
      tokens,
      body: {'comment_text': text},
    ),
  );

  Future<void> removeComment(AuthTokens tokens, int id) =>
      _api.delete('/comments/$id', tokens);
}

class MediaApi {
  MediaApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> presign(
    AuthTokens tokens, {
    required String fileName,
    required String fileType,
  }) async => _map(
    await _api.post(
      '/media/presign',
      tokens,
      body: {'file_name': fileName, 'file_type': fileType},
    ),
  );

  Future<Map<String, dynamic>> register(
    AuthTokens tokens,
    int groupId,
    Map<String, dynamic> body,
  ) async =>
      _map(await _api.post('/groups/$groupId/gallery', tokens, body: body));

  Future<List<Map<String, dynamic>>> gallery(
    AuthTokens tokens,
    int groupId, {
    int page = 1,
    int size = 20,
  }) async => _maps(
    await _api.get('/groups/$groupId/gallery?page=$page&size=$size', tokens),
  );

  Future<void> remove(AuthTokens tokens, int groupId, int mediaId) =>
      _api.delete('/groups/$groupId/gallery/$mediaId', tokens);
}

class UserApi {
  UserApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> authMe(AuthTokens tokens) async =>
      _map(await _api.get('/auth/me', tokens));

  Future<Map<String, dynamic>> profile(AuthTokens tokens) async =>
      _map(await _api.get('/users/me', tokens));

  Future<Map<String, dynamic>> updateProfile(
    AuthTokens tokens,
    Map<String, dynamic> body,
  ) async => _map(await _api.patch('/users/me', tokens, body));

  Future<void> changePassword(
    AuthTokens tokens,
    String currentPassword,
    String newPassword,
  ) async {
    await _api.patch('/users/me/password', tokens, {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

class CalendarApi {
  CalendarApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> month(
    AuthTokens tokens,
    int groupId,
    DateTime value,
  ) async => _map(
    await _api.get(
      '/groups/$groupId/calendar?year=${value.year}&month=${value.month}',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> day(
    AuthTokens tokens,
    int groupId,
    DateTime value,
  ) async =>
      _map(await _api.get('/groups/$groupId/calendar/${_date(value)}', tokens));

  Future<Map<String, dynamic>> garden(
    AuthTokens tokens,
    DateTime value, {
    int? groupId,
  }) async {
    final query = Uri(
      queryParameters: {
        'year': '${value.year}',
        'month': '${value.month}',
        if (groupId != null) 'group_id': '$groupId',
      },
    ).query;
    return _map(await _api.get('/gardens?$query', tokens));
  }
}

class CareApi {
  CareApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> createDailyCondition(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post(
      '/patients/$patientId/daily-conditions',
      tokens,
      body: body,
    ),
  );

  Future<List<Map<String, dynamic>>> dailyConditions(
    AuthTokens tokens,
    int patientId, {
    DateTime? recordDate,
  }) async => _maps(
    await _api.get(
      '/patients/$patientId/daily-conditions${recordDate == null ? '' : '?record_date=${_date(recordDate)}'}',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> updateDailyCondition(
    AuthTokens tokens,
    int patientId,
    int conditionId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.patch(
      '/patients/$patientId/daily-conditions/$conditionId',
      tokens,
      body,
    ),
  );

  Future<Map<String, dynamic>> createBehaviorLog(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post('/patients/$patientId/behavior-logs', tokens, body: body),
  );

  Future<List<Map<String, dynamic>>> behaviorLogs(
    AuthTokens tokens,
    int patientId,
  ) async =>
      _maps(await _api.get('/patients/$patientId/behavior-logs', tokens));

  Future<Map<String, dynamic>> addMedication(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post('/patients/$patientId/medications', tokens, body: body),
  );

  Future<List<Map<String, dynamic>>> medications(
    AuthTokens tokens,
    int patientId, {
    bool activeOnly = false,
  }) async => _maps(
    await _api.get(
      '/patients/$patientId/medications?active_only=$activeOnly',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> upsertIntake(
    AuthTokens tokens,
    int medicationId,
    DateTime logDate,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.put(
      '/medications/$medicationId/intake-logs/${_date(logDate)}',
      tokens,
      body: body,
    ),
  );

  Future<List<Map<String, dynamic>>> intakeLogs(
    AuthTokens tokens,
    int medicationId,
  ) async =>
      _maps(await _api.get('/medications/$medicationId/intake-logs', tokens));

  Future<Map<String, dynamic>> createHospitalVisit(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post('/patients/$patientId/hospital-visits', tokens, body: body),
  );

  Future<List<Map<String, dynamic>>> hospitalVisits(
    AuthTokens tokens,
    int patientId,
  ) async =>
      _maps(await _api.get('/patients/$patientId/hospital-visits', tokens));
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : <Map<String, dynamic>>[];
