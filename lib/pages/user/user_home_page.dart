import 'package:bluefish/models/author_identity.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/models/user_home/user_home.dart';
import 'package:bluefish/models/user_home/user_home_reply.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/user_home_view_model.dart';
import 'package:bluefish/widgets/common/fullscreen_feedback_scaffold.dart';
import 'package:bluefish/widgets/user_home/user_home_display_select_widget.dart';
import 'package:bluefish/widgets/user_home/user_home_info_widget.dart';
import 'package:bluefish/widgets/user_home/user_home_reply_list_widget.dart';
import 'package:bluefish/widgets/user_home/user_home_thread_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomePage extends StatelessWidget {
  final AuthorIdentity userIdentity;

  const UserHomePage({super.key, required this.userIdentity});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserHomeViewModel>(
      create: (_) => UserHomeViewModel(userIdentity: userIdentity)..init(),
      child: const UserHomePageView(),
    );
  }
}

class UserHomePageView extends StatefulWidget {
  const UserHomePageView({super.key});

  @override
  State<UserHomePageView> createState() => _UserHomePageViewState();
}

class _UserHomePageViewState extends State<UserHomePageView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _infoSectionKey = GlobalKey();

  static const double _infoSectionVerticalPadding = 32;
  int _replyJumpRequestId = 0;
  bool _replyJumpInProgress = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final vm = context.read<UserHomeViewModel>();
      switch (vm.displayStatus) {
        case DisplayStatus.threads:
          if (!vm.isLoadingThreads) {
            vm.loadMoreThreads();
          }
          break;
        case DisplayStatus.replies:
          if (!vm.isLoadingReplies) {
            vm.loadMoreReplies();
          }
          break;
        case DisplayStatus.recommends:
          if (!vm.isLoadingRecommends) {
            vm.loadMoreRecommends();
          }
          break;
      }
    }
  }

  double _getContentStartOffset() {
    final context = _infoSectionKey.currentContext;
    final renderBox = context?.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) {
      return 0;
    }

    return renderBox.size.height + _infoSectionVerticalPadding;
  }

  void _scrollToContentStart() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = math
        .min(maxScrollExtent, math.max(0.0, _getContentStartOffset()))
        .toDouble();

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleBack() {
    context.popOrGoThreadList();
  }

  int _resolveReplyLocateBudget() {
    final settings = Provider.of<AppSettingsViewModel?>(
      context,
      listen: false,
    )?.settings;
    return settings?.replyLocateTotalProbeBudget ??
        AppSettings.defaultReplyLocateTotalProbeBudget;
  }

  int _resolveReplyLocateCacheMaxEntries() {
    final settings = Provider.of<AppSettingsViewModel?>(
      context,
      listen: false,
    )?.settings;
    return settings?.replyLocateCacheMaxEntries ??
        AppSettings.defaultReplyLocateCacheMaxEntries;
  }

  int _resolveReplyLocateCoarseProbeStride() {
    final settings = Provider.of<AppSettingsViewModel?>(
      context,
      listen: false,
    )?.settings;
    return settings?.replyLocateCoarseProbeStride ??
        AppSettings.defaultReplyLocateCoarseProbeStride;
  }

  bool _isReplyJumpCanceled(int requestId) {
    return !_replyJumpInProgress || _replyJumpRequestId != requestId;
  }

  void _cancelActiveReplyJump({bool hideSnackBar = true}) {
    if (_replyJumpInProgress) {
      _replyJumpInProgress = false;
      _replyJumpRequestId += 1;
    }
    if (hideSnackBar && mounted) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
  }

  void _showReplyJumpSnackBar(int requestId) {
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
              if (_replyJumpRequestId == requestId) {
                _cancelActiveReplyJump();
              }
            },
          ),
        ),
      );
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openThreadByReplyTarget({
    required int tid,
    required int pid,
  }) async {
    _cancelActiveReplyJump();

    final requestId = _replyJumpRequestId + 1;
    _replyJumpRequestId = requestId;
    _replyJumpInProgress = true;
    _showReplyJumpSnackBar(requestId);

    final locateResult = await context
        .read<ReplyPageLocatorService>()
        .locateReplyPage(
          tid: '$tid',
          pid: '$pid',
          probeBudget: _resolveReplyLocateBudget(),
          cacheMaxEntries: _resolveReplyLocateCacheMaxEntries(),
          coarseProbeStride: _resolveReplyLocateCoarseProbeStride(),
          isCanceled: () => _isReplyJumpCanceled(requestId),
        );

    if (!mounted || _isReplyJumpCanceled(requestId)) {
      return;
    }

    _replyJumpInProgress = false;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

    if (!locateResult.shouldNavigate || locateResult.resolvedPage == null) {
      final message = locateResult.message;
      if (message != null && message.isNotEmpty) {
        _showMessage(message);
      }
      return;
    }

    await context.pushThreadDetail(
      tid: '$tid',
      page: locateResult.resolvedPage!,
      targetPid: '$pid',
    );

    if (!mounted) {
      return;
    }
    final message = locateResult.message;
    if (message != null && message.isNotEmpty) {
      _showMessage(message);
    }
  }

  Future<void> _handleReplyTap(UserHomeReply reply) {
    return _openThreadByReplyTarget(tid: reply.tid, pid: reply.pid);
  }

  @override
  void dispose() {
    _cancelActiveReplyJump(hideSnackBar: false);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (viewModel.data == null) {
      return FullscreenFeedbackScaffold(
        onBackPressed: _handleBack,
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    UserHome data = viewModel.data!;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBack,
              ),
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  key: _infoSectionKey,
                  child: UserHomeInfoWidget(userHome: data),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: UserHomeDisplaySelectWidget(
                  onTabChanged: _scrollToContentStart,
                ),
              ),
            ),
            switch (viewModel.displayStatus) {
              DisplayStatus.threads => UserHomeThreadListWidget(
                threadsList: data.threads,
                isLoading: viewModel.isLoadingThreads,
                isLastPage: viewModel.isLastThreadPage,
                enableTitleBlurMask: true,
              ),
              DisplayStatus.replies => UserHomeReplyListWidget(
                replyList: data.replies,
                isLoading: viewModel.isLoadingReplies,
                isLastPage: viewModel.isLastReplyPage,
                onReplyTap: (reply) {
                  unawaited(_handleReplyTap(reply));
                },
              ),
              DisplayStatus.recommends => UserHomeThreadListWidget(
                threadsList: data.recommendThreads,
                isLoading: viewModel.isLoadingRecommends,
                isLastPage: viewModel.isLastRecommendPage,
                enableTitleBlurMask: false,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
