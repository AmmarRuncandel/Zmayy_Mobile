class AppConfig {
  AppConfig._();

  static const String _lockedBaseUrl = 'https://zmayy.vercel.app';

  static String get backendBaseUrl {
    // The mobile client must always talk to the deployed backend.
    // If a compile-time value is provided, normalize it but keep a strict fallback.
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    final candidate = fromEnv.trim();
    final normalized = _normalizeBaseUrl(candidate);
    if (normalized == null) return _lockedBaseUrl;
    if (normalized != _lockedBaseUrl) return _lockedBaseUrl;
    return normalized;
  }

  static String? _normalizeBaseUrl(String value) {
    if (value.isEmpty) return null;
    final trimmed = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute) return null;
    return trimmed;
  }
}