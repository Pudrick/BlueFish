import 'package:bluefish/infrastructure/auth/cookie_manager_dev.dart';
import 'package:bluefish/infrastructure/network/interceptors/auth_interceptor.dart';
import 'package:bluefish/infrastructure/network/interceptors/request_interceptor.dart';
import 'package:http/http.dart' as http;

/// Unified HTTP client with interceptor support.
class AppHttpClient extends http.BaseClient {
  final http.Client _inner;
  final List<RequestInterceptor> _interceptors;

  AppHttpClient._({
    required http.Client inner,
    required List<RequestInterceptor> interceptors,
  })  : _inner = inner,
        _interceptors = interceptors;

  /// Creates a client with default auth interceptor.
  factory AppHttpClient.withAuth(CookieManager cookieManager) {
    return AppHttpClient._(
      inner: http.Client(),
      interceptors: [AuthInterceptor(cookieManager)],
    );
  }

  /// Creates a client with custom interceptors.
  factory AppHttpClient.withInterceptors(
      List<RequestInterceptor> interceptors) {
    return AppHttpClient._(
      inner: http.Client(),
      interceptors: interceptors,
    );
  }

  /// Creates a bare client without interceptors (for non-authenticated requests).
  factory AppHttpClient.bare() {
    return AppHttpClient._(
      inner: http.Client(),
      interceptors: [],
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Apply all interceptors
    for (final interceptor in _interceptors) {
      await interceptor.onRequest(request);
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Global singleton for the default HTTP client.
/// Must call [initializeHttpClient] before use.
AppHttpClient? _defaultClient;
CookieManager? _cookieManager;

bool _initialized = false;

/// Initializes the global HTTP client. Call this at app startup.
/// This enables async cookie loading from SharedPreferences.
Future<void> initializeHttpClient() async {
  if (_initialized) return;
  _cookieManager = CookieManager();
  await _cookieManager!.initialize();
  _defaultClient = AppHttpClient.withAuth(_cookieManager!);
  _initialized = true;
}

/// Synchronously initializes the HTTP client if not already done.
/// Uses default cookies (no SharedPreferences loading).
void _ensureInitializedSync() {
  if (_initialized) return;
  _cookieManager = CookieManager();
  _defaultClient = AppHttpClient.withAuth(_cookieManager!);
  _initialized = true;
}

/// Gets the global HTTP client instance.
/// Auto-initializes synchronously if needed (uses default cookies).
AppHttpClient get httpClient {
  _ensureInitializedSync();
  return _defaultClient!;
}

/// Gets the global cookie manager instance.
CookieManager get cookieManager {
  _ensureInitializedSync();
  return _cookieManager!;
}
