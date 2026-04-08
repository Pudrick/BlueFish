import 'package:bluefish/models/current_user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentUserProfileStore {
  static const String _usernameKey = 'current_user_profile.username';
  static const String _avatarUrlKey = 'current_user_profile.avatar_url';
  static const String _euidKey = 'current_user_profile.euid';
  static const String _updatedAtKey = 'current_user_profile.updated_at_ms';

  SharedPreferences? _prefs;

  CurrentUserProfileStore({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<CurrentUserProfile?> load() async {
    final prefs = await _preferences;
    final username = prefs.getString(_usernameKey);
    final euid = prefs.getInt(_euidKey);

    if (username == null || euid == null) {
      return null;
    }

    return CurrentUserProfile(
      username: username,
      avatarUrl: prefs.getString(_avatarUrlKey) ?? '',
      euid: euid,
      updatedAtEpochMs: prefs.getInt(_updatedAtKey) ?? 0,
    );
  }

  Future<void> save(CurrentUserProfile profile) async {
    final prefs = await _preferences;

    await prefs.setString(_usernameKey, profile.username);
    await prefs.setString(_avatarUrlKey, profile.avatarUrl);
    await prefs.setInt(_euidKey, profile.euid);
    await prefs.setInt(_updatedAtKey, profile.updatedAtEpochMs);
  }

  Future<void> clear() async {
    final prefs = await _preferences;

    await prefs.remove(_usernameKey);
    await prefs.remove(_avatarUrlKey);
    await prefs.remove(_euidKey);
    await prefs.remove(_updatedAtKey);
  }
}
