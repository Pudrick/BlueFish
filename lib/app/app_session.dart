import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/network/http_client.dart';

class AppSession {
  final AuthSessionManager authSessionManager;
  final AppHttpClient httpClient;

  const AppSession._({
    required this.authSessionManager,
    required this.httpClient,
  });

  static Future<AppSession> bootstrap() async {
    final authSessionManager = AuthSessionManager();
    await authSessionManager.initialize();
    final httpClient = AppHttpClient.withAuth(authSessionManager);
    return AppSession._(
      authSessionManager: authSessionManager,
      httpClient: httpClient,
    );
  }
}
