import 'package:bluefish/models/private_message_list.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/private_message_list_view_model.dart';
import 'package:bluefish/widgets/private_message/private_message_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrivateMessageListViewModel()..init(),
      child: const _MessagesPageView(),
    );
  }
}

class _MessagesPageView extends StatefulWidget {
  const _MessagesPageView();

  @override
  State<_MessagesPageView> createState() => _MessagesPageViewState();
}

class _MessagesPageViewState extends State<_MessagesPageView> {
  static const double _loadMoreTriggerDistance = 180;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreTriggerDistance) {
      return;
    }

    final viewModel = context.read<PrivateMessageListViewModel>();
    if (!viewModel.isLoading && viewModel.hasNextPage) {
      viewModel.loadMore();
    }
  }

  void _openConversation(PrivateMessagePeek messagePeek) {
    context.pushPrivateMessageDetail(
      puid: messagePeek.puid,
      title: messagePeek.nickName,
      avatarUrl: messagePeek.avatarUrl.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrivateMessageListViewModel>();
    final messagePeeks = viewModel.messagePeeks;
    final errorMessage = viewModel.errorMessage;
    final isInitialLoading = viewModel.isLoading && messagePeeks.isEmpty;
    final showEmptyState =
        !viewModel.isLoading &&
        messagePeeks.isEmpty &&
        (errorMessage == null || errorMessage.isEmpty);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _MessagesHeader(
                  unreadOnly: viewModel.unreadOnly,
                  totalCount: messagePeeks.length,
                  isBusy: viewModel.isLoading,
                  onUnreadOnlyChanged: viewModel.setUnreadOnly,
                ),
              ),
              if (isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessagesLoadingState(),
                )
              else if (errorMessage != null && messagePeeks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessagesErrorState(
                    message: errorMessage,
                    onRetry: viewModel.refresh,
                  ),
                )
              else if (showEmptyState)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessagesEmptyState(
                    unreadOnly: viewModel.unreadOnly,
                    onRefresh: viewModel.refresh,
                  ),
                )
              else ...[
                if (errorMessage != null && messagePeeks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _MessagesInlineError(
                      message: errorMessage,
                      onRetry: viewModel.refresh,
                    ),
                  ),
                PrivateMessageListWidget(
                  messagePeeks: messagePeeks,
                  isLoading: viewModel.isLoading,
                  isLastPage: viewModel.isLastPage,
                  onTap: _openConversation,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  final bool unreadOnly;
  final int totalCount;
  final bool isBusy;
  final Future<void> Function(bool) onUnreadOnlyChanged;

  const _MessagesHeader({
    required this.unreadOnly,
    required this.totalCount,
    required this.isBusy,
    required this.onUnreadOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '消息',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unreadOnly ? '当前仅显示未读会话' : '查看最近的私信会话',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('仅看未读'),
                selected: unreadOnly,
                onSelected: isBusy
                    ? null
                    : (selected) {
                        onUnreadOnlyChanged(selected);
                      },
              ),
              const SizedBox(width: 10),
              Text(
                '已加载 $totalCount 条会话',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessagesLoadingState extends StatelessWidget {
  const _MessagesLoadingState();

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
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载消息',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '稍等一下，马上把最近会话带出来',
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

class _MessagesEmptyState extends StatelessWidget {
  final bool unreadOnly;
  final Future<void> Function() onRefresh;

  const _MessagesEmptyState({
    required this.unreadOnly,
    required this.onRefresh,
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
            Icon(
              unreadOnly ? Icons.mark_email_read_outlined : Icons.mail_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              unreadOnly ? '暂时没有未读消息' : '暂无消息',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unreadOnly ? '可以切回全部消息看看' : '下拉刷新后再来看看',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

class _MessagesErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MessagesErrorState({required this.message, required this.onRetry});

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
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesInlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MessagesInlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
