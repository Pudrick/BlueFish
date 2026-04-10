import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:flutter/foundation.dart';

@immutable
class CurrentUserIdentity {
  final bool isLoggedIn;
  final int? euid;
  final String? puid;

  const CurrentUserIdentity({
    required this.isLoggedIn,
    required this.euid,
    required this.puid,
  });

  static const CurrentUserIdentity signedOut = CurrentUserIdentity(
    isLoggedIn: false,
    euid: null,
    puid: null,
  );

  @override
  bool operator ==(Object other) {
    return other is CurrentUserIdentity &&
        other.isLoggedIn == isLoggedIn &&
        other.euid == euid &&
        other.puid == puid;
  }

  @override
  int get hashCode => Object.hash(isLoggedIn, euid, puid);
}

class CurrentUserIdentityController extends ChangeNotifier {
  AuthSessionManager? _authSessionManager;
  CurrentUserProfileViewModel? _currentUserProfileViewModel;
  CurrentUserIdentity _identity = CurrentUserIdentity.signedOut;

  CurrentUserIdentity get identity => _identity;
  bool get isLoggedIn => _identity.isLoggedIn;
  int? get currentUserEuid => _identity.euid;
  String? get currentUserPuid => _identity.puid;

  void update({
    required AuthSessionManager authSessionManager,
    required CurrentUserProfileViewModel currentUserProfileViewModel,
  }) {
    if (!identical(_authSessionManager, authSessionManager)) {
      _authSessionManager?.removeListener(_handleDependencyChanged);
      _authSessionManager = authSessionManager;
      _authSessionManager?.addListener(_handleDependencyChanged);
    }

    if (!identical(_currentUserProfileViewModel, currentUserProfileViewModel)) {
      _currentUserProfileViewModel?.removeListener(_handleDependencyChanged);
      _currentUserProfileViewModel = currentUserProfileViewModel;
      _currentUserProfileViewModel?.addListener(_handleDependencyChanged);
    }

    _recomputeIdentity();
  }

  void _handleDependencyChanged() {
    _recomputeIdentity();
  }

  void _recomputeIdentity() {
    final authSessionManager = _authSessionManager;
    if (authSessionManager == null || !authSessionManager.isLoggedIn) {
      if (_identity != CurrentUserIdentity.signedOut) {
        _identity = CurrentUserIdentity.signedOut;
        notifyListeners();
      }
      return;
    }

    final nextIdentity = CurrentUserIdentity(
      isLoggedIn: true,
      euid: _currentUserProfileViewModel?.profile?.euid,
      puid: resolveCurrentUserPuidFromCookies(
        authSessionManager.getCookiesSync(),
      ),
    );
    if (nextIdentity == _identity) {
      return;
    }

    _identity = nextIdentity;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSessionManager?.removeListener(_handleDependencyChanged);
    _currentUserProfileViewModel?.removeListener(_handleDependencyChanged);
    super.dispose();
  }
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
