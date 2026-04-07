import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_cookie_jar.dart';

const String debugCookieDefineName = 'BLUEFISH_DEBUG_COOKIE';
const String _debugCookieFromEnvironment = String.fromEnvironment(
  debugCookieDefineName,
);
const String startWithoutAuthDefineName = 'BLUEFISH_START_WITHOUT_AUTH';
const bool _startWithoutAuthFromEnvironment = bool.fromEnvironment(
  startWithoutAuthDefineName,
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
  final bool _startWithoutAuth;

  Future<void>? _initialization;
  bool _isInitialized = false;

  AuthCookieJar _loginCookieJar = AuthCookieJar.empty;
  String? _debugOverrideCookies;
  String _activeCookies = '';
  AuthCookieSource _activeSource = AuthCookieSource.none;

  AuthSessionManager({
    AuthCookiePersistence? loginPersistence,
    AuthCookiePersistence? debugOverridePersistence,
    String? debugCookieFromEnvironmentOverride,
    bool? startWithoutAuthOverride,
  }) : _loginPersistence = loginPersistence ?? SecureAuthCookiePersistence(),
       _debugOverridePersistence =
           debugOverridePersistence ??
           (kDebugMode
               ? SharedPreferencesAuthCookiePersistence(
                   storageKey: debugOverrideStorageKey,
                 )
               : null),
       _debugCookieFromEnvironmentOverride = debugCookieFromEnvironmentOverride,
       _startWithoutAuth =
           startWithoutAuthOverride ?? _startWithoutAuthFromEnvironment {
    _resolveActiveCookies();
  }

  bool get isInitialized => _isInitialized;

  bool get startWithoutAuth => _startWithoutAuth;

  bool get canUseDebugOverride =>
      kDebugMode && _debugOverridePersistence != null;

  AuthCookieSource get activeSource => _activeSource;

  bool get isLoggedIn => _activeSource != AuthCookieSource.none;

  String? get activeCookies => _activeCookies.isEmpty ? null : _activeCookies;

  String? get loginCookies => _loginCookieJar.buildAllCookiesHeader().isEmpty
      ? null
      : _loginCookieJar.buildAllCookiesHeader();

  List<AuthCookieEntry> get loginCookieEntries => _loginCookieJar.cookies;

  String? get debugOverrideCookies => _debugOverrideCookies;

  String? get debugCookieFromEnvironment {
    if (_startWithoutAuth) {
      return null;
    }
    return _normalizeCookies(
      _debugCookieFromEnvironmentOverride ?? _debugCookieFromEnvironment,
    );
  }

  Future<void> initialize() {
    return _initialization ??= _loadPersistedState();
  }

  String getCookiesSync() => _activeCookies;

  String getCookieHeaderForUriSync(Uri uri) {
    return switch (_activeSource) {
      AuthCookieSource.login => _buildLoginCookieHeaderForUri(uri),
      _ => _activeCookies,
    };
  }

  bool hasCookieNamedSync(String name) {
    return switch (_activeSource) {
      AuthCookieSource.login => _loginCookieJar.containsCookieNamed(name),
      _ => _headerContainsCookie(_activeCookies, name),
    };
  }

  Future<void> saveLoginCookies(String cookies) async {
    final nextJar = AuthCookieJar.fromHeader(cookies);
    if (nextJar.isEmpty) {
      await clearLoginCookies();
      return;
    }

    _loginCookieJar = nextJar;
    await _loginPersistence.write(nextJar.toPersistenceValue()!);
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> saveLoginCookieEntries(Iterable<AuthCookieEntry> cookies) async {
    final nextJar = AuthCookieJar.fromCookies(cookies);
    if (nextJar.isEmpty) {
      await clearLoginCookies();
      return;
    }

    _loginCookieJar = nextJar;
    await _loginPersistence.write(nextJar.toPersistenceValue()!);
    _resolveActiveCookies();
    notifyListeners();
  }

  Future<void> clearLoginCookies() async {
    _loginCookieJar = AuthCookieJar.empty;
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
    if (!_startWithoutAuth) {
      _loginCookieJar = AuthCookieJar.fromPersistedValue(
        await _loginPersistence.read(),
      );
      if (_debugOverridePersistence != null) {
        _debugOverrideCookies = _normalizeCookies(
          await _debugOverridePersistence.read(),
        );
      }
    }
    _resolveActiveCookies();
    _isInitialized = true;
    notifyListeners();
  }

  String _buildLoginCookieHeaderForUri(Uri uri) {
    if (_isHupuHost(uri.host)) {
      return _loginCookieJar.buildAllCookiesHeader();
    }

    return _loginCookieJar.buildCookieHeaderForUri(uri);
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

    if (!_loginCookieJar.isEmpty) {
      _activeCookies = _loginCookieJar.buildAllCookiesHeader();
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

  bool _headerContainsCookie(String header, String name) {
    final normalizedName = name.trim();
    if (header.trim().isEmpty || normalizedName.isEmpty) {
      return false;
    }

    for (final segment in header.split(';')) {
      final separatorIndex = segment.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      if (segment.substring(0, separatorIndex).trim() == normalizedName) {
        return true;
      }
    }
    return false;
  }

  bool _isHupuHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    return normalizedHost == 'hupu.com' || normalizedHost.endsWith('.hupu.com');
  }
}
