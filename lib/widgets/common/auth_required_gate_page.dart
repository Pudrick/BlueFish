import 'package:bluefish/router/auth_guard.dart';
import 'package:bluefish/widgets/common/fullscreen_feedback_scaffold.dart';
import 'package:flutter/material.dart';

typedef AuthGateLoginNavigation = Future<void> Function(BuildContext context);

class AuthRequiredGatePage extends StatefulWidget {
  final AuthGuardPolicy policy;
  final bool isLoggedIn;
  final AuthGateLoginNavigation onGoToLogin;
  final VoidCallback onBackPressed;
  final String blockedHint;

  const AuthRequiredGatePage({
    super.key,
    required this.policy,
    required this.isLoggedIn,
    required this.onGoToLogin,
    required this.onBackPressed,
    required this.blockedHint,
  });

  @override
  State<AuthRequiredGatePage> createState() => _AuthRequiredGatePageState();
}

class _AuthRequiredGatePageState extends State<AuthRequiredGatePage> {
  bool _hasPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptIfNeeded();
    });
  }

  Future<void> _promptIfNeeded() async {
    if (_hasPrompted || widget.isLoggedIn || !mounted) {
      return;
    }
    _hasPrompted = true;

    final decision = await AuthNavigationGuard.checkAccess(
      context: context,
      isLoggedIn: widget.isLoggedIn,
      policy: widget.policy,
    );

    if (!mounted || decision != AuthGuardDecision.goToLogin) {
      return;
    }
    await widget.onGoToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FullscreenFeedbackScaffold(
      onBackPressed: widget.onBackPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 44,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            widget.blockedHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => widget.onGoToLogin(context),
            icon: const Icon(Icons.login_rounded),
            label: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}
