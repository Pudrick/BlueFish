import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/widgets/thread/thread_bottom_bar.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/page_pill.dart';
import 'package:bluefish/widgets/thread/thread_reply_sheet.dart';
import 'package:bluefish/widgets/thread/thread_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ThreadPage extends StatefulWidget {
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
  State<StatefulWidget> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late ThreadDetail threadDetail;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/');
  }

  Future<void> _loadData() async {
    await threadDetail.refresh();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _jumpToPage(int page) {
    if (page == threadDetail.currentPage) {
      return;
    }

    setState(() {
      threadDetail.currentPage = page;
      isLoading = true;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    _loadData();
  }

  @override
  void initState() {
    super.initState();
    threadDetail = ThreadDetail(widget.tid, page: widget.page);
    _loadData();
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

    if (isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    final bool canPrev = threadDetail.currentPage > 1;
    final bool canNext = threadDetail.currentPage < threadDetail.totalPagesNum;

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
                      onRefresh: _loadData,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPersistentHeader(
                            delegate: StickyHeaderDelegate(
                              height: threadDetail.totalPagesNum > 1 ? 76 : 64,
                              child: ThreadTitleWidget(
                                title: threadDetail.mainFloor.title,
                                currentPage: threadDetail.currentPage,
                                totalPages: threadDetail.totalPagesNum,
                                onBack: _handleBack,
                              ),
                            ),
                            pinned: true,
                          ),

                          if (threadDetail.totalPagesNum >= 1)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                8,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ThreadPaginationBar(
                                  currentPage: threadDetail.currentPage,
                                  totalPages: threadDetail.totalPagesNum,
                                  onPrev: canPrev
                                      ? () => _jumpToPage(
                                          threadDetail.currentPage - 1,
                                        )
                                      : null,
                                  onNext: canNext
                                      ? () => _jumpToPage(
                                          threadDetail.currentPage + 1,
                                        )
                                      : null,
                                ),
                              ),
                            ),

                          if (threadDetail.currentPage == 1)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                4,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ThreadMainFloorWidget(
                                  mainFloor: threadDetail.mainFloor,
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
                                    ((threadDetail.currentPage - 1) *
                                        threadDetail.repliesPerPage) +
                                    index +
                                    1;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ReplyFloor(
                                    replyFloor: threadDetail.replies[index],
                                    isQuote: false,
                                    floorNumber: fallbackFloorNumber,
                                    contentMaxWidth: contentBodyMaxWidth,
                                  ),
                                );
                              }, childCount: threadDetail.replies.length),
                            ),
                          ),

                          if (threadDetail.totalPagesNum >= 1)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                4,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ThreadPaginationBar(
                                  currentPage: threadDetail.currentPage,
                                  totalPages: threadDetail.totalPagesNum,
                                  onPrev: canPrev
                                      ? () => _jumpToPage(
                                          threadDetail.currentPage - 1,
                                        )
                                      : null,
                                  onNext: canNext
                                      ? () => _jumpToPage(
                                          threadDetail.currentPage + 1,
                                        )
                                      : null,
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(child: SizedBox(height: 68)),
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
                    currentPage: threadDetail.currentPage,
                    totalPages: threadDetail.totalPagesNum,
                    onPageTap: () {
                      showPageMenu(
                        context: context,
                        currentPage: threadDetail.currentPage,
                        totalPages: threadDetail.totalPagesNum,
                        onPageSelected: (int selectedPage) {
                          _jumpToPage(selectedPage);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: const ThreadBottomBar(
        hasRecommended: true,
        hasFavorated: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showThreadReplySheet(
            context: context,
            title: '回复主题',
            contextLabel: '当前帖子',
            contextPreview: threadDetail.mainFloor.title,
            onSubmit: (content) async {
              if (content.trim().isEmpty) {
                return;
              }
            },
          );
        },
        elevation: 0,
        child: const Icon(Icons.edit_outlined, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}
