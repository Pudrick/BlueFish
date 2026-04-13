import 'package:flutter/material.dart';

enum AuthGuardDecision { allow, stay, goToLogin }

@immutable
class AuthGuardPolicy {
  final String title;
  final String message;
  final String cancelButtonText;
  final String confirmButtonText;

  const AuthGuardPolicy({
    required this.title,
    required this.message,
    this.cancelButtonText = '取消',
    this.confirmButtonText = '去登录',
  });
}

class AuthGuardPolicies {
  const AuthGuardPolicies._();

  static const AuthGuardPolicy userHome = AuthGuardPolicy(
    title: '需要登录',
    message: '访问用户主页需要先登录，是否前往登录页？',
  );

  static const AuthGuardPolicy threadReport = AuthGuardPolicy(
    title: '需要登录',
    message: '举报主贴需要先登录，是否前往登录页？',
  );

  static const AuthGuardPolicy replyReport = AuthGuardPolicy(
    title: '需要登录',
    message: '举报回帖需要先登录，是否前往登录页？',
  );

  static const AuthGuardPolicy threadDislike = AuthGuardPolicy(
    title: '需要登录',
    message: '点踩主贴需要先登录，是否前往登录页？',
  );
}

class AuthNavigationGuard {
  const AuthNavigationGuard._();

  static Future<AuthGuardDecision> checkAccess({
    required BuildContext context,
    required bool isLoggedIn,
    required AuthGuardPolicy policy,
  }) async {
    if (isLoggedIn) {
      return AuthGuardDecision.allow;
    }

    final shouldGoToLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(policy.title),
          content: Text(policy.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(policy.cancelButtonText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(policy.confirmButtonText),
            ),
          ],
        );
      },
    );

    if (shouldGoToLogin == true) {
      return AuthGuardDecision.goToLogin;
    }
    return AuthGuardDecision.stay;
  }
}
