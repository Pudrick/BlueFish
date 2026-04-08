import 'package:flutter/foundation.dart';

@immutable
class CurrentUserProfile {
  final String username;
  final String avatarUrl;
  final int euid;
  final int updatedAtEpochMs;

  const CurrentUserProfile({
    required this.username,
    required this.avatarUrl,
    required this.euid,
    required this.updatedAtEpochMs,
  });

  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtEpochMs);

  CurrentUserProfile copyWith({
    String? username,
    String? avatarUrl,
    int? euid,
    int? updatedAtEpochMs,
  }) {
    return CurrentUserProfile(
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      euid: euid ?? this.euid,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }
}
