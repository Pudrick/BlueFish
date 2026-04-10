import 'package:bluefish/models/author_identity.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:bluefish/models/user_home/user_home.dart';
import 'package:bluefish/models/user_home/user_home_reply.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/reply_jump_controller.dart';
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
  final ReplyJumpController _replyJumpController = ReplyJumpController();

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

  Future<void> _handleReplyTap(UserHomeReply reply) {
    return _replyJumpController.open(context, tid: reply.tid, pid: reply.pid);
  }

  @override
  void dispose() {
    _replyJumpController.dispose();
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
  static const double _verticalPadding = 8;

  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, _verticalPadding),
        child: Align(alignment: Alignment.center, child: child),
      ),
    );
  }

  @override
  double get maxExtent =>
      UserHomeDisplaySelectWidget.preferredHeight + _verticalPadding + 4;

  @override
  double get minExtent =>
      UserHomeDisplaySelectWidget.preferredHeight + _verticalPadding + 4;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
