import 'package:bluefish/models/thread_list.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/viewModels/thread_list_view_model.dart';
import 'package:bluefish/widgets/thread/single_thread_title_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TitleListPageBody extends StatefulWidget {
  const TitleListPageBody({super.key});

  @override
  State<TitleListPageBody> createState() => _TitleListPageBodyState();
}

class _TitleListPageBodyState extends State<TitleListPageBody> {
  final ScrollController _scrollController = ScrollController();

  ThreadListBoard? _activeBoard;
  bool _pendingRestore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_saveCurrentBoardOffset);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_saveCurrentBoardOffset)
      ..dispose();
    super.dispose();
  }

  void _openThreadDetail(BuildContext context, int tid) {
    context.pushNamed(
      AppRouteNames.threadDetail,
      pathParameters: {'tid': tid.toString()},
    );
  }

  void _saveCurrentBoardOffset() {
    if (_pendingRestore ||
        !mounted ||
        _activeBoard == null ||
        !_scrollController.hasClients) {
      return;
    }

    context.read<ThreadListViewModel>().saveBoardScrollOffset(
      _activeBoard!,
      _scrollController.offset,
    );
  }

  void _onBoardChanged(ThreadListViewModel viewModel) {
    final nextBoard = viewModel.currentBoard;
    if (_activeBoard == nextBoard) {
      return;
    }

    if (_activeBoard != null && _scrollController.hasClients) {
      viewModel.saveBoardScrollOffset(_activeBoard!, _scrollController.offset);
    }

    _activeBoard = nextBoard;
    _pendingRestore = true;
  }

  void _restoreOffsetIfNeeded(
    ThreadListViewModel viewModel, {
    required bool canRestore,
  }) {
    if (!_pendingRestore) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || !canRestore) {
        return;
      }

      final targetOffset = viewModel.boardScrollOffset(viewModel.currentBoard);
      final position = _scrollController.position;
      final clampedOffset = targetOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();

      if ((_scrollController.offset - clampedOffset).abs() > 0.5) {
        _scrollController.jumpTo(clampedOffset);
      }

      _pendingRestore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer<ThreadListViewModel>(
          builder: (context, titleList, child) {
            _onBoardChanged(titleList);

            final isInitialLoading =
                titleList.isRefreshing && titleList.threadTitleList.isEmpty;
            final isEmpty =
                !titleList.isRefreshing && titleList.threadTitleList.isEmpty;
            final bool isEssenceBoard =
                titleList.currentBoard == ThreadListBoard.essence;
            final String boardLabel = titleList.currentBoardLabel;

            _restoreOffsetIfNeeded(
              titleList,
              canRestore: !isInitialLoading,
            );

            return ColoredBox(
              color: theme.colorScheme.surface,
              child: RefreshIndicator(
                onRefresh: titleList.refresh,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (isInitialLoading)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 16,
                        ),
                        child: _ThreadListLoadingState(
                          boardLabel: boardLabel,
                          isEssenceBoard: isEssenceBoard,
                        ),
                      )
                    else if (isEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 16,
                        ),
                        child: _ThreadListEmptyState(
                          onRefresh: titleList.refresh,
                          title: isEssenceBoard
                              ? '暂无精华帖'
                              : '这里暂时没有$boardLabel帖子',
                          description: isEssenceBoard
                              ? '稍后再来看看，或者下拉刷新试试'
                              : '可以下拉刷新，或者点下面再试一次',
                        ),
                      )
                    else ...[
                      if (titleList.isRefreshing)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: LinearProgressIndicator(
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                        ),
                      for (final title in titleList.threadTitleList)
                        SingleThreadTitleCard(
                          threadTitle: title,
                          showEssenceBadge: isEssenceBoard,
                          onTap: () => _openThreadDetail(context, title.tid),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ThreadListLoadingState extends StatelessWidget {
  final String boardLabel;
  final bool isEssenceBoard;

  const _ThreadListLoadingState({
    required this.boardLabel,
    required this.isEssenceBoard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载$boardLabel帖子列表',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEssenceBoard ? '下拉可以刷新精华列表' : '下拉也可以手动刷新',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadListEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String title;
  final String description;

  const _ThreadListEmptyState({
    required this.onRefresh,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 30,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
