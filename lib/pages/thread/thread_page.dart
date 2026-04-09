import 'package:bluefish/models/author_identity.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/thread_detail_view_model.dart';
import 'package:bluefish/widgets/composer/reply_composer_sheet.dart';
import 'package:bluefish/widgets/common/fullscreen_feedback_scaffold.dart';
import 'package:bluefish/widgets/thread/thread_bottom_bar.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/page_pill.dart';
import 'package:bluefish/widgets/thread/thread_pagination_bar.dart';
import 'package:bluefish/widgets/thread/thread_reply_sheet.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';

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
      create: (_) => ThreadDetailViewModel(
        tid: tid,
        initialPage: page,
        initialTargetPid: targetPid,
        initialAuthorFilter: authorFilter,
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
  String? _lastSyncedLocation;
  String? _pendingTargetPid;
  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;
  bool _quickActionSyncScheduled = false;
  bool _targetLocateScheduled = false;
  int _targetLocateAttempts = 0;

  static const Duration _scrollAnimationDuration = Duration(milliseconds: 260);
  static const Duration _quickActionAnimationDuration = Duration(
    milliseconds: 180,
  );
  static const int _maxTargetLocateAttempts = 5;
  static const double _targetReplyAlignment = 0.04;

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
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('未找到目标回复，已停留在当前页。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        final bool canPrev = viewModel.canGoPrev;
        final bool canNext = viewModel.canGoNext;
        final activeFilterLabel = _resolveActiveFilterLabel(viewModel, data);

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
                                  height: viewModel.totalPages > 1 ? 76 : 64,
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
                                          currentPage: viewModel.currentPage,
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
                                        isQuote: false,
                                        floorNumber: displayFloorNumber,
                                        contentMaxWidth: contentBodyMaxWidth,
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

          bottomNavigationBar: ThreadBottomBar(
            hasRecommended: true,
            hasFavorated: false,
            threadTid: viewModel.tid,
            threadTitle: data.mainFloor.title,
            isOnlyOpMode: viewModel.isOnlyOp,
            onOnlyOpTap: () {
              if (viewModel.isOnlyOp) {
                _clearAuthorFilter();
                return;
              }
              final opIdentity = data.mainFloor.meta.author.preferredIdentity();
              if (opIdentity == null) {
                return;
              }
              _applyAuthorFilter(opIdentity);
            },
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
