import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Shared client for the deployed REST API.
/// Feature services should use this class so auth headers and error handling
/// stay identical across the app.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<dynamic> upload(
    String path,
    AuthTokens tokens, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
    Map<String, String> fields = const {},
  }) => _send(() async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers['Authorization'] = 'Bearer ${tokens.accessToken}'
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
    return http.Response.fromStream(await _client.send(request));
  }, tokens);

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
      final body = response.bodyBytes.isEmpty
          ? null
          : _decode(utf8.decode(response.bodyBytes));
      final okay = expectedStatus == null
          ? response.statusCode >= 200 && response.statusCode < 300
          : response.statusCode == expectedStatus;
      if (!okay) {
        final detail = body is Map<String, dynamic> ? body['detail'] : null;
        final detailMessage = detail == 'Media upload failed'
            ? '첨부 파일 업로드에 실패했어요. 잠시 후 다시 시도해주세요.'
            : detail;
        throw ApiException(
          response.statusCode == 401
              ? '로그인이 만료되었습니다. 다시 로그인해주세요.'
              : detailMessage is String && detailMessage.isNotEmpty
              ? detailMessage
              : detailMessage is List
              ? '입력한 정보를 확인해주세요.'
              : 'API 요청에 실패했습니다. (${response.statusCode})',
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
        'group_profile_image_url': ?profileImageUrl,
      },
    ),
  );

  Future<Map<String, dynamic>> join(
    AuthTokens tokens,
    String inviteCode,
  ) async => _map(
    await _api.post('/groups/join', tokens, body: {'invite_code': inviteCode}),
  );

  Future<Map<String, dynamic>> detail(AuthTokens tokens, int groupId) async {
    final response = _map(await _api.get('/groups/$groupId', tokens));

    // Some API gateways wrap a single resource in `data` and/or `group`.
    // Keep the app compatible with both the deployed direct response and those
    // envelopes instead of treating a valid group as if it had no patient.
    var detail = response;
    final data = detail['data'];
    if (data is Map<String, dynamic>) detail = data;
    final group = detail['group'];
    if (group is Map<String, dynamic>) {
      detail = {...detail, ...group}..remove('group');
    }
    return detail;
  }

  Future<List<Map<String, dynamic>>> members(
    AuthTokens tokens,
    int groupId,
  ) async => _maps(await _api.get('/groups/$groupId/members', tokens));

  Future<Map<String, dynamic>> update(
    AuthTokens tokens,
    int groupId,
    Map<String, dynamic> body,
  ) async => _map(await _api.patch('/groups/$groupId', tokens, body));

  Future<void> leave(AuthTokens tokens, int groupId) async =>
      _api.delete('/groups/$groupId/members/me', tokens);

  Future<Map<String, dynamic>> updateMembership(
    AuthTokens tokens,
    int groupId, {
    String? patientsNickname,
    String? patientRelation,
  }) async => _map(
    await _api.patch('/groups/$groupId/members/me', tokens, {
      'patients_nickname': ?patientsNickname,
      'patient_relation': ?patientRelation,
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
}

class DiaryAnalysisApi {
  DiaryAnalysisApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> fetch(
    AuthTokens tokens, {
    required int groupId,
    required DateTime fromDate,
    required DateTime toDate,
    required String period,
  }) async {
    final query = Uri(
      queryParameters: {
        'period': period,
        'group_id': '$groupId',
        'from_date': _date(fromDate),
        'to_date': _date(toDate),
      },
    ).query;
    return _map(await _api.get('/diaries/analysis?$query', tokens));
  }
}

class MediaApi {
  MediaApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> uploadDiary(
    AuthTokens tokens,
    int diaryId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
    int? duration,
    int sortOrder = 0,
  }) async => _map(
    await _api.upload(
      '/diaries/$diaryId/media',
      tokens,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {
        'sort_order': '$sortOrder',
        if (duration != null) 'duration': '$duration',
      },
    ),
  );

  Future<Map<String, dynamic>> uploadMemory(
    AuthTokens tokens,
    int recordId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
    int? duration,
    int sortOrder = 0,
  }) async => _map(
    await _api.upload(
      '/memory-records/$recordId/media',
      tokens,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: {
        'sort_order': '$sortOrder',
        if (duration != null) 'duration': '$duration',
      },
    ),
  );
}

class UserApi {
  UserApi(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> profile(AuthTokens tokens) async =>
      _map(await _api.get('/users/me', tokens));

  Future<Map<String, dynamic>> updateProfile(
    AuthTokens tokens,
    Map<String, dynamic> body,
  ) async => _map(await _api.put('/users/me', tokens, body: body));

  Future<void> updatePassword(AuthTokens tokens, String password) async {
    await _api.put('/users/me/password', tokens, body: {'password': password});
  }

  Future<void> deleteAccount(AuthTokens tokens) async {
    await _api.delete('/users/me', tokens);
  }
}

class LetterApi {
  LetterApi(this._api);
  final ApiService _api;

  Future<List<Map<String, dynamic>>> list(
    AuthTokens tokens,
    int groupId, {
    bool sent = false,
  }) async {
    final query = Uri(
      queryParameters: {
        'group_id': '$groupId',
        'box_type': sent ? 'sent' : 'inbox',
      },
    ).query;
    return _maps(await _api.get('/letters?$query', tokens));
  }

  Future<Map<String, dynamic>> send(
    AuthTokens tokens, {
    required int groupId,
    required String content,
    String? receiverUserId,
  }) async => _map(
    await _api.post(
      '/letters',
      tokens,
      body: {
        'group_id': groupId,
        'receiver_user_id': receiverUserId,
        'content': content,
      },
      expectedStatus: 201,
    ),
  );

  Future<Map<String, dynamic>> detail(AuthTokens tokens, int letterId) async =>
      _map(await _api.get('/letters/$letterId', tokens));

  Future<void> remove(AuthTokens tokens, int letterId) =>
      _api.delete('/letters/$letterId', tokens);
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
      '/care-notes/daily-conditions',
      tokens,
      body: {'patient_id': patientId, ...body},
    ),
  );

  Future<List<Map<String, dynamic>>> dailyConditions(
    AuthTokens tokens,
    int patientId, {
    DateTime? recordDate,
  }) async => _maps(
    await _api.get(
      '/care-notes/daily-conditions?patient_id=$patientId${recordDate == null ? '' : '&start_date=${_date(recordDate)}&end_date=${_date(recordDate)}'}',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> updateDailyCondition(
    AuthTokens tokens,
    int patientId,
    int conditionId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.patch('/care-notes/daily-conditions/$conditionId', tokens, body),
  );

  Future<Map<String, dynamic>> createBehaviorLog(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post(
      '/care-notes/behavior-logs',
      tokens,
      body: {'patient_id': patientId, ...body},
    ),
  );

  Future<List<Map<String, dynamic>>> behaviorLogs(
    AuthTokens tokens,
    int patientId,
  ) async => _maps(
    await _api.get('/care-notes/behavior-logs?patient_id=$patientId', tokens),
  );

  Future<Map<String, dynamic>> addMedication(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post(
      '/care-notes/medications',
      tokens,
      body: {'patient_id': patientId, ...body},
    ),
  );

  Future<List<Map<String, dynamic>>> medications(
    AuthTokens tokens,
    int patientId, {
    bool activeOnly = false,
  }) async => _maps(
    await _api.get(
      '/care-notes/medications?patient_id=$patientId${activeOnly ? '&is_active=true' : ''}',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> upsertIntake(
    AuthTokens tokens,
    int medicationId,
    DateTime logDate,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post(
      '/care-notes/medication-intake-logs',
      tokens,
      body: {
        'medication_id': medicationId,
        'log_date': _date(logDate),
        ...body,
      },
    ),
  );

  Future<List<Map<String, dynamic>>> intakeLogs(
    AuthTokens tokens,
    int patientId,
  ) async => _maps(
    await _api.get(
      '/care-notes/medication-intake-logs?patient_id=$patientId',
      tokens,
    ),
  );

  Future<Map<String, dynamic>> createHospitalVisit(
    AuthTokens tokens,
    int patientId,
    Map<String, dynamic> body,
  ) async => _map(
    await _api.post(
      '/care-notes/hospital-visits',
      tokens,
      body: {'patient_id': patientId, ...body},
    ),
  );

  Future<List<Map<String, dynamic>>> hospitalVisits(
    AuthTokens tokens,
    int patientId,
  ) async => _maps(
    await _api.get('/care-notes/hospital-visits?patient_id=$patientId', tokens),
  );
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is List) return value.cast<Map<String, dynamic>>();
  throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
}
