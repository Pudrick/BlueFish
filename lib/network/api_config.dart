import 'package:bluefish/network/api_path_settings.dart';

/// Centralized API configuration.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://bbs.mobileapi.hupu.com';
  static String? _apiVersionOverride;

  static String get defaultApiVersion => apiVersionSegment;

  static String get apiVersion => _apiVersionOverride ?? defaultApiVersion;

  static void setApiVersionOverride(String? value) {
    final normalizedValue = value?.trim();
    _apiVersionOverride = normalizedValue == null || normalizedValue.isEmpty
        ? null
        : normalizedValue;
  }

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36';

  /// Builds a full API path with gateway and API-version path segments.
  static String apiPath(String path, {String gatewayVersion = '1'}) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$gatewayVersion/$apiVersion/$normalizedPath';
  }
}
