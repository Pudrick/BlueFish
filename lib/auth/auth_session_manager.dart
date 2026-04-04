import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String debugCookieDefineName = 'BLUEFISH_DEBUG_COOKIE';
const String _debugCookieFromEnvironment = String.fromEnvironment(
  debugCookieDefineName,
);

enum AuthCookieSource {
  none,
  login,
  debugOverride,
  debugDefine;

  String get label => switch (this) {
    AuthCookieSource.none => '未设置',
    AuthCookieSource.login => '登录会话',
    AuthCookieSource.debugOverride => '本地调试覆盖',
    AuthCookieSource.debugDefine => '--dart-define 调试注入',
  };
}

abstract class AuthCookiePersistence {
  Future<String?> read();

  Future<void> write(String cookies);

  Future<void> clear();
}

class SecureAuthCookiePersistence implements AuthCookiePersistence {
  static const String _storageKey = 'auth_cookies';

  final FlutterSecureStorage _storage;

  SecureAuthCookiePersistence({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read() {
    return _storage.read(key: _storageKey);
  }

  @override
  Future<void> write(String cookies) {
    return _storage.write(key: _storageKey, value: cookies);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _storageKey);
  }
}

class SharedPreferencesAuthCookiePersistence implements AuthCookiePersistence {
  final String storageKey;
  SharedPreferences? _prefs;

  SharedPreferencesAuthCookiePersistence({
    required this.storageKey,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<String?> read() async {
    final prefs = await _preferences;
    return prefs.getString(storageKey);
  }

  @override
  Future<void> write(String cookies) async {
    final prefs = await _preferences;
    await prefs.setString(storageKey, cookies);
  }

  @override
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(storageKey);
  }
}

class AuthSessionManager extends ChangeNotifier {
  static const String debugOverrideStorageKey = 'debug.auth_cookies_override';

  final AuthCookiePersistence _loginPersistence;
  final AuthCookiePersistence? _debugOverridePersistence;
  final String? _debugCookieFromEnvironmentOverride;

  Future<void>? _initialization;
  bool _isInitialized = false;

  String? _loginCookies;
  String? _debugOverrideCookies;
  String _activeCookies = '';
  AuthCookieSource _activeSource = AuthCookieSource.none;

  AuthSessionManager({
    AuthCookiePersistence? loginPersistence,
    AuthCookiePersistence? debugOverridePersistence,
    String? debugCookieFromEnvironmentOverride,
  }) : _loginPersistence = loginPersistence ?? SecureAuthCookiePersistence(),
       _debugOverridePersistence =
           debugOverridePersistence ??
           (kDebugMode
               ? SharedPreferencesAuthCookiePersistence(
                   storageKey: debugOverrideStorageKey,
                 )
               : null),
       _debugCookieFromEnvironmentOverride =
           debugCookieFromEnvironmentOverride {
    _resolveActiveCookies();
  }

  bool get isInitialized => _isInitialized;

  bool get canUseDebugOverride =>
      kDebugMode && _debugOverridePersistence != null;

  AuthCookieSource get activeSource => _activeSource;

  bool get isLoggedIn => _activeSource != AuthCookieSource.none;

  String? get activeCookies => _activeCookies.isEmpty ? null : _activeCookies;

  String? get loginCookies => _loginCookies;

  String? get debugOverrideCookies => _debugOverrideCookies;

  String? get debugCookieFromEnvironment => _normalizeCookies(
    _debugCookieFromEnvironmentOverride ?? _debugCookieFromEnvironment,
  );

  Future<void> initialize() {
    return _initialization ??= _loadPersistedState();
  }

  String getCookiesSync() => _activeCookies;

  Future<void> saveLoginCookies(String cookies) async {
    final normalizedCookies = _normalizeCookies(cookies);
    if (normalizedCookies == null) {
      await clearLoginCookies();
      return;
    }

    _loginCookies = normalizedCookies;
    await _loginPersistence.write(normalizedCookies);
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> clearLoginCookies() async {
    _loginCookies = null;
    await _loginPersistence.clear();
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> saveDebugOverrideCookies(String cookies) async {
    if (!canUseDebugOverride) {
      return;
    }

    final normalizedCookies = _normalizeCookies(cookies);
    if (normalizedCookies == null) {
      await clearDebugOverrideCookies();
      return;
    }

    _debugOverrideCookies = normalizedCookies;
    await _debugOverridePersistence!.write(normalizedCookies);
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> clearDebugOverrideCookies() async {
    if (!canUseDebugOverride) {
      return;
    }

    _debugOverrideCookies = null;
    await _debugOverridePersistence!.clear();
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> _loadPersistedState() async {
    _loginCookies = _normalizeCookies(await _loginPersistence.read());
    if (_debugOverridePersistence != null) {
      _debugOverrideCookies = _normalizeCookies(
        await _debugOverridePersistence.read(),
      );
    }
    _resolveActiveCookies();
    _isInitialized = true;
    notifyListeners();
  }

  void _resolveActiveCookies() {
    final envCookies = debugCookieFromEnvironment;

    if (envCookies != null) {
      _activeCookies = envCookies;
      _activeSource = AuthCookieSource.debugDefine;
      return;
    }

    if (_debugOverrideCookies != null) {
      _activeCookies = _debugOverrideCookies!;
      _activeSource = AuthCookieSource.debugOverride;
      return;
    }

    if (_loginCookies != null) {
      _activeCookies = _loginCookies!;
      _activeSource = AuthCookieSource.login;
      return;
    }

    _activeCookies = '';
    _activeSource = AuthCookieSource.none;
  }

  String? _normalizeCookies(String? cookies) {
    final normalizedCookies = cookies?.trim();
    if (normalizedCookies == null || normalizedCookies.isEmpty) {
      return null;
    }
    return normalizedCookies;
  }
}
