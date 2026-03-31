import 'package:http/http.dart' as http;

/// Base interface for request interceptors.
abstract class RequestInterceptor {
  /// Called before the request is sent. Modify the request as needed.
  Future<void> onRequest(http.BaseRequest request);
}
