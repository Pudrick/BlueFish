import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/thread_detail_view_model.dart';
import 'package:bluefish/widgets/composer/reply_composer_sheet.dart';
import 'package:bluefish/widgets/thread/thread_bottom_bar.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/page_pill.dart';
import 'package:bluefish/widgets/thread/thread_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';

/// Thread detail page entry point.
///
/// Creates a [ThreadDetailViewModel] and provides it to [_ThreadPageContent].
class ThreadPage extends StatelessWidget {
  final String tid;
  final int page;
  final String? onlyEuid;

  const ThreadPage._({
    super.key,
    required this.tid,
    required this.page,
    this.onlyEuid,
  });

  factory ThreadPage({
    Key? key,
    required dynamic tid,
    int page = 1,
    String? onlyEuid,
  }) {
    final normalizedOnlyEuid = AppRoutes.parseThreadOnlyEuid(onlyEuid);
    if (tid is String) {
      return ThreadPage._(
        key: key,
        tid: tid,
        page: page,
        onlyEuid: normalizedOnlyEuid,
      );
    } else if (tid is int) {
      return ThreadPage._(
        key: key,
        tid: tid.toString(),
        page: page,
        onlyEuid: normalizedOnlyEuid,
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
        initialFilterEuid: onlyEuid,
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

  void _scrollToTopIfNeeded() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _applyAuthorFilter(String euid) async {
    final viewModel = context.read<ThreadDetailViewModel>();
    if (viewModel.filterEuid == euid.trim() &&
        viewModel.currentPage == 1 &&
        viewModel.isLoaded) {
      return;
    }

    _scrollToTopIfNeeded();
    await viewModel.applyAuthorFilter(euid);
  }

  Future<void> _clearAuthorFilter() async {
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
                                            reply.meta.author.euid
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : () {
                                                _applyAuthorFilter(
                                                  reply.meta.author.euid,
                                                );
                                              },
                                        onReplyTap: () {
                                          context.pushThreadReplyComposer(
                                            tid: viewModel.tid,
                                            pid: reply.pid,
                                            page: viewModel.currentPage,
                                            onlyEuid: viewModel.filterEuid,
                                            contextLabel:
                                                '回复给 $displayFloorNumber 楼 · ${reply.meta.author.name}',
                                            contextPreview:
                                                _replyContextPreviewFromHtml(
                                                  reply.contentHtml,
                                                ),
                                          );
                                        },
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
              _applyAuthorFilter(data.opEuid);
            },
          ),
          floatingActionButton: FloatingActionButton(
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

  final filterEuid = viewModel.filterEuid;
  if (filterEuid == null) {
    return data.opName;
  }

  for (final reply in data.replies) {
    if (reply.meta.author.euid == filterEuid) {
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
