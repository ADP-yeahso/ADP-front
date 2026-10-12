class ApiConfig {
  ApiConfig._();

  // 별도 설정 없이 실행하거나 배포해도 공개된 백엔드에 연결합니다.
  static const _defaultBaseUrl =
      'https://adp-back-production.up.railway.app/api/v1';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    return _defaultBaseUrl;
  }
}
