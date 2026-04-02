import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/thread_detail_view_model.dart';
import 'package:bluefish/widgets/thread/thread_bottom_bar.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/page_pill.dart';
import 'package:bluefish/widgets/thread/thread_reply_sheet.dart';
import 'package:bluefish/widgets/thread/thread_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Thread detail page entry point.
///
/// Creates a [ThreadDetailViewModel] and provides it to [_ThreadPageContent].
class ThreadPage extends StatelessWidget {
  final String tid;
  final int page;

  const ThreadPage._({super.key, required this.tid, required this.page});

  factory ThreadPage({Key? key, required dynamic tid, int page = 1}) {
    if (tid is String) {
      return ThreadPage._(key: key, tid: tid, page: page);
    } else if (tid is int) {
      return ThreadPage._(key: key, tid: tid.toString(), page: page);
    } else {
      throw ArgumentError(
        "tid only can be String or int, but get ${tid.runtimeType}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ThreadDetailViewModel(tid: tid, initialPage: page)..loadInitial(),
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

  void _handleBack() {
    context.popOrGoThreadList();
  }

  void _jumpToPage(int page) {
    final viewModel = context.read<ThreadDetailViewModel>();
    if (page == viewModel.currentPage) {
      return;
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    viewModel.jumpToPage(page);
  }

  void _syncRouteIfNeeded(ThreadDetailViewModel viewModel) {
    final targetLocation = AppRoutes.threadDetailLocation(
      tid: viewModel.tid,
      page: viewModel.currentPage,
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
      if (currentLocation == null) {
        return;
      }

      if (currentLocation != targetLocation) {
        context.replaceThreadDetail(
          tid: viewModel.tid,
          page: viewModel.currentPage,
        );
      }
    });
  }

  @override
  void dispose() {
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
      return 880;
    }
    if (viewportWidth >= 1024) {
      return 840;
    }
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ThreadDetailViewModel>(
      builder: (context, viewModel, child) {
        _syncRouteIfNeeded(viewModel);

        // Loading state
        if (viewModel.isLoading && viewModel.data == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            ),
          );
        }

        // Error state
        if (viewModel.isError && viewModel.data == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage ?? '加载失败',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: viewModel.refresh,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Loaded state
        final data = viewModel.data!;
        final bool canPrev = viewModel.canGoPrev;
        final bool canNext = viewModel.canGoNext;

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
                                    final int fallbackFloorNumber =
                                        ((viewModel.currentPage - 1) *
                                            viewModel.repliesPerPage) +
                                        index +
                                        1;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: ReplyFloor(
                                        replyFloor: data.replies[index],
                                        isQuote: false,
                                        floorNumber: fallbackFloorNumber,
                                        contentMaxWidth: contentBodyMaxWidth,
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showThreadReplySheet(
                context: context,
                title: '回复主题',
                contextLabel: '当前帖子',
                contextPreview: data.mainFloor.title,
                onSubmit: (content) async {
                  if (content.trim().isEmpty) {
                    return;
                  }
                  // TODO: Implement reply submission
                  // After successful submission:
                  // viewModel.invalidateCache();
                  // viewModel.refresh();
                },
              );
            },
            elevation: 0,
            child: const Icon(Icons.edit_outlined, size: 20),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.endContained,
        );
      },
    );
  }
}
