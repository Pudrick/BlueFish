import 'dart:async';

import 'package:bluefish/auth/auth_cookie_jar.dart';
import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/web_login_session_service.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

String _describeWebUri(WebUri? uri) => uri?.toString() ?? '-';

Uri? _tryParseWebUri(WebUri? uri) {
  final rawValue = uri?.toString().trim();
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }
  return Uri.tryParse(rawValue);
}

const Set<String> _postLoginLandingHosts = <String>{
  'www.hupu.com',
  'm.hupu.com',
  'bbs.hupu.com',
  'my.hupu.com',
};

bool _looksLikePostLoginLanding(WebUri? uri) {
  if (uri == null) {
    return false;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return false;
  }

  final host = uri.host.toLowerCase();
  if (host.isEmpty || host == 'passport.hupu.com') {
    return false;
  }

  return _postLoginLandingHosts.contains(host);
}

bool _hasLikelyLoginSessionCookie(AuthCookieJar cookieJar) {
  return cookieJar.containsCookieNamed('u') ||
      cookieJar.containsCookieNamed('us') ||
      cookieJar.containsCookieNamed('_HUPUSSOID');
}

class LoginPageView extends StatefulWidget {
  static final Uri loginUri = Uri.parse(
    'https://passport.hupu.com/v2/login?pcPhone=1',
  );

  const LoginPageView({super.key});

  @override
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  final WebLoginCookieStore _cookieStore = WebLoginCookieStore();
  final WebLoginSessionValidator _validator = WebLoginSessionValidator();

  InAppWebViewController? _webViewController;
  double _loadingProgress = 0;
  bool _isPageLoading = true;
  bool _isSyncingCookies = false;
  String _statusText = '在网页中完成登录后，应用会自动尝试同步 Cookie。';
  DateTime? _lastAutoSyncAt;
  DateTime? _lastLandingInterceptionAt;
  bool _isInterceptAutoSyncScheduled = false;
  int _interceptAutoSyncToken = 0;

  bool get _useManualSyncAfterLoginOnWindows {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _cookieStore.resetSessionCapture();
    if (_useManualSyncAfterLoginOnWindows) {
      _statusText = 'Windows 端登录完成后会自动同步登录状态，若失败可手动点击“同步登录状态”。';
    }
  }

  @override
  void dispose() {
    _cancelPendingInterceptAutoSync();
    _validator.dispose();
    super.dispose();
  }

  Future<void> _syncLoginState({bool autoTriggered = false}) async {
    if (_isSyncingCookies) {
      return;
    }

    final authSessionManager = context.read<AuthSessionManager>();

    setState(() {
      _isSyncingCookies = true;
      _statusText = autoTriggered ? '正在检测网页登录状态...' : '正在同步登录状态...';
    });

    try {
      final cookies = await _cookieStore.getAllCookies();
      final cookieJar = AuthCookieJar.fromCookies(cookies);
      if (cookieJar.isEmpty) {
        _updateStatus(
          autoTriggered
              ? '还没有检测到可用 Cookie，登录完成后会继续自动检测。'
              : '当前还没有读取到任何 Cookie。',
        );
        if (!autoTriggered && mounted) {
          _showMessage('当前还没有读取到任何 Cookie。');
        }
        return;
      }

      if (autoTriggered &&
          !cookieJar.containsCookieNamed('u') &&
          !cookieJar.containsCookieNamed('us') &&
          !cookieJar.containsCookieNamed('_HUPUSSOID')) {
        _updateStatus('已读取到 Cookie，等待登录态稳定后继续检测。');
        return;
      }

      final isValid = await _validator.validate(cookieJar);
      if (!isValid) {
        _updateStatus(
          autoTriggered
              ? '已检测到网页登录痕迹，但应用会话校验尚未通过。'
              : 'Cookie 已读取，但应用会话校验未通过，请确认已经登录成功。',
        );
        if (!autoTriggered && mounted) {
          _showMessage('Cookie 已读取，但应用会话校验未通过，请确认已经登录成功。');
        }
        return;
      }

      await authSessionManager.saveLoginCookieEntries(cookieJar.cookies);
      if (!mounted) {
        return;
      }

      _triggerCurrentUserProfileRefresh();
      _showMessage('登录成功。');
      await _completeLoginFlow();
    } catch (_) {
      _updateStatus('同步登录状态失败，请稍后重试。');
      if (!autoTriggered && mounted) {
        _showMessage('同步登录状态失败，请稍后重试。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingCookies = false;
        });
      }
    }
  }

  Future<void> _restartLoginFlow() async {
    if (_isSyncingCookies) {
      return;
    }

    final authSessionManager = context.read<AuthSessionManager>();
    _cancelPendingInterceptAutoSync();

    setState(() {
      _isSyncingCookies = true;
      _statusText = '正在清空网页登录状态...';
    });

    try {
      await _cookieStore.clearAllCookies();
      await authSessionManager.clearLoginCookies();
      await InAppWebViewController.clearAllCache();
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(LoginPageView.loginUri.toString())),
      );
      _updateStatus('已清空网页登录状态，请重新登录。');
    } catch (_) {
      _updateStatus('清空网页登录状态失败，请稍后重试。');
      if (mounted) {
        _showMessage('清空网页登录状态失败，请稍后重试。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingCookies = false;
        });
      }
    }
  }

  Future<void> _reloadPage() async {
    await _webViewController?.reload();
    if (!mounted) {
      return;
    }
    setState(() {
      _statusText = '正在重新加载登录页...';
    });
  }

  void _notifyInterceptedLanding(
    WebUri? targetUrl, {
    required bool hasLikelySessionCookie,
  }) {
    final targetText = _describeWebUri(targetUrl);
    _cookieStore.freezeCapturedCookies();
    final nextStatus = hasLikelySessionCookie
        ? '检测到登录成功跳转，正在自动同步登录状态...'
        : '已拦截离开登录页的跳转，正在自动尝试同步登录状态...';
    _updateStatus(nextStatus);

    final now = DateTime.now();
    final lastLandingInterceptionAt = _lastLandingInterceptionAt;
    if (lastLandingInterceptionAt != null &&
        now.difference(lastLandingInterceptionAt) <
            const Duration(seconds: 2)) {
      return;
    }

    _lastLandingInterceptionAt = now;
    final message = hasLikelySessionCookie
        ? '已拦截登录成功后的页面跳转，正在自动同步登录状态。'
        : '已阻止跳出登录页：$targetText';
    _showMessage(message);
    _scheduleInterceptAutoSync(hasLikelySessionCookie: hasLikelySessionCookie);
  }

  Future<NavigationActionPolicy> _handleShouldOverrideUrlLoading(
    InAppWebViewController _,
    NavigationAction navigationAction,
  ) async {
    final targetUrl = navigationAction.request.url;
    await _cookieStore.captureCookiesForUri(_tryParseWebUri(targetUrl));
    final isCandidate =
        _useManualSyncAfterLoginOnWindows &&
        navigationAction.isForMainFrame &&
        _looksLikePostLoginLanding(targetUrl);
    if (!isCandidate) {
      return NavigationActionPolicy.ALLOW;
    }

    try {
      final cookieJar = AuthCookieJar.fromCookies(
        await _cookieStore.getAllCookies(),
      );
      final hasLikelySessionCookie = _hasLikelyLoginSessionCookie(cookieJar);
      _notifyInterceptedLanding(
        targetUrl,
        hasLikelySessionCookie: hasLikelySessionCookie,
      );
    } catch (_) {
      _notifyInterceptedLanding(targetUrl, hasLikelySessionCookie: false);
    }

    return NavigationActionPolicy.CANCEL;
  }

  void _scheduleAutoSync() {
    if (_useManualSyncAfterLoginOnWindows) {
      return;
    }

    final now = DateTime.now();
    final lastAutoSyncAt = _lastAutoSyncAt;
    if (lastAutoSyncAt != null &&
        now.difference(lastAutoSyncAt) < const Duration(seconds: 2)) {
      return;
    }

    _lastAutoSyncAt = now;
    unawaited(_syncLoginState(autoTriggered: true));
  }

  void _scheduleInterceptAutoSync({required bool hasLikelySessionCookie}) {
    if (!_useManualSyncAfterLoginOnWindows) {
      return;
    }
    if (_isInterceptAutoSyncScheduled) {
      return;
    }

    final delay = hasLikelySessionCookie
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 500);
    _interceptAutoSyncToken += 1;
    final currentToken = _interceptAutoSyncToken;
    _isInterceptAutoSyncScheduled = true;
    unawaited(() async {
      try {
        await Future<void>.delayed(delay);
        if (!mounted || currentToken != _interceptAutoSyncToken) {
          return;
        }
        await _syncLoginState(autoTriggered: true);
      } finally {
        if (currentToken == _interceptAutoSyncToken) {
          _isInterceptAutoSyncScheduled = false;
        }
      }
    }());
  }

  void _cancelPendingInterceptAutoSync() {
    if (!_isInterceptAutoSyncScheduled && _interceptAutoSyncToken == 0) {
      return;
    }

    _interceptAutoSyncToken += 1;
    _isInterceptAutoSyncScheduled = false;
  }

  void _captureCookiesForWebUri(WebUri? url) {
    unawaited(_cookieStore.captureCookiesForUri(_tryParseWebUri(url)));
  }

  void _captureCookiesForUri(Uri? uri) {
    unawaited(_cookieStore.captureCookiesForUri(uri));
  }

  Future<void> _completeLoginFlow() async {
    // On Windows, the flutter_inappwebview native destructor calls
    // DestroyWindow before webViewController->Close, which is the
    // reverse of what WebView2 requires. Stop the WebView first to
    // put it in a quiescent state and reduce the chance of a native
    // crash during disposal.
    final controller = _webViewController;
    if (controller != null) {
      try {
        await controller.stopLoading();
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final router = context.maybeGoRouter;
    if (router != null && router.canPop()) {
      router.pop<bool>(true);
      return;
    }

    context.goThreadList();
  }

  Future<bool> _handleCreateWindow(
    InAppWebViewController _,
    CreateWindowAction createWindowAction,
  ) async {
    final popupUrl = createWindowAction.request.url;
    _captureCookiesForWebUri(popupUrl);
    if (popupUrl == null || popupUrl.toString().trim().isEmpty) {
      _updateStatus('检测到登录弹窗请求，但地址为空，已忽略。');
    } else {
      _updateStatus('检测到登录弹窗，已在当前页面继续打开。');
    }
    // Must return false so the native WebView2 layer completes its deferral
    // and loads the popup URL in the current webview. Returning true would
    // skip the native defaultBehaviour, leaving the deferral uncompleted
    // and crashing the WebView2 process on Windows.
    return false;
  }

  void _updateStatus(String nextStatus) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusText = nextStatus;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _triggerCurrentUserProfileRefresh() {
    final profileViewModel = Provider.of<CurrentUserProfileViewModel?>(
      context,
      listen: false,
    );
    if (profileViewModel == null) {
      return;
    }

    unawaited(profileViewModel.refreshProfile(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loginGuideText = _useManualSyncAfterLoginOnWindows
        ? 'Windows 端会从打开登录页开始持续累计这期间拿到的全部 Cookie；检测到登录成功跳转后会自动同步并校验，若失败仍可手动点击“同步登录状态”。'
        : '打开虎扑登录页后，应用会保存 WebView 中返回的全部 Cookie，再自动校验登录是否生效。';

    if (!_isSupportedPlatform) {
      return Scaffold(
        appBar: AppBar(title: const Text('网页登录')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '当前平台暂不支持内嵌网页登录，请使用 Windows 或 Android 版本。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('网页登录'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () {
            context.popOrGoThreadList();
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loginGuideText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _isSyncingCookies
                              ? null
                              : () => _syncLoginState(),
                          icon: _isSyncingCookies
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cookie_outlined),
                          label: const Text('同步登录状态'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSyncingCookies ? null : _reloadPage,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('刷新页面'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSyncingCookies
                              ? null
                              : _restartLoginFlow,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('重新开始登录'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: _isPageLoading ? _loadingProgress.clamp(0, 1) : null,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(LoginPageView.loginUri.toString()),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        transparentBackground: false,
                        useShouldOverrideUrlLoading:
                            _useManualSyncAfterLoginOnWindows,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsBackForwardNavigationGestures: true,
                        thirdPartyCookiesEnabled: true,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                        _cookieStore.resetSessionCapture();
                        _captureCookiesForUri(LoginPageView.loginUri);
                      },
                      onLoadStart: (controller, url) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isPageLoading = true;
                          _loadingProgress = 0;
                        });
                        _captureCookiesForWebUri(url);
                      },
                      onLoadStop: (controller, url) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isPageLoading = false;
                          _loadingProgress = 1;
                        });
                        _captureCookiesForWebUri(url);
                        _scheduleAutoSync();
                      },
                      onProgressChanged: (controller, progress) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _loadingProgress = progress / 100;
                          _isPageLoading = progress < 100;
                        });
                      },
                      onUpdateVisitedHistory: (controller, url, isReload) {
                        _captureCookiesForWebUri(url);
                        _scheduleAutoSync();
                      },
                      onCreateWindow: _handleCreateWindow,
                      onLoadResource: (controller, resource) {
                        _captureCookiesForWebUri(resource.url);
                      },
                      shouldOverrideUrlLoading:
                          _useManualSyncAfterLoginOnWindows
                          ? _handleShouldOverrideUrlLoading
                          : null,
                      onCloseWindow: (controller) {
                        if (_useManualSyncAfterLoginOnWindows) {
                          _cookieStore.freezeCapturedCookies();
                          _updateStatus('检测到网页登录流程结束，请点击“同步登录状态”。');
                          return;
                        }

                        _updateStatus('网页登录触发关闭请求，正在校验登录状态...');
                        _scheduleAutoSync();
                      },
                      onReceivedError: (controller, request, error) {
                        _updateStatus('页面加载失败，请检查网络后重试。');
                      },
                      onReceivedHttpError:
                          (controller, request, errorResponse) {
                            _updateStatus(
                              '登录页返回异常状态码 ${errorResponse.statusCode ?? '-'}。',
                            );
                          },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
