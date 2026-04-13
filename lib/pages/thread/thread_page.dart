import 'dart:async';

import 'package:bluefish/auth/current_user_identity_controller.dart';
import 'package:bluefish/models/author_identity.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_recommend_state.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/auth_guard.dart';
import 'package:bluefish/services/thread/reply_light_action_service.dart';
import 'package:bluefish/services/thread/reply_light_record_service.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/services/thread/thread_gift_service.dart';
import 'package:bluefish/services/thread/thread_recommend_action_service.dart';
import 'package:bluefish/services/thread/thread_report_service.dart';
import 'package:bluefish/userdata/thread_recommend_status_store.dart';
import 'package:bluefish/utils/result.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/thread_detail_view_model.dart';
import 'package:bluefish/widgets/composer/reply_composer_sheet.dart';
import 'package:bluefish/widgets/common/fullscreen_feedback_scaffold.dart';
import 'package:bluefish/widgets/thread/reply_gift_sheet.dart';
import 'package:bluefish/widgets/thread/reply_received_gift_sheet.dart';
import 'package:bluefish/widgets/thread/thread_bottom_bar.dart';
import 'package:bluefish/widgets/thread/thread_lighted_replies_section.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/page_pill.dart';
import 'package:bluefish/widgets/thread/thread_pagination_bar.dart';
import 'package:bluefish/widgets/thread/thread_reply_sheet.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';

const double _threadBottomBarCompactReserveWidth = 68;
const double _threadBottomBarWideReserveWidth = 24;
const double _threadBottomBarReserveDecayStartWidth = 600;
const double _threadBottomBarReserveDecayEndWidth = 1024;

class _ThreadReportReasonOption {
  final String typeId;
  final String content;

  const _ThreadReportReasonOption({
    required this.typeId,
    required this.content,
  });
}

double resolveThreadBottomBarActionRightReserveWidth(double barWidth) {
  if (barWidth < _threadBottomBarReserveDecayStartWidth) {
    return _threadBottomBarCompactReserveWidth;
  }

  if (barWidth >= _threadBottomBarReserveDecayEndWidth) {
    return _threadBottomBarWideReserveWidth;
  }

  final progress =
      (barWidth - _threadBottomBarReserveDecayStartWidth) /
      (_threadBottomBarReserveDecayEndWidth -
          _threadBottomBarReserveDecayStartWidth);
  return _threadBottomBarCompactReserveWidth -
      ((_threadBottomBarCompactReserveWidth -
              _threadBottomBarWideReserveWidth) *
          progress);
}

/// Thread detail page entry point.
///
/// Creates a [ThreadDetailViewModel] and provides it to [_ThreadPageContent].
class ThreadPage extends StatelessWidget {
  final String tid;
  final int page;
  final String? targetPid;
  final AuthorIdentity? authorFilter;

  const ThreadPage._({
    super.key,
    required this.tid,
    required this.page,
    this.targetPid,
    this.authorFilter,
  });

  factory ThreadPage({
    Key? key,
    required dynamic tid,
    int page = 1,
    String? targetPid,
    String? onlyEuid,
    String? onlyPuid,
  }) {
    if (AppRoutes.parseThreadOnlyEuid(onlyEuid) != null &&
        AppRoutes.parseThreadOnlyPuid(onlyPuid) != null) {
      throw ArgumentError('onlyEuid and onlyPuid are mutually exclusive.');
    }
    final resolvedAuthorFilter = AppRoutes.parseThreadAuthorIdentity(
      onlyEuid: onlyEuid,
      onlyPuid: onlyPuid,
    );
    final resolvedTargetPid = AppRoutes.parseThreadTargetPid(targetPid);
    if (tid is String) {
      return ThreadPage._(
        key: key,
        tid: tid,
        page: page,
        targetPid: resolvedTargetPid,
        authorFilter: resolvedAuthorFilter,
      );
    } else if (tid is int) {
      return ThreadPage._(
        key: key,
        tid: tid.toString(),
        page: page,
        targetPid: resolvedTargetPid,
        authorFilter: resolvedAuthorFilter,
      );
    } else {
      throw ArgumentError(
        "tid only can be String or int, but get ${tid.runtimeType}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThreadDetailViewModel(
        tid: tid,
        initialPage: page,
        initialTargetPid: targetPid,
        initialAuthorFilter: authorFilter,
        service: context.read<ThreadDetailService>(),
      )..loadInitial(),
      child: const _ThreadPageContent(),
    );
  }
}

/// Internal stateful widget that consumes [ThreadDetailViewModel].
class _ThreadPageContent extends StatefulWidget {
  const _ThreadPageContent();

  @override
  State<_ThreadPageContent> createState() => _ThreadPageContentState();
}

class _ThreadPageContentState extends State<_ThreadPageContent> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _lightStateOverrides = <String, bool>{};
  final Set<String> _lightingReplyPids = <String>{};
  final Map<String, int> _lightCountOverrides = <String, int>{};
  final Map<String, int> _giftTotalOverrides = <String, int>{};
  final Set<String> _refreshingGiftTotalPids = <String>{};
  String? _lastSyncedLocation;
  String? _pendingTargetPid;
  String? _persistedLightedRequestKey;
  Future<Set<String>>? _persistedLightedFuture;
  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;
  bool _quickActionSyncScheduled = false;
  bool _targetLocateScheduled = false;
  int _targetLocateAttempts = 0;
  ThreadRecommendState _threadRecommendState = ThreadRecommendState.unknown;
  String? _threadRecommendHydratedTid;
  bool _didAttemptAutomaticThreadRecommendProbe = false;
  bool _isSubmittingMainThreadReport = false;
  bool _isSubmittingReplyReport = false;

  static const Duration _scrollAnimationDuration = Duration(milliseconds: 260);
  static const Duration _quickActionAnimationDuration = Duration(
    milliseconds: 180,
  );
  static const int _maxTargetLocateAttempts = 5;
  static const double _targetReplyAlignment = 0.04;
  static const String _giftTotalPlaceholder = '--';
  static const int _giftTotalRefreshPageSize = 20;
  static const double _floatingActionGroupBottomOffset = 12;
  static const List<_ThreadReportReasonOption> _mainThreadReportReasons =
      <_ThreadReportReasonOption>[
        _ThreadReportReasonOption(typeId: '1', content: '违反法律、时政敏感'),
        _ThreadReportReasonOption(typeId: '2', content: '未经许可的广告行为'),
        _ThreadReportReasonOption(typeId: '3', content: '色情淫秽、血腥暴恐'),
        _ThreadReportReasonOption(typeId: '4', content: '低俗谩骂、攻击引战'),
        _ThreadReportReasonOption(typeId: '5', content: '造谣造假、诈骗信息'),
        _ThreadReportReasonOption(typeId: '6', content: '其他恶意行为'),
        _ThreadReportReasonOption(typeId: '10', content: '侵权投诉'),
      ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPositionChanged);
    _scheduleQuickActionSync();
  }

  void _handleBack() {
    context.popOrGoThreadList();
  }

  void _jumpToPage(int page) {
    _clearPendingTarget();
    final viewModel = context.read<ThreadDetailViewModel>();
    if (page == viewModel.currentPage) {
      return;
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: _scrollAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }

    viewModel.jumpToPage(page);
  }

  void _scrollToTopIfNeeded() {
    _jumpToEdgeIfNeeded(toTop: true);
  }

  void _scrollToBottomIfNeeded() {
    _jumpToEdgeIfNeeded(toTop: false);
  }

  void _jumpToEdgeIfNeeded({required bool toTop}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = toTop ? position.minScrollExtent : position.maxScrollExtent;
    final alreadyAtEdge = toTop
        ? position.pixels <= target + 0.5
        : position.pixels >= target - 0.5;
    if (alreadyAtEdge) {
      return;
    }

    _scrollController.jumpTo(target);
    _settleJumpToEdge(toTop: toTop);
  }

  void _settleJumpToEdge({required bool toTop, int attempt = 0}) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = toTop ? position.minScrollExtent : position.maxScrollExtent;
    final reachedEdge = toTop
        ? position.pixels <= target + 0.5
        : position.pixels >= target - 0.5;

    if (reachedEdge || attempt >= 8) {
      _syncQuickActionsVisibility();
      return;
    }

    // Sliver max extent can grow while children are laid out, so settle over frames.
    _scrollController.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settleJumpToEdge(toTop: toTop, attempt: attempt + 1);
    });
  }

  Widget _buildAnimatedQuickScrollFab({
    required bool visible,
    required String heroTag,
    required VoidCallback onPressed,
    required String tooltip,
    required IconData icon,
  }) {
    return AnimatedSwitcher(
      duration: _quickActionAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.86, end: 1).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: visible
          ? Padding(
              key: ValueKey<String>('${heroTag}_visible'),
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.small(
                heroTag: heroTag,
                onPressed: onPressed,
                tooltip: tooltip,
                elevation: 0,
                child: Icon(icon, size: 20),
              ),
            )
          : SizedBox(key: ValueKey<String>('${heroTag}_hidden')),
    );
  }

  void _handleScrollPositionChanged() {
    _syncQuickActionsVisibility();
  }

  void _scheduleQuickActionSync() {
    if (_quickActionSyncScheduled) {
      return;
    }

    _quickActionSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickActionSyncScheduled = false;
      _syncQuickActionsVisibility();
    });
  }

  void _syncQuickActionsVisibility() {
    if (!mounted || !_scrollController.hasClients) {
      if (_showScrollToTop || _showScrollToBottom) {
        setState(() {
          _showScrollToTop = false;
          _showScrollToBottom = false;
        });
      }
      return;
    }

    const double edgeTolerance = 6;
    final position = _scrollController.position;
    final bool showScrollToTop = position.pixels > edgeTolerance;
    final bool showScrollToBottom =
        position.pixels < position.maxScrollExtent - edgeTolerance;

    if (showScrollToTop == _showScrollToTop &&
        showScrollToBottom == _showScrollToBottom) {
      return;
    }

    setState(() {
      _showScrollToTop = showScrollToTop;
      _showScrollToBottom = showScrollToBottom;
    });
  }

  Future<void> _applyAuthorFilter(AuthorIdentity identity) async {
    _clearPendingTarget();
    final viewModel = context.read<ThreadDetailViewModel>();
    if (viewModel.authorFilter == identity &&
        viewModel.currentPage == 1 &&
        viewModel.isLoaded) {
      return;
    }

    _scrollToTopIfNeeded();
    await viewModel.applyAuthorFilter(identity);
  }

  Future<void> _clearAuthorFilter() async {
    _clearPendingTarget();
    final viewModel = context.read<ThreadDetailViewModel>();
    if (!viewModel.hasAuthorFilter &&
        viewModel.currentPage == 1 &&
        viewModel.isLoaded) {
      return;
    }

    _scrollToTopIfNeeded();
    await viewModel.clearAuthorFilter();
  }

  void _syncRouteIfNeeded(ThreadDetailViewModel viewModel) {
    final targetLocation = AppRoutes.threadDetailLocation(
      tid: viewModel.tid,
      page: viewModel.currentPage,
      onlyEuid: viewModel.filterEuid,
      onlyPuid: viewModel.filterPuid,
    );
    if (_lastSyncedLocation == targetLocation) {
      return;
    }

    _lastSyncedLocation = targetLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final currentLocation = context.maybeGoRouterUri?.toString();
      final currentUri = context.maybeGoRouterUri;
      if (currentLocation == null || currentUri == null) {
        return;
      }

      if (currentUri.path != AppRoutes.threadDetailPathForTid(viewModel.tid)) {
        return;
      }

      if (currentLocation != targetLocation) {
        context.replaceThreadDetail(
          tid: viewModel.tid,
          page: viewModel.currentPage,
          onlyEuid: viewModel.filterEuid,
          onlyPuid: viewModel.filterPuid,
        );
      }
    });
  }

  void _consumePendingTargetIfNeeded(ThreadDetailViewModel viewModel) {
    if (_pendingTargetPid != null) {
      return;
    }

    final targetPid = viewModel.consumeTargetPid();
    if (targetPid == null || targetPid.isEmpty) {
      return;
    }

    _pendingTargetPid = targetPid;
    _targetLocateAttempts = 0;
    _scheduleTargetLocate();
  }

  void _clearPendingTarget() {
    _pendingTargetPid = null;
    _targetLocateAttempts = 0;
  }

  void _scheduleTargetLocate() {
    if (_targetLocateScheduled) {
      return;
    }

    _targetLocateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _targetLocateScheduled = false;
      _tryLocateTargetReply();
    });
  }

  void _tryLocateTargetReply() {
    if (!mounted) {
      return;
    }

    final targetPid = _pendingTargetPid;
    if (targetPid == null) {
      return;
    }

    final viewModel = context.read<ThreadDetailViewModel>();
    final data = viewModel.data;
    if (!viewModel.isLoaded || data == null) {
      _scheduleTargetLocate();
      return;
    }

    final targetIndex = data.replies.indexWhere(
      (reply) => reply.pid == targetPid,
    );
    if (targetIndex < 0) {
      _showTargetReplyNotFoundTip();
      _clearPendingTarget();
      return;
    }

    if (!_scrollController.hasClients) {
      if (_targetLocateAttempts >= _maxTargetLocateAttempts) {
        _showTargetReplyNotFoundTip();
        _clearPendingTarget();
        return;
      }

      _targetLocateAttempts += 1;
      _scheduleTargetLocate();
      return;
    }

    final targetContext = _findReplyCardContext(targetPid);
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: _targetReplyAlignment,
        duration: Duration.zero,
      );
      _clearPendingTarget();
      return;
    }

    if (_targetLocateAttempts >= _maxTargetLocateAttempts) {
      _showTargetReplyNotFoundTip();
      _clearPendingTarget();
      return;
    }

    _targetLocateAttempts += 1;
    _jumpNearReplyIndex(
      targetIndex: targetIndex,
      totalReplies: data.replies.length,
    );
    _scheduleTargetLocate();
  }

  BuildContext? _findReplyCardContext(String pid) {
    final targetKey = ValueKey<String>('reply-floor-card-$pid');
    BuildContext? result;

    void visit(Element element) {
      if (result != null) {
        return;
      }

      if (element.widget.key == targetKey) {
        result = element;
        return;
      }

      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return result;
  }

  void _jumpNearReplyIndex({
    required int targetIndex,
    required int totalReplies,
  }) {
    if (!_scrollController.hasClients || totalReplies <= 0) {
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) {
      return;
    }

    final ratio = ((targetIndex + 0.2) / totalReplies).clamp(0.0, 1.0);
    final roughOffset = (position.maxScrollExtent * ratio).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(roughOffset.toDouble());
  }

  void _showTargetReplyNotFoundTip() {
    _showTransientSnackBar('未找到目标回复，已停留在当前页。');
  }

  void _showTransientSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _ensureThreadRecommendStateHydrated({
    required String tid,
    required ThreadRecommendStatusStore store,
  }) {
    if (_threadRecommendHydratedTid == tid) {
      return;
    }

    _threadRecommendHydratedTid = tid;
    _didAttemptAutomaticThreadRecommendProbe = false;
    _threadRecommendState = ThreadRecommendState.unknown;
    unawaited(_loadPersistedThreadRecommendState(tid: tid, store: store));
  }

  Future<void> _loadPersistedThreadRecommendState({
    required String tid,
    required ThreadRecommendStatusStore store,
  }) async {
    final snapshot = await store.read(tid);
    if (!mounted || _threadRecommendHydratedTid != tid) {
      return;
    }

    final nextState = snapshot?.state ?? ThreadRecommendState.unknown;
    if (_threadRecommendState == nextState) {
      return;
    }

    setState(() {
      _threadRecommendState = nextState;
    });
  }

  void _maybeScheduleAutomaticThreadRecommendProbe({
    required bool autoProbeEnabled,
    required bool isLoggedIn,
    required String tid,
    required ThreadRecommendActionService threadRecommendActionService,
    required ThreadRecommendStatusStore threadRecommendStatusStore,
  }) {
    if (!autoProbeEnabled ||
        !isLoggedIn ||
        _didAttemptAutomaticThreadRecommendProbe ||
        _threadRecommendState != ThreadRecommendState.unknown ||
        _threadRecommendHydratedTid != tid) {
      return;
    }

    _didAttemptAutomaticThreadRecommendProbe = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _threadRecommendHydratedTid != tid ||
          _threadRecommendState != ThreadRecommendState.unknown) {
        return;
      }

      unawaited(
        _probeThreadRecommendState(
          isLoggedIn: isLoggedIn,
          tid: tid,
          threadRecommendActionService: threadRecommendActionService,
          threadRecommendStatusStore: threadRecommendStatusStore,
          silent: true,
        ),
      );
    });
  }

  Future<void> _probeThreadRecommendState({
    required bool isLoggedIn,
    required String tid,
    required ThreadRecommendActionService threadRecommendActionService,
    required ThreadRecommendStatusStore threadRecommendStatusStore,
    required bool silent,
  }) async {
    if (!isLoggedIn) {
      if (!silent) {
        _showTransientSnackBar('请先登录后再探测推荐状态');
      }
      return;
    }
    if (_threadRecommendState.isChecking) {
      return;
    }

    final previousState = _threadRecommendState;
    setState(() {
      _threadRecommendState = ThreadRecommendState.checking;
    });

    final recommendResult = await threadRecommendActionService.recommend(
      tid: tid,
    );

    if (!mounted || _threadRecommendHydratedTid != tid) {
      return;
    }

    if (recommendResult.isDuplicate) {
      const nextState = ThreadRecommendState.recommended;
      setState(() {
        _threadRecommendState = nextState;
      });
      await threadRecommendStatusStore.write(tid: tid, state: nextState);

      if (!silent) {
        _showTransientSnackBar('探测完成：当前已推荐');
      }
      return;
    }

    if (!recommendResult.isSuccess) {
      final failureMessage = recommendResult.message?.trim();
      setState(() {
        _threadRecommendState = previousState;
      });

      if (!silent) {
        _showTransientSnackBar(
          failureMessage == null || failureMessage.isEmpty
              ? '推荐状态探测失败，请稍后重试。'
              : failureMessage,
        );
      }
      return;
    }

    final cancelResult = await threadRecommendActionService.cancelRecommend(
      tid: tid,
    );

    if (!mounted || _threadRecommendHydratedTid != tid) {
      return;
    }

    if (cancelResult.isSuccess) {
      const nextState = ThreadRecommendState.notRecommended;
      setState(() {
        _threadRecommendState = nextState;
      });
      await threadRecommendStatusStore.write(tid: tid, state: nextState);

      if (!silent) {
        _showTransientSnackBar('探测完成：当前未推荐');
      }
      return;
    }

    const fallbackState = ThreadRecommendState.recommended;
    setState(() {
      _threadRecommendState = fallbackState;
    });
    await threadRecommendStatusStore.write(tid: tid, state: fallbackState);

    if (!silent) {
      final failureMessage = cancelResult.message?.trim();
      _showTransientSnackBar(
        failureMessage == null || failureMessage.isEmpty
            ? '探测完成但回滚失败，当前视为已推荐。'
            : '探测完成但回滚失败：$failureMessage',
      );
    }
  }

  Future<void> _handleThreadRecommendTap({
    required bool isLoggedIn,
    required String tid,
    required ThreadRecommendActionService threadRecommendActionService,
    required ThreadRecommendStatusStore threadRecommendStatusStore,
  }) async {
    if (!isLoggedIn) {
      _showTransientSnackBar('请先登录后再推荐');
      return;
    }
    if (_threadRecommendState.isChecking) {
      return;
    }

    final previousState = _threadRecommendState;
    final shouldCancelRecommend = previousState.isRecommended;

    setState(() {
      _threadRecommendState = ThreadRecommendState.checking;
    });

    final result = shouldCancelRecommend
        ? await threadRecommendActionService.cancelRecommend(tid: tid)
        : await threadRecommendActionService.recommend(tid: tid);

    if (!mounted || _threadRecommendHydratedTid != tid) {
      return;
    }

    final successState = shouldCancelRecommend
        ? ThreadRecommendState.notRecommended
        : ThreadRecommendState.recommended;

    if (result.isSuccess || result.isDuplicate) {
      setState(() {
        _threadRecommendState = successState;
      });
      await threadRecommendStatusStore.write(tid: tid, state: successState);

      if (result.isDuplicate) {
        final duplicateMessage = result.message?.trim();
        if (duplicateMessage != null && duplicateMessage.isNotEmpty) {
          _showTransientSnackBar(duplicateMessage);
        }
      }
      return;
    }

    final failureMessage = result.message?.trim();
    setState(() {
      _threadRecommendState = previousState;
    });
    _showTransientSnackBar(
      failureMessage == null || failureMessage.isEmpty
          ? (shouldCancelRecommend ? '取消推荐失败，请稍后重试。' : '推荐失败，请稍后重试。')
          : failureMessage,
    );
  }

  Future<void> _handleThreadDislikeTap({
    required bool isLoggedIn,
    required String tid,
    required ThreadRecommendActionService threadRecommendActionService,
    required ThreadRecommendStatusStore threadRecommendStatusStore,
  }) async {
    if (_threadRecommendState.isChecking) {
      return;
    }

    if (!isLoggedIn) {
      final decision = await AuthNavigationGuard.checkAccess(
        context: context,
        isLoggedIn: isLoggedIn,
        policy: AuthGuardPolicies.threadDislike,
      );
      if (!mounted) {
        return;
      }
      if (decision == AuthGuardDecision.goToLogin) {
        await context.pushLogin<void>();
      }
      if (!mounted) {
        return;
      }
      return;
    }

    final previousState = _threadRecommendState;
    setState(() {
      _threadRecommendState = ThreadRecommendState.checking;
    });

    final result = await threadRecommendActionService.downvote(tid: tid);

    if (!mounted || _threadRecommendHydratedTid != tid) {
      return;
    }

    if (result.isSuccess || result.isDuplicate) {
      const nextState = ThreadRecommendState.notRecommended;
      setState(() {
        _threadRecommendState = nextState;
      });
      await threadRecommendStatusStore.write(tid: tid, state: nextState);

      if (result.isDuplicate) {
        final duplicateMessage = result.message?.trim();
        if (duplicateMessage != null && duplicateMessage.isNotEmpty) {
          _showTransientSnackBar(duplicateMessage);
        }
      }
      return;
    }

    final failureMessage = result.message?.trim();
    setState(() {
      _threadRecommendState = previousState;
    });
    _showTransientSnackBar(
      failureMessage == null || failureMessage.isEmpty
          ? '点踩失败，请稍后重试。'
          : failureMessage,
    );
  }

  Future<void> _handleThreadRecommendProbeTap({
    required bool isLoggedIn,
    required String tid,
    required ThreadRecommendActionService threadRecommendActionService,
    required ThreadRecommendStatusStore threadRecommendStatusStore,
  }) {
    return _probeThreadRecommendState(
      isLoggedIn: isLoggedIn,
      tid: tid,
      threadRecommendActionService: threadRecommendActionService,
      threadRecommendStatusStore: threadRecommendStatusStore,
      silent: false,
    );
  }

  Future<_ThreadReportReasonOption?> _showMainThreadReportReasonSheet() {
    return showModalBottomSheet<_ThreadReportReasonOption>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    '选择举报原因',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final reason in _mainThreadReportReasons)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(reason.content),
                    onTap: () => Navigator.of(sheetContext).pop(reason),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveThreadReportSuccessMessage(String rawMessage) {
    final normalizedMessage = rawMessage.trim();
    if (normalizedMessage.isEmpty || normalizedMessage == '成功') {
      return '举报成功';
    }
    return normalizedMessage;
  }

  Future<void> _handleMainThreadReportTap({
    required bool isLoggedIn,
    required String tid,
    required String topicId,
    required ThreadReportService threadReportService,
  }) async {
    if (_isSubmittingMainThreadReport) {
      return;
    }

    if (!isLoggedIn) {
      final decision = await AuthNavigationGuard.checkAccess(
        context: context,
        isLoggedIn: isLoggedIn,
        policy: AuthGuardPolicies.threadReport,
      );
      if (!mounted) {
        return;
      }
      if (decision == AuthGuardDecision.goToLogin) {
        await context.pushLogin<void>();
      }
      if (!mounted) {
        return;
      }
      return;
    }

    final selectedReason = await _showMainThreadReportReasonSheet();
    if (!mounted || selectedReason == null) {
      return;
    }

    setState(() {
      _isSubmittingMainThreadReport = true;
    });

    late final Result<String> result;
    try {
      result = await threadReportService.reportThread(
        tid: tid,
        topicId: topicId,
        typeId: selectedReason.typeId,
        content: selectedReason.content,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingMainThreadReport = false;
        });
      } else {
        _isSubmittingMainThreadReport = false;
      }
    }

    if (!mounted) {
      return;
    }

    result.when(
      success: (message) {
        _showTransientSnackBar(_resolveThreadReportSuccessMessage(message));
      },
      failure: (message, exception) {
        final normalizedMessage = message.trim();
        _showTransientSnackBar(
          normalizedMessage.isEmpty ? '举报失败，请稍后重试。' : normalizedMessage,
        );
      },
    );
  }

  Future<void> _handleReplyReportTap({
    required bool isLoggedIn,
    required String tid,
    required String topicId,
    required String pid,
    required ThreadReportService threadReportService,
  }) async {
    if (_isSubmittingReplyReport) {
      return;
    }

    if (!isLoggedIn) {
      final decision = await AuthNavigationGuard.checkAccess(
        context: context,
        isLoggedIn: isLoggedIn,
        policy: AuthGuardPolicies.replyReport,
      );
      if (!mounted) {
        return;
      }
      if (decision == AuthGuardDecision.goToLogin) {
        await context.pushLogin<void>();
      }
      if (!mounted) {
        return;
      }
      return;
    }

    final selectedReason = await _showMainThreadReportReasonSheet();
    if (!mounted || selectedReason == null) {
      return;
    }

    setState(() {
      _isSubmittingReplyReport = true;
    });

    late final Result<String> result;
    try {
      result = await threadReportService.reportReply(
        tid: tid,
        topicId: topicId,
        pid: pid,
        typeId: selectedReason.typeId,
        content: selectedReason.content,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReplyReport = false;
        });
      } else {
        _isSubmittingReplyReport = false;
      }
    }

    if (!mounted) {
      return;
    }

    result.when(
      success: (message) {
        _showTransientSnackBar(_resolveThreadReportSuccessMessage(message));
      },
      failure: (message, exception) {
        final normalizedMessage = message.trim();
        _showTransientSnackBar(
          normalizedMessage.isEmpty ? '举报失败，请稍后重试。' : normalizedMessage,
        );
      },
    );
  }

  String? _resolvedActorKey({
    required String? currentActorKey,
    required String? currentUserPuid,
  }) {
    final normalizedActorKey = currentActorKey?.trim();
    if (normalizedActorKey != null && normalizedActorKey.isNotEmpty) {
      return normalizedActorKey;
    }

    final normalizedPuid = currentUserPuid?.trim();
    if (normalizedPuid == null || normalizedPuid.isEmpty) {
      return null;
    }
    return 'puid:$normalizedPuid';
  }

  bool _isReplyLighted({
    required String pid,
    required Set<String> persistedLightedPids,
  }) {
    final localOverride = _lightStateOverrides[pid];
    return localOverride ?? persistedLightedPids.contains(pid);
  }

  Set<String> _effectiveLightedPids({
    required Set<String> trackedReplyPids,
    required Set<String> persistedLightedPids,
  }) {
    return trackedReplyPids
        .where(
          (pid) => _isReplyLighted(
            pid: pid,
            persistedLightedPids: persistedLightedPids,
          ),
        )
        .toSet();
  }

  int _effectiveLightCount(SingleReplyFloor reply) {
    return _lightCountOverrides[reply.pid] ?? reply.lightCount;
  }

  String _effectiveGiftTotalDisplayText(SingleReplyFloor reply) {
    final total = _giftTotalOverrides[reply.pid];
    if (total == null) {
      return _giftTotalPlaceholder;
    }
    return '${total < 0 ? 0 : total}';
  }

  bool _isReplyGiftTotalRefreshing(String pid) {
    return _refreshingGiftTotalPids.contains(pid);
  }

  Future<void> _handleReplyGiftTotalRefreshTap({
    required SingleReplyFloor reply,
    required String tid,
    required ThreadGiftService threadGiftService,
  }) async {
    if (_refreshingGiftTotalPids.contains(reply.pid)) {
      return;
    }

    setState(() {
      _refreshingGiftTotalPids.add(reply.pid);
    });

    int? refreshedTotal;
    String? failureMessage;

    try {
      final result = await threadGiftService.getThreadGiftDetailList(
        tid: tid,
        pid: reply.pid,
        page: 1,
        pageSize: _giftTotalRefreshPageSize,
      );
      if (!mounted) {
        return;
      }

      result.when(
        success: (pageData) {
          refreshedTotal = pageData.total < 0 ? 0 : pageData.total;
        },
        failure: (message, exception) {
          final normalized = message.trim();
          failureMessage = normalized.isEmpty
              ? '收到礼物列表加载失败，请稍后重试。'
              : normalized;
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingGiftTotalPids.remove(reply.pid);
          if (refreshedTotal != null) {
            _giftTotalOverrides[reply.pid] = refreshedTotal!;
          }
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (failureMessage != null) {
      _showTransientSnackBar(failureMessage!);
    }
  }

  Future<void> _handleReplyGiftTap({
    required SingleReplyFloor reply,
    required String tid,
    required String? currentUserPuid,
    required ThreadGiftService threadGiftService,
  }) async {
    final errorMessage = await showReplyGiftBottomSheetForReply(
      context: context,
      reply: reply,
      threadGiftService: threadGiftService,
      onGiftTap: (targetReply, gift) {
        final normalizedCurrentUserPuid = currentUserPuid?.trim();
        if (normalizedCurrentUserPuid == null ||
            normalizedCurrentUserPuid.isEmpty) {
          return Future<Result<String>>.value(
            const Failure<String>('请先登录后再送礼'),
          );
        }

        final receiverPuid = targetReply.meta.author.puid.trim();
        if (receiverPuid.isEmpty) {
          return Future<Result<String>>.value(
            const Failure<String>('目标用户信息异常，暂时无法送礼'),
          );
        }

        return threadGiftService.giveGift(
          giftId: gift.giftId,
          givePuid: normalizedCurrentUserPuid,
          pid: targetReply.pid,
          receivePuid: receiverPuid,
          tid: tid,
        );
      },
      onViewReceivedGiftsTap: (targetReply) {
        unawaited(
          showReplyReceivedGiftDetailSheet(
            context: context,
            threadGiftService: threadGiftService,
            tid: tid,
            pid: targetReply.pid,
          ),
        );
      },
    );
    if (!mounted || errorMessage == null || errorMessage.isEmpty) {
      return;
    }
    _showTransientSnackBar(errorMessage);
  }

  VoidCallback? _buildReplyLightTapCallback({
    required SingleReplyFloor reply,
    required Set<String> persistedLightedPids,
    required ThreadDetailViewModel viewModel,
    required ReplyLightActionService replyLightActionService,
    required ReplyLightRecordService replyLightRecordService,
    required String? currentActorKey,
    required String? currentUserPuid,
  }) {
    if (_lightingReplyPids.contains(reply.pid)) {
      return null;
    }

    final isLighted = _isReplyLighted(
      pid: reply.pid,
      persistedLightedPids: persistedLightedPids,
    );

    return () {
      if (isLighted) {
        _handleReplyCancelLightTap(
          reply: reply,
          tid: viewModel.tid,
          replyLightActionService: replyLightActionService,
          replyLightRecordService: replyLightRecordService,
          currentActorKey: currentActorKey,
          currentUserPuid: currentUserPuid,
        );
        return;
      }

      _handleReplyLightTap(
        reply: reply,
        tid: viewModel.tid,
        replyLightActionService: replyLightActionService,
        replyLightRecordService: replyLightRecordService,
        currentActorKey: currentActorKey,
        currentUserPuid: currentUserPuid,
      );
    };
  }

  VoidCallback? _buildReplyUnlightTapCallback({
    required SingleReplyFloor reply,
    required ThreadDetailViewModel viewModel,
    required ReplyLightActionService replyLightActionService,
    required ReplyLightRecordService replyLightRecordService,
    required String? currentActorKey,
    required String? currentUserPuid,
  }) {
    if (_lightingReplyPids.contains(reply.pid)) {
      return null;
    }

    return () {
      unawaited(
        _handleReplyUnlightTap(
          reply: reply,
          tid: viewModel.tid,
          replyLightActionService: replyLightActionService,
          replyLightRecordService: replyLightRecordService,
          currentActorKey: currentActorKey,
          currentUserPuid: currentUserPuid,
        ),
      );
    };
  }

  Future<void> _handleReplyLightTap({
    required SingleReplyFloor reply,
    required String tid,
    required ReplyLightActionService replyLightActionService,
    required ReplyLightRecordService replyLightRecordService,
    required String? currentActorKey,
    required String? currentUserPuid,
  }) async {
    final normalizedPuid = currentUserPuid?.trim();
    if (normalizedPuid == null || normalizedPuid.isEmpty) {
      _showTransientSnackBar('请先登录后再点亮');
      return;
    }
    if (_lightingReplyPids.contains(reply.pid)) {
      return;
    }

    final actorKey = _resolvedActorKey(
      currentActorKey: currentActorKey,
      currentUserPuid: normalizedPuid,
    );

    setState(() {
      _lightingReplyPids.add(reply.pid);
    });

    final result = await replyLightActionService.lightReply(
      tid: tid,
      pid: reply.pid,
      puid: normalizedPuid,
    );

    if (actorKey != null && (result.isSuccess || result.isAlreadyLighted)) {
      await _persistReplyLightedRecord(
        replyLightRecordService: replyLightRecordService,
        actorKey: actorKey,
        tid: tid,
        pid: reply.pid,
      );
    }

    if (!mounted) {
      return;
    }

    String? snackBarMessage;
    final shouldMarkLighted = result.isSuccess || result.isAlreadyLighted;
    final shouldIncreaseLightCount = result.isSuccess;

    if (result.isAlreadyLighted) {
      snackBarMessage = result.message ?? '你已经点亮过这个回帖了';
    } else if (!result.isSuccess) {
      snackBarMessage = result.message ?? '点亮失败，请稍后重试。';
    }

    setState(() {
      _lightingReplyPids.remove(reply.pid);
      if (!shouldMarkLighted) {
        return;
      }

      _lightStateOverrides[reply.pid] = true;
      if (shouldIncreaseLightCount) {
        _lightCountOverrides[reply.pid] = _effectiveLightCount(reply) + 1;
      } else {
        _lightCountOverrides.putIfAbsent(reply.pid, () => reply.lightCount);
      }
    });

    if (snackBarMessage != null) {
      _showTransientSnackBar(snackBarMessage);
    }
  }

  Future<void> _handleReplyCancelLightTap({
    required SingleReplyFloor reply,
    required String tid,
    required ReplyLightActionService replyLightActionService,
    required ReplyLightRecordService replyLightRecordService,
    required String? currentActorKey,
    required String? currentUserPuid,
  }) async {
    final normalizedPuid = currentUserPuid?.trim();
    if (normalizedPuid == null || normalizedPuid.isEmpty) {
      _showTransientSnackBar('请先登录后再取消点亮');
      return;
    }
    if (_lightingReplyPids.contains(reply.pid)) {
      return;
    }

    final actorKey = _resolvedActorKey(
      currentActorKey: currentActorKey,
      currentUserPuid: normalizedPuid,
    );

    setState(() {
      _lightingReplyPids.add(reply.pid);
    });

    final result = await replyLightActionService.cancelLight(
      tid: tid,
      pid: reply.pid,
      puid: normalizedPuid,
    );

    if (actorKey != null && (result.isSuccess || result.isNotLighted)) {
      await _removeReplyLightedRecord(
        replyLightRecordService: replyLightRecordService,
        actorKey: actorKey,
        tid: tid,
        pid: reply.pid,
      );
    }

    if (!mounted) {
      return;
    }

    String? snackBarMessage;
    final shouldMarkUnlighted = result.isSuccess || result.isNotLighted;
    final shouldDecreaseLightCount = result.isSuccess;

    if (result.isNotLighted) {
      snackBarMessage = result.message ?? '请先点亮后再操作';
    } else if (!result.isSuccess) {
      snackBarMessage = result.message ?? '取消点亮失败，请稍后重试。';
    }

    setState(() {
      _lightingReplyPids.remove(reply.pid);
      if (!shouldMarkUnlighted) {
        return;
      }

      _lightStateOverrides[reply.pid] = false;
      if (shouldDecreaseLightCount) {
        final nextCount = _effectiveLightCount(reply) - 1;
        _lightCountOverrides[reply.pid] = nextCount < 0 ? 0 : nextCount;
      } else {
        _lightCountOverrides.putIfAbsent(reply.pid, () => reply.lightCount);
      }
    });

    if (snackBarMessage != null) {
      _showTransientSnackBar(snackBarMessage);
    }
  }

  Future<void> _handleReplyUnlightTap({
    required SingleReplyFloor reply,
    required String tid,
    required ReplyLightActionService replyLightActionService,
    required ReplyLightRecordService replyLightRecordService,
    required String? currentActorKey,
    required String? currentUserPuid,
  }) async {
    final normalizedPuid = currentUserPuid?.trim();
    if (normalizedPuid == null || normalizedPuid.isEmpty) {
      _showTransientSnackBar('请先登录后再点灭');
      return;
    }
    if (_lightingReplyPids.contains(reply.pid)) {
      return;
    }

    final actorKey = _resolvedActorKey(
      currentActorKey: currentActorKey,
      currentUserPuid: normalizedPuid,
    );

    setState(() {
      _lightingReplyPids.add(reply.pid);
    });

    final result = await replyLightActionService.unlightReply(
      tid: tid,
      pid: reply.pid,
      puid: normalizedPuid,
    );

    if (actorKey != null && (result.isSuccess || result.isAlreadyUnlighted)) {
      await _removeReplyLightedRecord(
        replyLightRecordService: replyLightRecordService,
        actorKey: actorKey,
        tid: tid,
        pid: reply.pid,
      );
    }

    if (!mounted) {
      return;
    }

    String? snackBarMessage;
    final shouldMarkUnlighted = result.isSuccess || result.isAlreadyUnlighted;
    final shouldDecreaseLightCount = result.isSuccess;

    if (result.isAlreadyUnlighted) {
      snackBarMessage = result.message ?? '你已经点灭过这个回帖了';
    } else if (!result.isSuccess) {
      snackBarMessage = result.message ?? '点灭失败，请稍后重试。';
    }

    setState(() {
      _lightingReplyPids.remove(reply.pid);
      if (!shouldMarkUnlighted) {
        return;
      }

      _lightStateOverrides[reply.pid] = false;
      if (shouldDecreaseLightCount) {
        _lightCountOverrides[reply.pid] = _effectiveLightCount(reply) - 1;
      } else {
        _lightCountOverrides.putIfAbsent(reply.pid, () => reply.lightCount);
      }
    });

    if (snackBarMessage != null) {
      _showTransientSnackBar(snackBarMessage);
    }
  }

  Future<void> _persistReplyLightedRecord({
    required ReplyLightRecordService replyLightRecordService,
    required String actorKey,
    required String tid,
    required String pid,
  }) async {
    try {
      await replyLightRecordService.markLighted(
        actorKey: actorKey,
        tid: tid,
        pid: pid,
      );
    } catch (_) {}
  }

  Future<void> _removeReplyLightedRecord({
    required ReplyLightRecordService replyLightRecordService,
    required String actorKey,
    required String tid,
    required String pid,
  }) async {
    try {
      await replyLightRecordService.unmarkLighted(
        actorKey: actorKey,
        tid: tid,
        pid: pid,
      );
    } catch (_) {}
  }

  void _ensurePersistedLightedFuture({
    required ReplyLightRecordService replyLightRecordService,
    required String? actorKey,
    required String tid,
    required Set<String> trackedReplyPids,
  }) {
    final requestKey = _persistedLightedRequestKeyFor(
      actorKey: actorKey,
      tid: tid,
      trackedReplyPids: trackedReplyPids,
    );
    if (_persistedLightedRequestKey == requestKey &&
        _persistedLightedFuture != null) {
      return;
    }

    _persistedLightedRequestKey = requestKey;
    _persistedLightedFuture = replyLightRecordService.findThreadLightedPids(
      actorKey: actorKey,
      tid: tid,
      pids: trackedReplyPids,
    );
  }

  String _persistedLightedRequestKeyFor({
    required String? actorKey,
    required String tid,
    required Set<String> trackedReplyPids,
  }) {
    final sortedPids = trackedReplyPids.toList()..sort();
    final normalizedActorKey = actorKey?.trim() ?? '';
    return '$normalizedActorKey|$tid|${sortedPids.join(',')}';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  double _pageMaxWidth(double viewportWidth) {
    if (viewportWidth >= 1440) {
      return 1240;
    }
    if (viewportWidth >= 1024) {
      return 1120;
    }
    return viewportWidth;
  }

  double _contentBodyMaxWidth(double viewportWidth) {
    if (viewportWidth >= 1440) {
      return 960;
    }
    if (viewportWidth >= 1024) {
      return 920;
    }
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserPuid = context
        .select<CurrentUserIdentityController, String?>(
          (identity) => identity.currentUserPuid,
        );
    final isCurrentUserLoggedIn = context
        .select<CurrentUserIdentityController, bool>(
          (identity) => identity.isLoggedIn,
        );
    final currentActorKey = context
        .select<CurrentUserIdentityController, String?>(
          (identity) => identity.currentActorKey,
        );
    final defaultCollapseLightedReplies = context
        .select<AppSettingsViewModel, bool>(
          (settings) => settings.settings.defaultCollapseLightedReplies,
        );
    final autoProbeThreadRecommendStatus = context
        .select<AppSettingsViewModel, bool>(
          (settings) => settings.settings.autoProbeThreadRecommendStatus,
        );
    final replyLightActionService = context.read<ReplyLightActionService>();
    final replyLightRecordService = context.read<ReplyLightRecordService>();
    final threadGiftService = context.read<ThreadGiftService>();
    final threadRecommendActionService = context
        .read<ThreadRecommendActionService>();
    final threadReportService = context.read<ThreadReportService>();
    final threadRecommendStatusStore = context
        .read<ThreadRecommendStatusStore>();

    return Consumer<ThreadDetailViewModel>(
      builder: (context, viewModel, child) {
        final interceptMessage = viewModel.consumeInterceptMessage();
        if (interceptMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            final router = context.maybeGoRouter;
            if (router != null && router.canPop()) {
              router.pop(ThreadDetailBlockedNavigationResult(interceptMessage));
              return;
            }

            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(interceptMessage),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          });

          return const Scaffold(body: SizedBox.expand());
        }

        _syncRouteIfNeeded(viewModel);
        _consumePendingTargetIfNeeded(viewModel);
        _scheduleQuickActionSync();

        // Loading state
        if (viewModel.isLoading && viewModel.data == null) {
          return FullscreenFeedbackScaffold(
            onBackPressed: _handleBack,
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        // Error state
        if (viewModel.isError && viewModel.data == null) {
          return FullscreenFeedbackScaffold(
            onBackPressed: _handleBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage ?? '加载失败',
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: viewModel.refresh,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // Loaded state
        final data = viewModel.data!;
        final normalizedCurrentUserPuid = currentUserPuid?.trim();
        final normalizedOpPuid = viewModel.opPuid?.trim();
        final bool isViewingOwnMainThread =
            normalizedCurrentUserPuid != null &&
            normalizedCurrentUserPuid.isNotEmpty &&
            normalizedCurrentUserPuid == normalizedOpPuid;
        final bool canPrev = viewModel.canGoPrev;
        final bool canNext = viewModel.canGoNext;
        final activeFilterLabel = _resolveActiveFilterLabel(viewModel, data);
        final trackedReplyPids = _trackedReplyPids(
          currentPage: viewModel.currentPage,
          data: data,
        );
        _ensureThreadRecommendStateHydrated(
          tid: viewModel.tid,
          store: threadRecommendStatusStore,
        );
        _maybeScheduleAutomaticThreadRecommendProbe(
          autoProbeEnabled: autoProbeThreadRecommendStatus,
          isLoggedIn: isCurrentUserLoggedIn,
          tid: viewModel.tid,
          threadRecommendActionService: threadRecommendActionService,
          threadRecommendStatusStore: threadRecommendStatusStore,
        );
        _ensurePersistedLightedFuture(
          replyLightRecordService: replyLightRecordService,
          actorKey: currentActorKey,
          tid: viewModel.tid,
          trackedReplyPids: trackedReplyPids,
        );

        return FutureBuilder<Set<String>>(
          key: ValueKey<String>(
            'persisted-lighted-${_persistedLightedRequestKey ?? ''}',
          ),
          initialData: const <String>{},
          future: _persistedLightedFuture,
          builder: (context, lightedPidsSnapshot) {
            final persistedLightedPids =
                lightedPidsSnapshot.data ?? const <String>{};
            final effectiveLightedPids = _effectiveLightedPids(
              trackedReplyPids: trackedReplyPids,
              persistedLightedPids: persistedLightedPids,
            );

            return Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final double horizontalPadding = constraints.maxWidth >= 720
                      ? 16
                      : 12;
                  final double contentBodyMaxWidth = _contentBodyMaxWidth(
                    constraints.maxWidth,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _pageMaxWidth(constraints.maxWidth),
                            ),
                            child: RefreshIndicator(
                              onRefresh: viewModel.refresh,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                slivers: [
                                  SliverPersistentHeader(
                                    delegate: StickyHeaderDelegate(
                                      height: viewModel.totalPages > 1
                                          ? 76
                                          : 64,
                                      child: ThreadTitleWidget(
                                        title: data.mainFloor.title,
                                        currentPage: viewModel.currentPage,
                                        totalPages: viewModel.totalPages,
                                        onBack: _handleBack,
                                      ),
                                    ),
                                    pinned: true,
                                  ),

                                  if (viewModel.hasAuthorFilter)
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        8,
                                        horizontalPadding,
                                        0,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: _ThreadAuthorFilterBanner(
                                          label: activeFilterLabel,
                                          onClearTap: () {
                                            _clearAuthorFilter();
                                          },
                                        ),
                                      ),
                                    ),

                                  if (viewModel.totalPages >= 1)
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        8,
                                        horizontalPadding,
                                        0,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: ThreadPaginationBar(
                                          currentPage: viewModel.currentPage,
                                          totalPages: viewModel.totalPages,
                                          firstButtonLabel: '跳至首页',
                                          lastButtonLabel: '跳至末页',
                                          onFirst: canPrev
                                              ? () => _jumpToPage(1)
                                              : null,
                                          onPrev: canPrev
                                              ? () => _jumpToPage(
                                                  viewModel.currentPage - 1,
                                                )
                                              : null,
                                          onNext: canNext
                                              ? () => _jumpToPage(
                                                  viewModel.currentPage + 1,
                                                )
                                              : null,
                                          onLast: canNext
                                              ? () => _jumpToPage(
                                                  viewModel.totalPages,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),

                                  if (viewModel.currentPage == 1)
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        4,
                                        horizontalPadding,
                                        0,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: ThreadMainFloorWidget(
                                          mainFloor: data.mainFloor,
                                          contentMaxWidth: contentBodyMaxWidth,
                                        ),
                                      ),
                                    ),

                                  if (viewModel.currentPage == 1 &&
                                      data.lightedReplies.isNotEmpty)
                                    SliverPadding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding,
                                      ),
                                      sliver: ThreadLightedRepliesSection(
                                        lightedReplies: data.lightedReplies,
                                        persistedLightedPids:
                                            effectiveLightedPids,
                                        lightingReplyPids: _lightingReplyPids,
                                        lightCountOverrides:
                                            _lightCountOverrides,
                                        initiallyCollapsed:
                                            defaultCollapseLightedReplies,
                                        contentMaxWidth: contentBodyMaxWidth,
                                        viewerPuid: currentUserPuid,
                                        onLightTapBuilder: (reply) {
                                          return _buildReplyLightTapCallback(
                                            reply: reply,
                                            persistedLightedPids:
                                                persistedLightedPids,
                                            viewModel: viewModel,
                                            replyLightActionService:
                                                replyLightActionService,
                                            replyLightRecordService:
                                                replyLightRecordService,
                                            currentActorKey: currentActorKey,
                                            currentUserPuid: currentUserPuid,
                                          );
                                        },
                                        onUnlightTapBuilder: (reply) {
                                          return _buildReplyUnlightTapCallback(
                                            reply: reply,
                                            viewModel: viewModel,
                                            replyLightActionService:
                                                replyLightActionService,
                                            replyLightRecordService:
                                                replyLightRecordService,
                                            currentActorKey: currentActorKey,
                                            currentUserPuid: currentUserPuid,
                                          );
                                        },
                                        onGiftTapBuilder: (reply) {
                                          return () {
                                            unawaited(
                                              _handleReplyGiftTap(
                                                reply: reply,
                                                tid: viewModel.tid,
                                                currentUserPuid:
                                                    currentUserPuid,
                                                threadGiftService:
                                                    threadGiftService,
                                              ),
                                            );
                                          };
                                        },
                                        giftTotalDisplayTextBuilder: (reply) {
                                          return _effectiveGiftTotalDisplayText(
                                            reply,
                                          );
                                        },
                                        isGiftTotalRefreshingBuilder: (reply) {
                                          return _isReplyGiftTotalRefreshing(
                                            reply.pid,
                                          );
                                        },
                                        onGiftRefreshTapBuilder: (reply) {
                                          return () {
                                            unawaited(
                                              _handleReplyGiftTotalRefreshTap(
                                                reply: reply,
                                                tid: viewModel.tid,
                                                threadGiftService:
                                                    threadGiftService,
                                              ),
                                            );
                                          };
                                        },
                                        onOnlySeeAuthorTapBuilder: (reply) {
                                          final identity = reply.meta.author
                                              .preferredIdentity();
                                          if (identity == null) {
                                            return null;
                                          }
                                          return () {
                                            _applyAuthorFilter(identity);
                                          };
                                        },
                                        onReplyTapBuilder: (reply) {
                                          return () {
                                            context.pushThreadReplyComposer(
                                              tid: viewModel.tid,
                                              pid: reply.pid,
                                              page: viewModel.currentPage,
                                              onlyEuid: viewModel.filterEuid,
                                              onlyPuid: viewModel.filterPuid,
                                              contextLabel:
                                                  _lightedReplyContextLabel(
                                                    reply,
                                                  ),
                                              contextPreview:
                                                  _replyContextPreviewFromHtml(
                                                    reply.contentHtml,
                                                  ),
                                            );
                                          };
                                        },
                                        onReportTapBuilder: (reply) {
                                          return () {
                                            unawaited(
                                              _handleReplyReportTap(
                                                isLoggedIn:
                                                    isCurrentUserLoggedIn,
                                                tid: viewModel.tid,
                                                topicId: data.topicId
                                                    .toString(),
                                                pid: reply.pid,
                                                threadReportService:
                                                    threadReportService,
                                              ),
                                            );
                                          };
                                        },
                                        onReplyChainTapBuilder: (reply) {
                                          if (reply.replyNum <= 0) {
                                            return null;
                                          }
                                          return () {
                                            showThreadReplySheet(
                                              context: context,
                                              tid: viewModel.tid,
                                              rootReply: reply,
                                              rootFloorNumber:
                                                  reply.serverFloorNumber,
                                              threadPage: viewModel.currentPage,
                                              onlyEuid: viewModel.filterEuid,
                                              onlyPuid: viewModel.filterPuid,
                                              onReportTap: (targetReply) {
                                                return _handleReplyReportTap(
                                                  isLoggedIn:
                                                      isCurrentUserLoggedIn,
                                                  tid: viewModel.tid,
                                                  topicId: data.topicId
                                                      .toString(),
                                                  pid: targetReply.pid,
                                                  threadReportService:
                                                      threadReportService,
                                                );
                                              },
                                            );
                                          };
                                        },
                                      ),
                                    ),

                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      8,
                                      horizontalPadding,
                                      0,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final reply = data.replies[index];
                                        final displayFloorNumber = reply
                                            .resolveFloorNumber(
                                              currentPage:
                                                  viewModel.currentPage,
                                              repliesPerPage:
                                                  viewModel.repliesPerPage,
                                              indexInPage: index,
                                            );

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: ReplyFloor(
                                            replyFloor: reply,
                                            isLightedByViewer:
                                                effectiveLightedPids.contains(
                                                  reply.pid,
                                                ),
                                            isLightingLightAction:
                                                _lightingReplyPids.contains(
                                                  reply.pid,
                                                ),
                                            isQuote: false,
                                            lightCountOverride:
                                                _lightCountOverrides[reply.pid],
                                            giftTotalDisplayText:
                                                _effectiveGiftTotalDisplayText(
                                                  reply,
                                                ),
                                            isGiftTotalRefreshing:
                                                _isReplyGiftTotalRefreshing(
                                                  reply.pid,
                                                ),
                                            viewerPuid: currentUserPuid,
                                            floorNumber: displayFloorNumber,
                                            contentMaxWidth:
                                                contentBodyMaxWidth,
                                            onGiftTap: () {
                                              unawaited(
                                                _handleReplyGiftTap(
                                                  reply: reply,
                                                  tid: viewModel.tid,
                                                  currentUserPuid:
                                                      currentUserPuid,
                                                  threadGiftService:
                                                      threadGiftService,
                                                ),
                                              );
                                            },
                                            onGiftRefreshTap: () {
                                              unawaited(
                                                _handleReplyGiftTotalRefreshTap(
                                                  reply: reply,
                                                  tid: viewModel.tid,
                                                  threadGiftService:
                                                      threadGiftService,
                                                ),
                                              );
                                            },
                                            onLightTap:
                                                _buildReplyLightTapCallback(
                                                  reply: reply,
                                                  persistedLightedPids:
                                                      persistedLightedPids,
                                                  viewModel: viewModel,
                                                  replyLightActionService:
                                                      replyLightActionService,
                                                  replyLightRecordService:
                                                      replyLightRecordService,
                                                  currentActorKey:
                                                      currentActorKey,
                                                  currentUserPuid:
                                                      currentUserPuid,
                                                ),
                                            onUnlightTap:
                                                _buildReplyUnlightTapCallback(
                                                  reply: reply,
                                                  viewModel: viewModel,
                                                  replyLightActionService:
                                                      replyLightActionService,
                                                  replyLightRecordService:
                                                      replyLightRecordService,
                                                  currentActorKey:
                                                      currentActorKey,
                                                  currentUserPuid:
                                                      currentUserPuid,
                                                ),
                                            onOnlySeeAuthorTap:
                                                reply.meta.author
                                                        .preferredIdentity() ==
                                                    null
                                                ? null
                                                : () {
                                                    _applyAuthorFilter(
                                                      reply.meta.author
                                                          .preferredIdentity()!,
                                                    );
                                                  },
                                            onReplyTap: () {
                                              context.pushThreadReplyComposer(
                                                tid: viewModel.tid,
                                                pid: reply.pid,
                                                page: viewModel.currentPage,
                                                onlyEuid: viewModel.filterEuid,
                                                onlyPuid: viewModel.filterPuid,
                                                contextLabel:
                                                    '回复给 $displayFloorNumber 楼 · ${reply.meta.author.name}',
                                                contextPreview:
                                                    _replyContextPreviewFromHtml(
                                                      reply.contentHtml,
                                                    ),
                                              );
                                            },
                                            onReportTap: () {
                                              unawaited(
                                                _handleReplyReportTap(
                                                  isLoggedIn:
                                                      isCurrentUserLoggedIn,
                                                  tid: viewModel.tid,
                                                  topicId: data.topicId
                                                      .toString(),
                                                  pid: reply.pid,
                                                  threadReportService:
                                                      threadReportService,
                                                ),
                                              );
                                            },
                                            onReplyChainTap: reply.replyNum > 0
                                                ? () {
                                                    showThreadReplySheet(
                                                      context: context,
                                                      tid: viewModel.tid,
                                                      rootReply: reply,
                                                      rootFloorNumber:
                                                          displayFloorNumber,
                                                      threadPage:
                                                          viewModel.currentPage,
                                                      onlyEuid:
                                                          viewModel.filterEuid,
                                                      onlyPuid:
                                                          viewModel.filterPuid,
                                                      onReportTap: (targetReply) {
                                                        return _handleReplyReportTap(
                                                          isLoggedIn:
                                                              isCurrentUserLoggedIn,
                                                          tid: viewModel.tid,
                                                          topicId: data.topicId
                                                              .toString(),
                                                          pid: targetReply.pid,
                                                          threadReportService:
                                                              threadReportService,
                                                        );
                                                      },
                                                    );
                                                  }
                                                : null,
                                          ),
                                        );
                                      }, childCount: data.replies.length),
                                    ),
                                  ),

                                  if (viewModel.totalPages >= 1)
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        4,
                                        horizontalPadding,
                                        0,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: ThreadPaginationBar(
                                          currentPage: viewModel.currentPage,
                                          totalPages: viewModel.totalPages,
                                          firstButtonLabel: '跳至首页',
                                          lastButtonLabel: '跳至末页',
                                          onFirst: canPrev
                                              ? () => _jumpToPage(1)
                                              : null,
                                          onPrev: canPrev
                                              ? () => _jumpToPage(
                                                  viewModel.currentPage - 1,
                                                )
                                              : null,
                                          onNext: canNext
                                              ? () => _jumpToPage(
                                                  viewModel.currentPage + 1,
                                                )
                                              : null,
                                          onLast: canNext
                                              ? () => _jumpToPage(
                                                  viewModel.totalPages,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),

                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 68),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PagePill(
                            currentPage: viewModel.currentPage,
                            totalPages: viewModel.totalPages,
                            onPageTap: () {
                              showPageMenu(
                                context: context,
                                currentPage: viewModel.currentPage,
                                totalPages: viewModel.totalPages,
                                onPageSelected: (int selectedPage) {
                                  _jumpToPage(selectedPage);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      // Loading overlay when switching pages
                      if (viewModel.isLoading && viewModel.data != null)
                        Container(
                          color: colorScheme.surface.withAlpha(180),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              bottomNavigationBar: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : MediaQuery.sizeOf(context).width;
                  final actionAreaRightReserveWidth =
                      resolveThreadBottomBarActionRightReserveWidth(barWidth);

                  return ThreadBottomBar(
                    recommendState: _threadRecommendState,
                    autoProbeThreadRecommendStatusEnabled:
                        autoProbeThreadRecommendStatus,
                    hasFavorated: false,
                    threadTid: viewModel.tid,
                    threadTitle: data.mainFloor.title,
                    actionAreaRightReserveWidth: actionAreaRightReserveWidth,
                    showReportAction: true,
                    isReportActionEnabled: !isViewingOwnMainThread,
                    onReportTap: () {
                      _handleMainThreadReportTap(
                        isLoggedIn: isCurrentUserLoggedIn,
                        tid: viewModel.tid,
                        topicId: data.topicId.toString(),
                        threadReportService: threadReportService,
                      );
                    },
                    isOnlyOpMode: viewModel.isOnlyOp,
                    onRecommendTap: () {
                      unawaited(
                        _handleThreadRecommendTap(
                          isLoggedIn: isCurrentUserLoggedIn,
                          tid: viewModel.tid,
                          threadRecommendActionService:
                              threadRecommendActionService,
                          threadRecommendStatusStore:
                              threadRecommendStatusStore,
                        ),
                      );
                    },
                    onRecommendRefreshTap: () {
                      unawaited(
                        _handleThreadRecommendProbeTap(
                          isLoggedIn: isCurrentUserLoggedIn,
                          tid: viewModel.tid,
                          threadRecommendActionService:
                              threadRecommendActionService,
                          threadRecommendStatusStore:
                              threadRecommendStatusStore,
                        ),
                      );
                    },
                    onDislikeTap: () {
                      unawaited(
                        _handleThreadDislikeTap(
                          isLoggedIn: isCurrentUserLoggedIn,
                          tid: viewModel.tid,
                          threadRecommendActionService:
                              threadRecommendActionService,
                          threadRecommendStatusStore:
                              threadRecommendStatusStore,
                        ),
                      );
                    },
                    onOnlyOpTap: () {
                      if (viewModel.isOnlyOp) {
                        _clearAuthorFilter();
                        return;
                      }
                      final opIdentity = data.mainFloor.meta.author
                          .preferredIdentity();
                      if (opIdentity == null) {
                        return;
                      }
                      _applyAuthorFilter(opIdentity);
                    },
                  );
                },
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(
                  bottom: _floatingActionGroupBottomOffset,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAnimatedQuickScrollFab(
                      visible: _showScrollToTop,
                      heroTag: 'thread_detail_scroll_top_fab',
                      onPressed: _scrollToTopIfNeeded,
                      tooltip: '滑至顶部',
                      icon: Icons.keyboard_double_arrow_up_rounded,
                    ),
                    _buildAnimatedQuickScrollFab(
                      visible: _showScrollToBottom,
                      heroTag: 'thread_detail_scroll_bottom_fab',
                      onPressed: _scrollToBottomIfNeeded,
                      tooltip: '滑至底部',
                      icon: Icons.keyboard_double_arrow_down_rounded,
                    ),
                    if (_showScrollToTop || _showScrollToBottom)
                      const SizedBox(height: 4),
                    FloatingActionButton(
                      heroTag: 'thread_detail_reply_fab',
                      onPressed: () {
                        showReplyComposerSheet(
                          context: context,
                          title: '发送回复',
                          contextLabel: '当前帖子',
                          contextPreview: data.mainFloor.title,
                          onSubmit: (draft) async {
                            if (!draft.hasPublishableContent) {
                              return;
                            }
                            // TODO: Implement reply submission
                            // After successful submission:
                            // viewModel.invalidateCache();
                            // viewModel.refresh();
                          },
                        );
                      },
                      tooltip: '发送回复',
                      elevation: 0,
                      child: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endContained,
            );
          },
        );
      },
    );
  }
}

class _ThreadAuthorFilterBanner extends StatelessWidget {
  final String label;
  final VoidCallback onClearTap;

  const _ThreadAuthorFilterBanner({
    required this.label,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('thread-author-filter-banner'),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前仅看：$label',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onClearTap, child: const Text('查看全部')),
        ],
      ),
    );
  }
}

String _resolveActiveFilterLabel(
  ThreadDetailViewModel viewModel,
  ThreadDetail data,
) {
  if (viewModel.isOnlyOp) {
    return '楼主 ${data.opName}';
  }

  final authorFilter = viewModel.authorFilter;
  if (authorFilter == null) {
    return data.opName;
  }

  for (final reply in data.replies) {
    if (authorFilter.matchesAuthor(reply.meta.author)) {
      return reply.meta.author.name;
    }
  }

  return '指定用户';
}

String _replyContextPreviewFromHtml(String html) {
  if (html.trim().isEmpty) {
    return '该回复未包含可预览的文字内容。';
  }

  final normalizedHtml = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');

  final plainText = html_parser.parseFragment(normalizedHtml).text ?? '';
  final collapsedWhitespace = plainText
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  if (collapsedWhitespace.isNotEmpty) {
    return collapsedWhitespace;
  }

  return '该回复包含图片或其他暂不支持预览的内容。';
}

String _lightedReplyContextLabel(SingleReplyFloor reply) {
  final floorNumber = reply.serverFloorNumber;
  if (floorNumber != null && floorNumber > 0) {
    return '回复给 $floorNumber 楼 · ${reply.meta.author.name}';
  }
  return '回复给亮回复 · ${reply.meta.author.name}';
}

Set<String> _trackedReplyPids({
  required int currentPage,
  required ThreadDetail data,
}) {
  final trackedPids = <String>{for (final reply in data.replies) reply.pid};
  if (currentPage == 1) {
    trackedPids.addAll(data.lightedReplies.map((reply) => reply.pid));
  }
  return trackedPids;
}
