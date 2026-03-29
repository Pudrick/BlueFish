import 'package:bluefish/models/thread_list.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/widgets/thread/single_thread_title_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TitleListPageBody extends StatelessWidget {
  const TitleListPageBody({super.key});

  void _openThreadDetail(BuildContext context, int tid) {
    context.pushNamed(
      AppRouteNames.threadDetail,
      pathParameters: {'tid': tid.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer<ThreadTitleList>(
          builder: (context, titleList, child) {
            final isInitialLoading =
                titleList.isRefreshing && titleList.threadTitleList.isEmpty;
            final isEmpty =
                !titleList.isRefreshing && titleList.threadTitleList.isEmpty;

            return ColoredBox(
              color: theme.colorScheme.surface,
              child: RefreshIndicator(
                onRefresh: titleList.refresh,
                child: ListView(
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
                        child: const _ThreadListLoadingState(),
                      )
                    else if (isEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 16,
                        ),
                        child: _ThreadListEmptyState(
                          onRefresh: titleList.refresh,
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
  const _ThreadListLoadingState();

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
              '正在加载帖子列表',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '下拉也可以手动刷新',
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

  const _ThreadListEmptyState({required this.onRefresh});

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
              '这里暂时没有帖子',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '可以下拉刷新，或者点下面再试一次',
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
