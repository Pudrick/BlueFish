import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/current_user_identity.dart';
import 'package:bluefish/models/current_user_profile.dart';

class CurrentUserIdentityResolver {
  const CurrentUserIdentityResolver();

  CurrentUserIdentity resolve({
    required AuthSessionManager authSessionManager,
    required CurrentUserProfile? currentUserProfile,
  }) {
    if (!authSessionManager.isLoggedIn) {
      return CurrentUserIdentity.signedOut;
    }

    return CurrentUserIdentity(
      isLoggedIn: true,
      euid: currentUserProfile?.euid,
      puid: resolveCurrentUserPuidFromCookies(
        authSessionManager.getCookiesSync(),
      ),
    );
  }

  String? resolveCurrentUserPuidFromCookies(String cookies) {
    final normalizedCookies = cookies.trim();
    if (normalizedCookies.isEmpty) {
      return null;
    }

    const cookieKeyCandidates = <String>['uid', 'puid', 'u', 'g'];
    for (final key in cookieKeyCandidates) {
      final parsedPuid = _extractNumericIdentityFromCookie(
        normalizedCookies,
        key,
      );
      if (parsedPuid != null) {
        return parsedPuid;
      }
    }

    return null;
  }

  String? _extractNumericIdentityFromCookie(String cookies, String key) {
    final match = RegExp(
      '(?:^|;\\s*)${RegExp.escape(key)}=([^;]+)',
    ).firstMatch(cookies);
    if (match == null) {
      return null;
    }

    final decodedValue = Uri.decodeComponent(match.group(1)!);
    final separatorIndex = decodedValue.indexOf('|');
    final rawId = separatorIndex >= 0
        ? decodedValue.substring(0, separatorIndex)
        : decodedValue;
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d+$').hasMatch(normalizedId)) {
      return null;
    }

    return normalizedId;
  }
}
