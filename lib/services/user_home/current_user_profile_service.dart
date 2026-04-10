import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/current_user_profile.dart';
import 'package:http/http.dart' as http;

abstract class CurrentUserProfileService {
  Future<CurrentUserProfile> fetchCurrentUserProfile();
}

class CurrentUserProfileHttpService implements CurrentUserProfileService {
  static final Uri _currentUserProfileUri = Uri.parse(
    'https://my.hupu.com/pcmapi/pc/space/v1/getReddot',
  );

  final http.Client _client;

  CurrentUserProfileHttpService({required http.Client client})
    : _client = client;

  @override
  Future<CurrentUserProfile> fetchCurrentUserProfile() async {
    final response = await _client.get(_currentUserProfileUri);
    if (response.statusCode != 200) {
      throw const HttpException(
        'Failed to fetch current user profile payload.',
      );
    }

    return parseCurrentUserProfileFromBody(response.body);
  }
}

CurrentUserProfile parseCurrentUserProfileFromBody(
  String responseBody, {
  DateTime? now,
}) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Invalid current user profile payload root object.',
    );
  }

  final code = decoded['code'];
  if (code is! num || code.toInt() != 1) {
    throw const FormatException(
      'Current user profile payload code is not successful.',
    );
  }

  final data = decoded['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException(
      'Invalid current user profile payload data object.',
    );
  }

  final userInfo = data['userInfo'];
  if (userInfo is! Map<String, dynamic>) {
    throw const FormatException(
      'Invalid current user profile payload userInfo object.',
    );
  }

  final username = _requireNonEmptyString(userInfo['username'], 'username');
  final avatarUrl = _requireNonEmptyString(userInfo['header'], 'header');
  final euid = _requireInt(data['euid'], 'euid');

  return CurrentUserProfile(
    username: username,
    avatarUrl: avatarUrl,
    euid: euid,
    updatedAtEpochMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
  );
}

String _requireNonEmptyString(Object? value, String fieldName) {
  if (value is! String) {
    throw FormatException('Invalid current user profile field: $fieldName.');
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('Empty current user profile field: $fieldName.');
  }
  return normalized;
}

int _requireInt(Object? value, String fieldName) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Invalid current user profile field: $fieldName.');
}
