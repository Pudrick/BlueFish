import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/current_user_identity.dart';
import 'package:bluefish/auth/current_user_identity_resolver.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:flutter/foundation.dart';

class CurrentUserIdentityController extends ChangeNotifier {
  AuthSessionManager? _authSessionManager;
  CurrentUserProfileViewModel? _currentUserProfileViewModel;
  CurrentUserIdentityResolver? _resolver;
  CurrentUserIdentity _identity = CurrentUserIdentity.signedOut;

  CurrentUserIdentity get identity => _identity;
  bool get isLoggedIn => _identity.isLoggedIn;
  int? get currentUserEuid => _identity.euid;
  String? get currentUserPuid => _identity.puid;

  void update({
    required AuthSessionManager authSessionManager,
    required CurrentUserProfileViewModel currentUserProfileViewModel,
    required CurrentUserIdentityResolver resolver,
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

    _resolver = resolver;
    _recomputeIdentity();
  }

  void _handleDependencyChanged() {
    _recomputeIdentity();
  }

  void _recomputeIdentity() {
    final authSessionManager = _authSessionManager;
    final resolver = _resolver;
    if (authSessionManager == null || resolver == null) {
      if (_identity != CurrentUserIdentity.signedOut) {
        _identity = CurrentUserIdentity.signedOut;
        notifyListeners();
      }
      return;
    }

    final nextIdentity = resolver.resolve(
      authSessionManager: authSessionManager,
      currentUserProfile: _currentUserProfileViewModel?.profile,
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
