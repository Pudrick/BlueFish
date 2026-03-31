import 'package:shared_preferences/shared_preferences.dart';

/// Manages cookie storage for authentication.
/// 
/// Users must provide their own cookies via [saveCookies] or the app
/// will prompt for cookie input.
class CookieManager {
  static const String _storageKey = 'auth_cookies';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Gets cookies from storage. Returns null if no cookies are saved.
  Future<String?> getCookies() async {
    final prefs = await _preferences;
    return prefs.getString(_storageKey);
  }

  /// Gets cookies synchronously if preferences are already loaded.
  /// Returns null if not yet initialized or no cookies saved.
  String? getCookiesSync() {
    return _prefs?.getString(_storageKey);
  }

  /// Saves user-provided cookies.
  Future<void> saveCookies(String cookies) async {
    final prefs = await _preferences;
    await prefs.setString(_storageKey, cookies);
  }

  /// Clears saved cookies.
  Future<void> clearCookies() async {
    final prefs = await _preferences;
    await prefs.remove(_storageKey);
  }

  /// Checks if user has cookies saved.
  Future<bool> hasCookies() async {
    final prefs = await _preferences;
    return prefs.containsKey(_storageKey);
  }

  /// Pre-loads preferences for sync access later.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
}
