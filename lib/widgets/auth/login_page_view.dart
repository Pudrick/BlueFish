import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum LoginPageAuthMode { smsCode, password }

@immutable
class SmsCodeRequest {
  final String areaCode;
  final String phoneNumber;

  const SmsCodeRequest({required this.areaCode, required this.phoneNumber});

  String get fullPhoneNumber => '$areaCode$phoneNumber';
}

@immutable
class SmsCodeLoginSubmission {
  final String areaCode;
  final String phoneNumber;
  final String verificationCode;

  const SmsCodeLoginSubmission({
    required this.areaCode,
    required this.phoneNumber,
    required this.verificationCode,
  });

  String get fullPhoneNumber => '$areaCode$phoneNumber';
}

@immutable
class PasswordLoginSubmission {
  final String account;
  final String password;

  const PasswordLoginSubmission({
    required this.account,
    required this.password,
  });
}

class LoginPageView extends StatefulWidget {
  final LoginPageAuthMode initialMode;
  final FutureOr<void> Function(SmsCodeRequest request)?
  onRequestVerificationCode;
  final FutureOr<void> Function(SmsCodeLoginSubmission submission)?
  onSubmitSmsCodeLogin;
  final FutureOr<void> Function(PasswordLoginSubmission submission)?
  onSubmitPasswordLogin;

  const LoginPageView({
    super.key,
    this.initialMode = LoginPageAuthMode.smsCode,
    this.onRequestVerificationCode,
    this.onSubmitSmsCodeLogin,
    this.onSubmitPasswordLogin,
  });

  @override
  State<LoginPageView> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  final _formKey = GlobalKey<FormState>();
  final _areaCodeController = TextEditingController(text: '86');
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();

  late LoginPageAuthMode _mode;
  bool _obscurePassword = true;
  bool _isSendingCode = false;
  bool _isSubmitting = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _areaCodeController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canRequestCode =>
      !_isSendingCode &&
      _countdown == 0 &&
      _normalizeAreaCode(_areaCodeController.text) != null &&
      _normalizePhoneNumber(_phoneController.text) != null;

  Future<void> _requestVerificationCode() async {
    final areaCode = _normalizeAreaCode(_areaCodeController.text);
    final phoneNumber = _normalizePhoneNumber(_phoneController.text);
    if (areaCode == null || phoneNumber == null) {
      _showMessage('请输入正确的区号和手机号');
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final request = SmsCodeRequest(
        areaCode: areaCode,
        phoneNumber: phoneNumber,
      );
      await (widget.onRequestVerificationCode?.call(request) ??
          Future<void>.delayed(const Duration(milliseconds: 450)));
      if (!mounted) return;
      _startCountdown();
      if (widget.onRequestVerificationCode == null) {
        _showMessage('验证码已发送至 ${request.fullPhoneNumber}');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('验证码发送失败，请稍后重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_mode == LoginPageAuthMode.smsCode) {
        final submission = SmsCodeLoginSubmission(
          areaCode: _normalizeAreaCode(_areaCodeController.text)!,
          phoneNumber: _normalizePhoneNumber(_phoneController.text)!,
          verificationCode: _normalizeVerificationCode(
            _smsCodeController.text,
          )!,
        );
        await (widget.onSubmitSmsCodeLogin?.call(submission) ??
            Future<void>.delayed(const Duration(milliseconds: 550)));
        if (mounted && widget.onSubmitSmsCodeLogin == null) {
          _showMessage('已提交验证码登录');
        }
      } else {
        final submission = PasswordLoginSubmission(
          account: _normalizeAccount(_accountController.text)!,
          password: _passwordController.text,
        );
        await (widget.onSubmitPasswordLogin?.call(submission) ??
            Future<void>.delayed(const Duration(milliseconds: 550)));
        if (mounted && widget.onSubmitPasswordLogin == null) {
          _showMessage('已提交密码登录');
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage('登录失败，请检查信息后重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _countdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _countdown = 0);
        }
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  String? _normalizeAreaCode(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '').trim();
    return RegExp(r'^\d{1,4}$').hasMatch(normalized) ? '+$normalized' : null;
  }

  String? _normalizePhoneNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '').trim();
    return RegExp(r'^\d{6,15}$').hasMatch(normalized) ? normalized : null;
  }

  String? _normalizeVerificationCode(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '').trim();
    return RegExp(r'^\d{4,8}$').hasMatch(normalized) ? normalized : null;
  }

  String? _normalizeAccount(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.7),
              colorScheme.surface,
              colorScheme.tertiaryContainer.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: _BackgroundOrb(
                size: 220,
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -30,
              child: _BackgroundOrb(
                size: 190,
                color: colorScheme.tertiary.withValues(alpha: 0.12),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildFormCard(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '登录',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '欢迎回来',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<LoginPageAuthMode>(
                  segments: const [
                    ButtonSegment(
                      value: LoginPageAuthMode.smsCode,
                      icon: Icon(Icons.sms_outlined),
                      label: Text('验证码登录'),
                    ),
                    ButtonSegment(
                      value: LoginPageAuthMode.password,
                      icon: Icon(Icons.lock_outline_rounded),
                      label: Text('密码登录'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                  showSelectedIcon: false,
                  multiSelectionEnabled: false,
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _mode == LoginPageAuthMode.smsCode
                      ? _buildSmsForm()
                      : _buildPasswordForm(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(
                            _mode == LoginPageAuthMode.smsCode
                                ? '验证码登录'
                                : '密码登录',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmsForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('login-sms-form'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: TextFormField(
                key: const ValueKey('login-area-code-field'),
                controller: _areaCodeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: '区号',
                  prefixIcon: Icon(Icons.public_rounded),
                  prefixText: '+',
                ),
                validator: (value) {
                  if (_normalizeAreaCode(value ?? '') == null) {
                    return '格式错误';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const ValueKey('login-phone-field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (_normalizePhoneNumber(value ?? '') == null) {
                    return '请输入手机号';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('login-sms-code-field'),
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '短信验证码',
                  hintText: '输入 4-8 位验证码',
                  prefixIcon: Icon(Icons.mark_email_unread_outlined),
                ),
                validator: (value) {
                  if (_normalizeVerificationCode(value ?? '') == null) {
                    return '请输入有效验证码';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 128, maxWidth: 148),
              child: FilledButton.tonal(
                key: const ValueKey('login-send-code-button'),
                onPressed: _canRequestCode ? _requestVerificationCode : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                child: Text(
                  _isSendingCode
                      ? '发送中...'
                      : _countdown > 0
                      ? '${_countdown}s'
                      : '发送验证码',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      key: const ValueKey('login-password-form'),
      children: [
        TextFormField(
          key: const ValueKey('login-account-field'),
          controller: _accountController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '账号或手机号',
            hintText: '输入账号或手机号',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) {
            if (_normalizeAccount(value ?? '') == null) {
              return '请输入账号或手机号';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('login-password-field'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: '密码',
            hintText: '输入登录密码',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().length < 6) {
              return '密码至少 6 位';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
