class ApiConfig {
  ApiConfig._();

  static const bool isDemoMode = bool.fromEnvironment(
    'VARATIA_DEMO_MODE',
    defaultValue: false,
  );

  static const String _overrideBaseUrl = String.fromEnvironment(
    'VARATIA_API_BASE_URL',
  );

  static const String _defaultBaseUrl = 'https://amarthikanaa.com/';

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_overrideBaseUrl);
    }

    return _normalizeBaseUrl(_defaultBaseUrl);
  }

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
