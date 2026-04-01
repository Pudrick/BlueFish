import 'package:bluefish/userdata/user_settings.dart';

/// Centralized API configuration.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://bbs.mobileapi.hupu.com';

  static String get appVersion => appVersionNumber;

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36';

  /// Builds a full API path with version prefix.
  static String apiPath(String path) => '$baseUrl/1/$appVersion/$path';
}
