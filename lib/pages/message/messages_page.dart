import 'dart:async';

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/models/mention/mention_light.dart';
import 'package:bluefish/models/mention/mention_reply.dart';
import 'package:bluefish/models/private_message/private_message_list.dart';
import 'package:bluefish/pages/message/mention_list_page_base.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/mention_light_view_model.dart';
import 'package:bluefish/viewModels/mention_reply_view_model.dart';
import 'package:bluefish/viewModels/private_message_list_view_model.dart';
import 'package:bluefish/widgets/mention/mention_light_widget.dart';
import 'package:bluefish/widgets/mention/mention_reply_widget.dart';
import 'package:bluefish/widgets/private_message/private_message_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessagesPage extends StatefulWidget {
  final MentionTab initialTab;

  const MessagesPage({super.key, this.initialTab = MentionTab.privateMessage});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late final MentionReplyViewModel _replyViewModel;
  late final MentionLightViewModel _lightViewModel;
  late final PrivateMessageListViewModel _privateMessageViewModel;
  late final TabController _tabController;

  late MentionTab _currentTab;

  bool _didInitReply = false;
  bool _didInitLight = false;
  bool _didInitPrivateMessage = false;
  String? _lastSyncedLocation;
  int _replyJumpRequestId = 0;
  bool _replyJumpInProgress = false;

  int get _replyUnreadCount => _replyViewModel.newList.length;
  int get _lightUnreadCount => _lightViewModel.newList.length;
  int get _privateUnreadCount => _privateMessageViewModel.messagePeeks
      .where((messagePeek) => messagePeek.isUnread)
      .length;

  @override
  void initState() {
    super.initState();
    _replyViewModel = MentionReplyViewModel();
    _lightViewModel = MentionLightViewModel();
    _privateMessageViewModel = PrivateMessageListViewModel();
    _currentTab = widget.initialTab;
    _tabController = TabController(
      length: MentionTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _ensureTabInitialized(_currentTab);
    for (final tab in MentionTab.values) {
      if (tab != _currentTab) {
        _ensureTabInitialized(tab);
      }
    }
  }

  @override
  void didUpdateWidget(covariant MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != _currentTab) {
      _setCurrentTab(widget.initialTab, animate: true);
    }
  }

  @override
  void dispose() {
    _cancelActiveReplyJump(hideSnackBar: false);
    _tabController.dispose();
    _replyViewModel.dispose();
    _lightViewModel.dispose();
    _privateMessageViewModel.dispose();
    super.dispose();
  }

  void _setCurrentTab(MentionTab tab, {bool animate = false}) {
    _ensureTabInitialized(tab);

    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }

    if (_tabController.index != tab.index) {
      if (animate) {
        _tabController.animateTo(tab.index);
      } else {
        _tabController.index = tab.index;
      }
    }
  }

  void _ensureTabInitialized(MentionTab tab) {
    switch (tab) {
      case MentionTab.reply:
        if (_didInitReply) {
          return;
        }
        _didInitReply = true;
        unawaited(_replyViewModel.init());
        return;
      case MentionTab.light:
        if (_didInitLight) {
          return;
        }
        _didInitLight = true;
        unawaited(_lightViewModel.init());
        return;
      case MentionTab.privateMessage:
        if (_didInitPrivateMessage) {
          return;
        }
        _didInitPrivateMessage = true;
        unawaited(_privateMessageViewModel.init());
        return;
    }
  }

  void _syncRouteIfNeeded() {
    final targetLocation = AppRoutes.messagesLocation(tab: _currentTab);
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
        context.replaceMessages(tab: _currentTab);
      }
    });
  }

  String _buildSubtitle() {
    return switch (_currentTab) {
      MentionTab.reply => '回复的点击跳转已经尽力了（）',
      MentionTab.light => '看看是不是裂天又来送祝福了',
      MentionTab.privateMessage => '查看最近私信会话，也可以切换到未读优先处理。',
    };
  }

  void _openConversation(PrivateMessagePeek messagePeek) {
    context.pushPrivateMessageDetail(
      puid: messagePeek.puid,
      title: messagePeek.nickName,
      avatarUrl: messagePeek.avatarUrl.toString(),
    );
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

  Future<void> _handleMentionReplyTap(MentionReply reply) {
    return _openThreadByReplyTarget(tid: reply.tid, pid: reply.pid);
  }

  Future<void> _handleMentionLightTap(MentionLight light) {
    return _openThreadByReplyTarget(tid: light.post.tid, pid: light.post.pid);
  }

  @override
  Widget build(BuildContext context) {
    _syncRouteIfNeeded();

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _replyViewModel,
            _lightViewModel,
            _privateMessageViewModel,
          ]),
          builder: (context, _) {
            return Column(
              children: [
                _MessagesHeader(subtitle: _buildSubtitle()),
                _MessagesTabBar(
                  controller: _tabController,
                  onTap: _setCurrentTab,
                  replyUnreadCount: _replyUnreadCount,
                  lightUnreadCount: _lightUnreadCount,
                  privateUnreadCount: _privateUnreadCount,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentTab.index,
                    children: [
                      _ReplyMessagesTab(
                        viewModel: _replyViewModel,
                        onOpenReply: (reply) {
                          unawaited(_handleMentionReplyTap(reply));
                        },
                      ),
                      _LightMessagesTab(
                        viewModel: _lightViewModel,
                        onOpenLight: (light) {
                          unawaited(_handleMentionLightTap(light));
                        },
                      ),
                      _PrivateMessagesTab(
                        viewModel: _privateMessageViewModel,
                        onOpenConversation: _openConversation,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  final String subtitle;

  const _MessagesHeader({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
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

class _MessagesTabBar extends StatelessWidget {
  final TabController controller;
  final ValueChanged<MentionTab> onTap;
  final int replyUnreadCount;
  final int lightUnreadCount;
  final int privateUnreadCount;

  const _MessagesTabBar({
    required this.controller,
    required this.onTap,
    required this.replyUnreadCount,
    required this.lightUnreadCount,
    required this.privateUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: TabBar.secondary(
          controller: controller,
          onTap: (index) => onTap(MentionTab.values[index]),
          labelColor: colorScheme.onPrimaryContainer,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
          indicator: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          splashBorderRadius: BorderRadius.circular(999),
          tabs: [
            Tab(
              height: 46,
              child: _MessagesTabLabel(
                badgeKeySuffix: 'reply',
                icon: Icons.reply_rounded,
                label: '回复',
                unreadCount: replyUnreadCount,
                badgeTone: _MessagesTabBadgeTone.alert,
              ),
            ),
            Tab(
              height: 46,
              child: _MessagesTabLabel(
                badgeKeySuffix: 'light',
                icon: Icons.thumb_up_alt_outlined,
                label: '点亮',
                unreadCount: lightUnreadCount,
                badgeTone: _MessagesTabBadgeTone.tonal,
              ),
            ),
            Tab(
              height: 46,
              child: _MessagesTabLabel(
                badgeKeySuffix: 'private',
                icon: Icons.mail_outline_rounded,
                label: '私信',
                unreadCount: privateUnreadCount,
                badgeTone: _MessagesTabBadgeTone.alert,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesTabLabel extends StatelessWidget {
  final String badgeKeySuffix;
  final IconData icon;
  final String label;
  final int unreadCount;
  final _MessagesTabBadgeTone badgeTone;

  const _MessagesTabLabel({
    required this.badgeKeySuffix,
    required this.icon,
    required this.label,
    required this.unreadCount,
    required this.badgeTone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
        if (unreadCount > 0) ...[
          const SizedBox(width: 8),
          _MessagesTabBadge(
            key: ValueKey('messages-tab-badge-$badgeKeySuffix'),
            count: unreadCount,
            tone: badgeTone,
          ),
        ],
      ],
    );
  }
}

enum _MessagesTabBadgeTone { alert, tonal }

class _MessagesTabBadge extends StatelessWidget {
  final int count;
  final _MessagesTabBadgeTone tone;

  const _MessagesTabBadge({super.key, required this.count, required this.tone});

  String get _label => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = switch (tone) {
      _MessagesTabBadgeTone.alert => colorScheme.error,
      _MessagesTabBadgeTone.tonal => colorScheme.secondaryContainer,
    };
    final foregroundColor = switch (tone) {
      _MessagesTabBadgeTone.alert => colorScheme.onError,
      _MessagesTabBadgeTone.tonal => colorScheme.onSecondaryContainer,
    };

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        _label,
        style: textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }
}

class _ReplyMessagesTab extends StatelessWidget {
  final MentionReplyViewModel viewModel;
  final ValueChanged<MentionReply> onOpenReply;

  const _ReplyMessagesTab({required this.viewModel, required this.onOpenReply});

  @override
  Widget build(BuildContext context) {
    return MentionListSection<MentionReply, MentionReplyViewModel>(
      viewModel: viewModel,
      bottomInset: 16,
      buildListSliver: (context, viewModel) => MentionReplyListWidget(
        newReplies: viewModel.newList,
        oldReplies: viewModel.oldList,
        hasNextPage: viewModel.hasNextPage,
        isLoading: viewModel.isLoading,
        onReplyTap: onOpenReply,
      ),
    );
  }
}

class _LightMessagesTab extends StatelessWidget {
  final MentionLightViewModel viewModel;
  final ValueChanged<MentionLight> onOpenLight;

  const _LightMessagesTab({required this.viewModel, required this.onOpenLight});

  @override
  Widget build(BuildContext context) {
    return MentionListSection<MentionLight, MentionLightViewModel>(
      viewModel: viewModel,
      bottomInset: 16,
      buildListSliver: (context, viewModel) => MentionLightListWidget(
        newLights: viewModel.newList,
        oldLights: viewModel.oldList,
        hasNextPage: viewModel.hasNextPage,
        isLoading: viewModel.isLoading,
        onLightTap: onOpenLight,
      ),
    );
  }
}

class _PrivateMessagesTab extends StatefulWidget {
  final PrivateMessageListViewModel viewModel;
  final ValueChanged<PrivateMessagePeek> onOpenConversation;

  const _PrivateMessagesTab({
    required this.viewModel,
    required this.onOpenConversation,
  });

  @override
  State<_PrivateMessagesTab> createState() => _PrivateMessagesTabState();
}

class _PrivateMessagesTabState extends State<_PrivateMessagesTab> {
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

    if (!widget.viewModel.isLoading && widget.viewModel.hasNextPage) {
      widget.viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrivateMessageListViewModel>.value(
      value: widget.viewModel,
      child: Consumer<PrivateMessageListViewModel>(
        builder: (context, viewModel, _) {
          final messagePeeks = viewModel.messagePeeks;
          final errorMessage = viewModel.errorMessage;
          final isInitialLoading = viewModel.isLoading && messagePeeks.isEmpty;
          final showEmptyState =
              !viewModel.isLoading &&
              messagePeeks.isEmpty &&
              (errorMessage == null || errorMessage.isEmpty);

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _PrivateMessagesToolbar(
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
                    onTap: widget.onOpenConversation,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrivateMessagesToolbar extends StatelessWidget {
  final bool unreadOnly;
  final int totalCount;
  final bool isBusy;
  final Future<void> Function(bool) onUnreadOnlyChanged;

  const _PrivateMessagesToolbar({
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unreadOnly ? '当前仅显示未读会话' : '切换到私信列表查看最近会话。',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
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
              '稍等一下，马上把最新动态带出来。',
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
              unreadOnly ? '可以切回全部消息看看。' : '下拉刷新后再来看看。',
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
