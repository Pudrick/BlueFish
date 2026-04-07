import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/network/interceptors/request_interceptor.dart';
import 'package:http/http.dart' as http;

/// Interceptor that adds User-Agent and Cookie headers to requests.
class AuthInterceptor implements RequestInterceptor {
  final AuthSessionManager _authSessionManager;

  AuthInterceptor(this._authSessionManager);

  @override
  Future<void> onRequest(http.BaseRequest request) async {
    request.headers['user-agent'] = ApiConfig.userAgent;
    final cookies = _authSessionManager
        .getCookieHeaderForUriSync(request.url)
        .trim();
    if (cookies.isEmpty) {
      return;
    }

    request.headers['cookie'] = cookies;
  }
}
