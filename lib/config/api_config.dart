class ApiConfig {
  ApiConfig._();

  /// 배포 백엔드 주소.
  ///
  /// `--dart-define=API_BASE_URL=...`를 전달하면 로컬 백엔드 등으로
  /// 덮어쓸 수 있지만, 별도 설정 없이 실행해도 실제 API 서버를 바라본다.
  static const productionBaseUrl =
      'https://adp-back-production.up.railway.app/api/v1';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    return productionBaseUrl;
  }
}
