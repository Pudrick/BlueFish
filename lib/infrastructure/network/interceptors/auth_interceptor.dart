import 'package:bluefish/infrastructure/auth/cookie_manager_dev.dart';
import 'package:bluefish/infrastructure/network/api_config.dart';
import 'package:bluefish/infrastructure/network/interceptors/request_interceptor.dart';
import 'package:http/http.dart' as http;

/// Interceptor that adds User-Agent and Cookie headers to requests.
class AuthInterceptor implements RequestInterceptor {
  final CookieManager _cookieManager;

  AuthInterceptor(this._cookieManager);

  @override
  Future<void> onRequest(http.BaseRequest request) async {
    request.headers['user-agent'] = ApiConfig.userAgent;
    request.headers['cookie'] = _cookieManager.getCookiesSync();
  }
}
