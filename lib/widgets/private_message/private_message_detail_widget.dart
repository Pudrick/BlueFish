import 'dart:math' as math;

import 'package:bluefish/models/private_message_detail.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/private_message_detail_view_model.dart';
import 'package:bluefish/widgets/private_message/detail/private_message_detail_bubble.dart';
import 'package:bluefish/widgets/private_message/detail/private_message_detail_header.dart';
import 'package:bluefish/widgets/private_message/detail/private_message_detail_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrivateMessageDetailWidget extends StatefulWidget {
  final String? initialTitle;
  final String? initialAvatarUrl;
  final double bottomInset;

  const PrivateMessageDetailWidget({
    super.key,
    this.initialTitle,
    this.initialAvatarUrl,
    this.bottomInset = 24,
  });

  @override
  State<PrivateMessageDetailWidget> createState() =>
      _PrivateMessageDetailWidgetState();
}

class _PrivateMessageDetailWidgetState
    extends State<PrivateMessageDetailWidget> {
  static const double _loadMoreTriggerDistance = 80;

  final ScrollController _scrollController = ScrollController();

  bool _didInitialScrollToLatest = false;
  bool _pendingInitialScroll = false;
  bool _isLoadingOlder = false;

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
    final viewModel = context.read<PrivateMessageDetailViewModel>();
    _maybeLoadMoreOnTop(viewModel);
  }

  void _maybeLoadMoreOnTop(PrivateMessageDetailViewModel viewModel) {
    if (!_scrollController.hasClients ||
        _isLoadingOlder ||
        viewModel.isLoading ||
        !viewModel.hasNextPage ||
        viewModel.messages.isEmpty) {
      return;
    }

    if (_scrollController.position.pixels <= _loadMoreTriggerDistance) {
      _loadMorePreservingScroll(viewModel);
    }
  }

  Future<void> _loadMorePreservingScroll(
    PrivateMessageDetailViewModel viewModel,
  ) async {
    if (_isLoadingOlder || !_scrollController.hasClients) {
      return;
    }

    final oldPixels = _scrollController.position.pixels;
    final oldMaxScrollExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _isLoadingOlder = true;
    });

    try {
      await viewModel.loadMore();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        if (_scrollController.hasClients) {
          final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
          final scrollDelta = newMaxScrollExtent - oldMaxScrollExtent;
          final targetOffset = (oldPixels + math.max(0, scrollDelta)).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(targetOffset);
        }

        if (mounted) {
          setState(() {
            _isLoadingOlder = false;
          });
        }
      });
    }
  }

  void _scheduleInitialScrollToLatest() {
    if (_didInitialScrollToLatest || _pendingInitialScroll) {
      return;
    }

    _pendingInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingInitialScroll = false;

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didInitialScrollToLatest = true;
    });
  }

  List<SinglePrivateMessage> _orderedMessages(
    List<SinglePrivateMessage> messages,
  ) {
    final ordered = List<SinglePrivateMessage>.of(messages);
    ordered.sort((left, right) {
      final compareTime = left.createTime.compareTo(right.createTime);
      if (compareTime != 0) {
        return compareTime;
      }
      return left.pmid.compareTo(right.pmid);
    });
    return ordered;
  }

  List<_ConversationEntry> _buildEntries(List<SinglePrivateMessage> messages) {
    final entries = <_ConversationEntry>[];
    DateTime? currentDay;

    for (final message in messages) {
      final messageDay = DateUtils.dateOnly(message.createTime);
      if (currentDay == null || currentDay != messageDay) {
        currentDay = messageDay;
        entries.add(_DateDividerEntry(date: messageDay));
      }
      entries.add(_MessageEntry(message: message));
    }

    return entries;
  }

  SinglePrivateMessage? _resolveCounterpart(
    PrivateMessageDetailViewModel viewModel,
    List<SinglePrivateMessage> orderedMessages,
  ) {
    final loginPuid = viewModel.loginPuid;
    if (loginPuid != null) {
      for (final message in orderedMessages.reversed) {
        if (message.puid != loginPuid) {
          return message;
        }
      }
    }

    if (orderedMessages.isNotEmpty) {
      return orderedMessages.last;
    }

    return null;
  }

  double _conversationHeaderHeight(
    BuildContext context,
    PrivateMessageDetailViewModel viewModel,
  ) {
    final badgeCount = <bool>[
      viewModel.isSystem,
      viewModel.unread,
      viewModel.isBanned,
    ].where((isVisible) => isVisible).length;
    final baseHeight = switch (badgeCount) {
      0 => 92.0,
      1 => 122.0,
      _ => 160.0,
    };
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final extraTextHeight = math.max(0.0, textScaleFactor - 1) * 24;

    return baseHeight + extraTextHeight;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrivateMessageDetailViewModel>();
    final orderedMessages = _orderedMessages(viewModel.messages);
    final counterpart = _resolveCounterpart(viewModel, orderedMessages);
    final conversationEntries = _buildEntries(orderedMessages);
    final isInitialLoading = viewModel.isLoading && orderedMessages.isEmpty;

    if (orderedMessages.isNotEmpty) {
      _scheduleInitialScrollToLatest();
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PrivateMessageHeaderDelegate(
              height: _conversationHeaderHeight(context, viewModel),
              child: PrivateMessageConversationHeader(
                title:
                    counterpart?.nickName ??
                    widget.initialTitle ??
                    (viewModel.isSystem ? '系统消息' : '私信详情'),
                avatarUrl: counterpart?.avatarUrlStr ?? widget.initialAvatarUrl,
                totalMessages:
                    viewModel.pageInfo?.totalMessagesNum ??
                    orderedMessages.length,
                interval: viewModel.interval,
                isSystem: viewModel.isSystem,
                unread: viewModel.unread,
                isBanned: viewModel.isBanned,
                onBackPressed: () => context.popOrGoMessages(),
              ),
            ),
          ),
          if (isInitialLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: PrivateMessageHistoryStatusCard(
                  loadedCount: orderedMessages.length,
                  totalCount:
                      viewModel.pageInfo?.totalMessagesNum ??
                      orderedMessages.length,
                  hasNextPage: viewModel.hasNextPage,
                  isLoadingOlder: _isLoadingOlder,
                ),
              ),
            ),
            if (orderedMessages.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PrivateMessageEmptyConversationState(
                  isSystem: viewModel.isSystem,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  math.max(widget.bottomInset, 24),
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = conversationEntries[index];
                    return switch (entry) {
                      _DateDividerEntry() =>
                        PrivateMessageConversationDateDivider(date: entry.date),
                      _MessageEntry() => PrivateMessageBubble(
                        message: entry.message,
                        loginPuid: viewModel.loginPuid,
                      ),
                    };
                  }, childCount: conversationEntries.length),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

sealed class _ConversationEntry {
  const _ConversationEntry();
}

class _DateDividerEntry extends _ConversationEntry {
  final DateTime date;

  const _DateDividerEntry({required this.date});
}

class _MessageEntry extends _ConversationEntry {
  final SinglePrivateMessage message;

  const _MessageEntry({required this.message});
}
