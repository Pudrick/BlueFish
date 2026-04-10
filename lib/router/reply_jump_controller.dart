import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReplyJumpController {
  int _requestId = 0;
  bool _jumpInProgress = false;

  Future<void> open(
    BuildContext context, {
    required Object tid,
    required Object pid,
  }) async {
    cancel(context);

    final requestId = _requestId + 1;
    _requestId = requestId;
    _jumpInProgress = true;
    _showProgressSnackBar(context, requestId);

    final settings = Provider.of<AppSettingsViewModel?>(
      context,
      listen: false,
    )?.settings;
    final locateResult = await context
        .read<ReplyPageLocatorService>()
        .locateReplyPage(
          tid: tid.toString(),
          pid: pid.toString(),
          probeBudget:
              settings?.replyLocateTotalProbeBudget ??
              AppSettings.defaultReplyLocateTotalProbeBudget,
          cacheMaxEntries:
              settings?.replyLocateCacheMaxEntries ??
              AppSettings.defaultReplyLocateCacheMaxEntries,
          coarseProbeStride:
              settings?.replyLocateCoarseProbeStride ??
              AppSettings.defaultReplyLocateCoarseProbeStride,
          isCanceled: () => _isCanceled(requestId),
        );

    if (!context.mounted || _isCanceled(requestId)) {
      return;
    }

    _jumpInProgress = false;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

    if (!locateResult.shouldNavigate || locateResult.resolvedPage == null) {
      _showMessage(context, locateResult.message);
      return;
    }

    await context.pushThreadDetail(
      tid: tid.toString(),
      page: locateResult.resolvedPage!,
      targetPid: pid.toString(),
    );

    if (!context.mounted) {
      return;
    }
    _showMessage(context, locateResult.message);
  }

  void cancel(BuildContext context, {bool hideSnackBar = true}) {
    if (_jumpInProgress) {
      _jumpInProgress = false;
      _requestId += 1;
    }
    if (hideSnackBar && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
  }

  void dispose() {
    if (_jumpInProgress) {
      _jumpInProgress = false;
      _requestId += 1;
    }
  }

  bool _isCanceled(int requestId) {
    return !_jumpInProgress || _requestId != requestId;
  }

  void _showProgressSnackBar(BuildContext context, int requestId) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('正在跳转...'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: '取消',
            onPressed: () {
              if (_requestId == requestId) {
                cancel(context);
              }
            },
          ),
        ),
      );
  }

  void _showMessage(BuildContext context, String? message) {
    if (message == null || message.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
