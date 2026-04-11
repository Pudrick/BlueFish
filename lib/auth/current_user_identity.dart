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
