import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/network/interceptors/auth_interceptor.dart';
import 'package:bluefish/network/interceptors/request_interceptor.dart';
import 'package:http/http.dart' as http;

/// Unified HTTP client with interceptor support.
class AppHttpClient extends http.BaseClient {
  final http.Client _inner;
  final List<RequestInterceptor> _interceptors;

  AppHttpClient._({
    required http.Client inner,
    required List<RequestInterceptor> interceptors,
  }) : _inner = inner,
       _interceptors = interceptors;

  /// Creates a client with default auth interceptor.
  factory AppHttpClient.withAuth(AuthSessionManager authSessionManager) {
    return AppHttpClient._(
      inner: http.Client(),
      interceptors: [AuthInterceptor(authSessionManager)],
    );
  }

  /// Creates a client with custom interceptors.
  factory AppHttpClient.withInterceptors(
    List<RequestInterceptor> interceptors,
  ) {
    return AppHttpClient._(inner: http.Client(), interceptors: interceptors);
  }

  /// Creates a bare client without interceptors (for non-authenticated requests).
  factory AppHttpClient.bare() {
    return AppHttpClient._(inner: http.Client(), interceptors: []);
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
