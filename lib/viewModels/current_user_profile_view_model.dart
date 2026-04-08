import 'dart:async';

import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/models/current_user_profile.dart';
import 'package:bluefish/services/user_home/current_user_profile_service.dart';
import 'package:bluefish/userdata/current_user_profile_store.dart';
import 'package:flutter/foundation.dart';

class CurrentUserProfileViewModel extends ChangeNotifier {
  static const Duration defaultRefreshDebounceWindow = Duration(seconds: 2);

  final AuthSessionManager _authSessionManager;
  final CurrentUserProfileService _service;
  final CurrentUserProfileStore _store;
  final Duration _refreshDebounceWindow;

  Future<void>? _initialization;
  Future<void>? _inFlightRefresh;

  bool _isDisposed = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool _lastLoggedInState = false;
  DateTime? _lastRefreshAt;

  CurrentUserProfile? _profile;
  String? _lastErrorMessage;

  CurrentUserProfileViewModel({
    required AuthSessionManager authSessionManager,
    CurrentUserProfileService? service,
    CurrentUserProfileStore? store,
    Duration refreshDebounceWindow = defaultRefreshDebounceWindow,
  }) : _authSessionManager = authSessionManager,
       _service = service ?? CurrentUserProfileHttpService(),
       _store = store ?? CurrentUserProfileStore(),
       _refreshDebounceWindow = refreshDebounceWindow,
       _lastLoggedInState = authSessionManager.isLoggedIn {
    _authSessionManager.addListener(_handleAuthStateChanged);
  }

  bool get isInitialized => _isInitialized;

  bool get isLoading => _isLoading;

  CurrentUserProfile? get profile => _profile;

  String? get lastErrorMessage => _lastErrorMessage;

  Future<void> initialize() {
    return _initialization ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    final cachedProfile = await _store.load();
    if (_isDisposed) {
      return;
    }

    if (_authSessionManager.isLoggedIn) {
      _profile = cachedProfile;
    } else {
      _profile = null;
      if (cachedProfile != null) {
        await _store.clear();
      }
    }

    _isInitialized = true;
    notifyListeners();

    if (_authSessionManager.isLoggedIn) {
      unawaited(refreshProfile(force: true));
    }
  }

  Future<void> refreshProfile({bool force = false}) async {
    if (!_authSessionManager.isLoggedIn) {
      return;
    }

    if (_inFlightRefresh != null) {
      await _inFlightRefresh;
      return;
    }

    final now = DateTime.now();
    final lastRefreshAt = _lastRefreshAt;
    if (!force &&
        lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _refreshDebounceWindow) {
      return;
    }

    _lastRefreshAt = now;
    final refreshFuture = _refreshProfileInternal();
    _inFlightRefresh = refreshFuture;
    await refreshFuture;
  }

  Future<void> _refreshProfileInternal() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final freshProfile = await _service.fetchCurrentUserProfile();
      await _store.save(freshProfile);

      _profile = freshProfile;
      _lastErrorMessage = null;
    } catch (error, stackTrace) {
      _lastErrorMessage = '用户资料刷新失败';
      debugPrint('Failed to refresh current user profile: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Keep the in-memory profile as fallback. If it is empty, try persisted cache.
      _profile ??= await _store.load();
    } finally {
      _isLoading = false;
      _inFlightRefresh = null;
      _safeNotifyListeners();
    }
  }

  void _handleAuthStateChanged() {
    final isLoggedIn = _authSessionManager.isLoggedIn;
    if (isLoggedIn == _lastLoggedInState) {
      return;
    }

    _lastLoggedInState = isLoggedIn;
    if (isLoggedIn) {
      unawaited(refreshProfile(force: true));
      return;
    }

    unawaited(_clearProfile(clearStorage: true));
  }

  Future<void> _clearProfile({required bool clearStorage}) async {
    if (clearStorage) {
      await _store.clear();
    }

    _profile = null;
    _lastErrorMessage = null;
    _lastRefreshAt = null;
    _safeNotifyListeners();
  }

  @visibleForTesting
  Future<void> waitForIdle() async {
    final inFlightRefresh = _inFlightRefresh;
    if (inFlightRefresh != null) {
      await inFlightRefresh;
    }
  }

  void _safeNotifyListeners() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSessionManager.removeListener(_handleAuthStateChanged);
    super.dispose();
  }
}
