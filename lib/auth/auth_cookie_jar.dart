import 'dart:convert';

import 'package:flutter/foundation.dart';

const int _secondsPrecisionEpochThreshold = 100000000000;

int? normalizeCookieExpiresDateMs(int? rawExpiresDateMs) {
  if (rawExpiresDateMs == null || rawExpiresDateMs <= 0) {
    return rawExpiresDateMs;
  }

  // flutter_inappwebview_windows currently reads cookie expiry back as
  // Unix seconds, while the Dart side expects milliseconds.
  if (rawExpiresDateMs < _secondsPrecisionEpochThreshold) {
    return rawExpiresDateMs * 1000;
  }

  return rawExpiresDateMs;
}

@immutable
class AuthCookieEntry {
  final String name;
  final String value;
  final String? domain;
  final String path;
  final bool isSecure;
  final bool isHttpOnly;
  final int? expiresDateMs;

  const AuthCookieEntry({
    required this.name,
    required this.value,
    this.domain,
    this.path = '/',
    this.isSecure = false,
    this.isHttpOnly = false,
    this.expiresDateMs,
  });

  String get requestPair => '$name=$value';

  bool isExpiredAt(DateTime instant) {
    final expiresDateMs = normalizeCookieExpiresDateMs(this.expiresDateMs);
    if (expiresDateMs == null) {
      return false;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      expiresDateMs,
      isUtc: true,
    ).isBefore(instant.toUtc());
  }

  bool matches(Uri uri, {DateTime? now}) {
    final comparisonInstant = now ?? DateTime.now();
    if (isExpiredAt(comparisonInstant)) {
      return false;
    }
    if (isSecure && uri.scheme.toLowerCase() != 'https') {
      return false;
    }
    if (!_domainMatches(uri.host)) {
      return false;
    }
    return _pathMatches(uri.path);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'isSecure': isSecure,
      'isHttpOnly': isHttpOnly,
      'expiresDateMs': normalizeCookieExpiresDateMs(expiresDateMs),
    };
  }

  static AuthCookieEntry? fromJson(Map<String, dynamic> json) {
    final normalizedName = (json['name'] as String?)?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return null;
    }

    final normalizedValue = (json['value'] as String? ?? '').trim();
    final rawDomain = (json['domain'] as String?)?.trim();
    final normalizedPath = _normalizePath((json['path'] as String?)?.trim());
    final rawExpiresDate = json['expiresDateMs'];

    return AuthCookieEntry(
      name: normalizedName,
      value: normalizedValue,
      domain: _normalizeDomain(rawDomain),
      path: normalizedPath,
      isSecure: json['isSecure'] == true,
      isHttpOnly: json['isHttpOnly'] == true,
      expiresDateMs: normalizeCookieExpiresDateMs(
        rawExpiresDate is num ? rawExpiresDate.toInt() : null,
      ),
    );
  }

  bool _domainMatches(String host) {
    final normalizedDomain = _normalizeDomain(domain);
    if (normalizedDomain == null) {
      return true;
    }

    final normalizedHost = host.trim().toLowerCase();
    return normalizedHost == normalizedDomain ||
        normalizedHost.endsWith('.$normalizedDomain');
  }

  bool _pathMatches(String rawPath) {
    final requestPath = _normalizePath(rawPath);
    return requestPath == path || requestPath.startsWith(path);
  }

  static String? _normalizeDomain(String? rawDomain) {
    final normalized = rawDomain?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized.startsWith('.') ? normalized.substring(1) : normalized;
  }

  static String _normalizePath(String? rawPath) {
    final normalized = rawPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/';
    }
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }
}

@immutable
class AuthCookieJar {
  static const int _schemaVersion = 1;

  static const AuthCookieJar empty = AuthCookieJar._();

  final List<AuthCookieEntry> cookies;
  final String? legacyHeader;

  const AuthCookieJar._({
    this.cookies = const <AuthCookieEntry>[],
    this.legacyHeader,
  });

  bool get hasStructuredCookies => cookies.isNotEmpty;

  bool get isEmpty {
    return cookies.isEmpty && (legacyHeader == null || legacyHeader!.isEmpty);
  }

  String buildAllCookiesHeader({DateTime? now}) {
    if (cookies.isEmpty) {
      return legacyHeader ?? '';
    }

    final comparisonInstant = now ?? DateTime.now();
    final activeCookies = cookies
        .where((cookie) => !cookie.isExpiredAt(comparisonInstant))
        .map((cookie) => cookie.requestPair)
        .toList(growable: false);
    return activeCookies.join('; ');
  }

  String buildCookieHeaderForUri(Uri uri, {DateTime? now}) {
    if (cookies.isEmpty) {
      return legacyHeader ?? '';
    }

    final comparisonInstant = now ?? DateTime.now();
    final matchingCookies =
        cookies
            .where((cookie) => cookie.matches(uri, now: comparisonInstant))
            .toList(growable: false)
          ..sort(_compareRequestCookies);
    return matchingCookies.map((cookie) => cookie.requestPair).join('; ');
  }

  bool containsCookieNamed(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return false;
    }

    if (cookies.isNotEmpty) {
      return cookies.any((cookie) => cookie.name == normalizedName);
    }

    final header = legacyHeader;
    if (header == null || header.isEmpty) {
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

  String? toPersistenceValue() {
    if (isEmpty) {
      return null;
    }
    if (cookies.isEmpty) {
      return legacyHeader;
    }

    return jsonEncode(<String, Object?>{
      'schemaVersion': _schemaVersion,
      'cookies': cookies
          .map((cookie) => cookie.toJson())
          .toList(growable: false),
    });
  }

  static AuthCookieJar fromHeader(String? rawHeader) {
    final normalizedHeader = rawHeader?.trim();
    if (normalizedHeader == null || normalizedHeader.isEmpty) {
      return empty;
    }
    return AuthCookieJar._(legacyHeader: normalizedHeader);
  }

  static AuthCookieJar fromCookies(Iterable<AuthCookieEntry> rawCookies) {
    final deduped = <String, AuthCookieEntry>{};
    for (final cookie in rawCookies) {
      final normalizedName = cookie.name.trim();
      if (normalizedName.isEmpty) {
        continue;
      }

      final normalizedCookie = AuthCookieEntry(
        name: normalizedName,
        value: cookie.value.trim(),
        domain: _normalizeDomain(cookie.domain),
        path: _normalizePath(cookie.path),
        isSecure: cookie.isSecure,
        isHttpOnly: cookie.isHttpOnly,
        expiresDateMs: normalizeCookieExpiresDateMs(cookie.expiresDateMs),
      );
      deduped[_cookieKey(normalizedCookie)] = normalizedCookie;
    }

    if (deduped.isEmpty) {
      return empty;
    }

    final normalizedCookies = deduped.values.toList(growable: false)
      ..sort(_compareCookies);
    return AuthCookieJar._(cookies: List.unmodifiable(normalizedCookies));
  }

  static AuthCookieJar fromPersistedValue(String? rawValue) {
    final normalizedValue = rawValue?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return empty;
    }

    final structured = _tryParseStructuredCookies(normalizedValue);
    return structured ?? fromHeader(normalizedValue);
  }

  static AuthCookieJar? _tryParseStructuredCookies(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      final List<dynamic>? rawCookies = switch (decoded) {
        Map<String, dynamic>() => decoded['cookies'] as List<dynamic>?,
        List<dynamic>() => decoded,
        _ => null,
      };
      if (rawCookies == null) {
        return null;
      }

      final cookies = rawCookies
          .whereType<Map>()
          .map(
            (rawCookie) =>
                AuthCookieEntry.fromJson(Map<String, dynamic>.from(rawCookie)),
          )
          .whereType<AuthCookieEntry>();
      return fromCookies(cookies);
    } catch (_) {
      return null;
    }
  }

  static int _compareCookies(AuthCookieEntry left, AuthCookieEntry right) {
    final domainComparison = (left.domain ?? '').compareTo(right.domain ?? '');
    if (domainComparison != 0) {
      return domainComparison;
    }

    final pathComparison = right.path.length.compareTo(left.path.length);
    if (pathComparison != 0) {
      return pathComparison;
    }

    final nameComparison = left.name.compareTo(right.name);
    if (nameComparison != 0) {
      return nameComparison;
    }

    return left.value.compareTo(right.value);
  }

  static int _compareRequestCookies(
    AuthCookieEntry left,
    AuthCookieEntry right,
  ) {
    final pathComparison = right.path.length.compareTo(left.path.length);
    if (pathComparison != 0) {
      return pathComparison;
    }

    final domainLengthComparison = (right.domain ?? '').length.compareTo(
      (left.domain ?? '').length,
    );
    if (domainLengthComparison != 0) {
      return domainLengthComparison;
    }

    return _compareCookies(left, right);
  }

  static String _cookieKey(AuthCookieEntry cookie) {
    return '${cookie.domain ?? ''}\n${cookie.path}\n${cookie.name}';
  }

  static String? _normalizeDomain(String? rawDomain) {
    final normalized = rawDomain?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized.startsWith('.') ? normalized.substring(1) : normalized;
  }

  static String _normalizePath(String rawPath) {
    final normalized = rawPath.trim();
    if (normalized.isEmpty) {
      return '/';
    }
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }
}
