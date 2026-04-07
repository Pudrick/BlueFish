import 'dart:convert';

import 'package:bluefish/auth/auth_cookie_jar.dart';
import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/services/private_message/private_message_service_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class WebLoginCookieStore {
  static const Duration _captureThrottleWindow = Duration(milliseconds: 800);

  static final List<Uri> _windowsCookieProbeUris = <Uri>[
    Uri.parse('https://passport.hupu.com/'),
    Uri.parse('https://my.hupu.com/'),
    Uri.parse('https://bbs.hupu.com/'),
  ];

  final CookieManager _cookieManager;
  final Map<String, DateTime> _recentCaptureAtByKey = <String, DateTime>{};

  AuthCookieJar _capturedCookieJar = AuthCookieJar.empty;
  Future<void> _captureSequence = Future<void>.value();
  int _captureSession = 0;
  bool _captureFrozen = false;

  WebLoginCookieStore({CookieManager? cookieManager})
    : _cookieManager = cookieManager ?? CookieManager.instance();

  List<AuthCookieEntry> get capturedCookies => _capturedCookieJar.cookies;

  void resetSessionCapture() {
    _captureSession += 1;
    _captureFrozen = false;
    _capturedCookieJar = AuthCookieJar.empty;
    _captureSequence = Future<void>.value();
    _recentCaptureAtByKey.clear();
  }

  void freezeCapturedCookies() {
    if (_captureFrozen) {
      return;
    }

    _captureFrozen = true;
  }

  Future<void> captureCookiesForUri(Uri? uri) async {
    if (uri == null) {
      return;
    }

    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.trim().isEmpty) {
      return;
    }
    if (_captureFrozen) {
      return;
    }

    final captureKey = _captureKeyForUri(uri);
    final now = DateTime.now();
    final lastCaptureAt = _recentCaptureAtByKey[captureKey];
    if (lastCaptureAt != null &&
        now.difference(lastCaptureAt) < _captureThrottleWindow) {
      return;
    }

    _recentCaptureAtByKey[captureKey] = now;
    final captureSession = _captureSession;
    _captureSequence = _captureSequence.then(
      (_) => _captureCookiesForUriInternal(uri, captureSession: captureSession),
    );
    await _captureSequence;
  }

  Future<List<AuthCookieEntry>> getAllCookies() async {
    await _captureSequence;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final collected = <AuthCookieEntry>[..._capturedCookieJar.cookies];
      for (final uri in _windowsCookieProbeUris) {
        final cookies = await _cookieManager.getCookies(url: WebUri.uri(uri));
        if (cookies.isEmpty) {
          continue;
        }

        collected.addAll(_mapCookies(cookies));
      }
      return AuthCookieJar.fromCookies(collected).cookies;
    }

    final cookies = await _cookieManager.getAllCookies();
    final mappedCookies = _mapCookies(cookies);
    final mergedCookieJar = AuthCookieJar.fromCookies(<AuthCookieEntry>[
      ..._capturedCookieJar.cookies,
      ...mappedCookies,
    ]);
    return mergedCookieJar.cookies;
  }

  Future<void> clearAllCookies() async {
    await _cookieManager.deleteAllCookies();
    resetSessionCapture();
  }

  Future<void> _captureCookiesForUriInternal(
    Uri uri, {
    required int captureSession,
  }) async {
    if (_captureFrozen || _captureSession != captureSession) {
      return;
    }

    try {
      final cookies = await _cookieManager.getCookies(url: WebUri.uri(uri));
      final mappedCookies = _mapCookies(cookies);
      if (_captureFrozen || _captureSession != captureSession) {
        return;
      }

      if (mappedCookies.isEmpty) {
        return;
      }

      _capturedCookieJar = AuthCookieJar.fromCookies(<AuthCookieEntry>[
        ..._capturedCookieJar.cookies,
        ...mappedCookies,
      ]);
    } catch (_) {}
  }

  String _captureKeyForUri(Uri uri) {
    final normalizedScheme = uri.scheme.toLowerCase();
    final normalizedHost = uri.host.toLowerCase();
    final portText = uri.hasPort ? ':${uri.port}' : '';
    final normalizedPath = uri.path.trim().isEmpty ? '/' : uri.path;
    return '$normalizedScheme://$normalizedHost$portText$normalizedPath';
  }

  List<AuthCookieEntry> _mapCookies(List<Cookie> cookies) {
    return cookies
        .map(
          (cookie) => AuthCookieEntry(
            name: cookie.name,
            value: '${cookie.value ?? ''}',
            domain: cookie.domain,
            path: cookie.path ?? '/',
            isSecure: cookie.isSecure == true,
            isHttpOnly: cookie.isHttpOnly == true,
            expiresDateMs: normalizeCookieExpiresDateMs(cookie.expiresDate),
          ),
        )
        .toList(growable: false);
  }
}

class WebLoginSessionValidator {
  static final Uri _validationUrl = Uri.parse(
    'https://my.hupu.com/pcmapi/pc/space/v1/pm/getPmList',
  );

  final http.Client _client;

  WebLoginSessionValidator({http.Client? client})
    : _client = client ?? http.Client();

  Future<bool> validate(AuthCookieJar cookieJar) async {
    final comparisonInstant = DateTime.now();
    final allCookieHeader = cookieJar.buildAllCookiesHeader(
      now: comparisonInstant,
    );
    var cookieHeader = cookieJar.buildCookieHeaderForUri(
      _validationUrl,
      now: comparisonInstant,
    );

    if (cookieHeader.trim().isEmpty && allCookieHeader.trim().isNotEmpty) {
      cookieHeader = allCookieHeader;
    }
    if (cookieHeader.trim().isEmpty) {
      return false;
    }

    try {
      final response = await _client.post(
        _validationUrl,
        headers: <String, String>{
          ...privateMessageJsonHeaders,
          'user-agent': ApiConfig.userAgent,
          'cookie': cookieHeader,
        },
        body: jsonEncode(<String, Object?>{
          'unreadList': 0,
          'page': <String, int>{'pageNum': 1, 'pageSize': 1},
        }),
      );
      if (response.statusCode != 200) {
        return false;
      }

      final payload = jsonDecode(response.body);
      return payload is Map<String, dynamic> &&
          payload['data'] is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
