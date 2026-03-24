import 'dart:math' as math;

import 'package:bluefish/models/private_message_detail.dart';
import 'package:bluefish/pages/photo_gallery_page.dart';
import 'package:bluefish/viewModels/private_message_detail_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrivateMessageDetailViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final orderedMessages = _orderedMessages(viewModel.messages);
    final counterpart = _resolveCounterpart(viewModel, orderedMessages);
    final conversationEntries = _buildEntries(orderedMessages);

    if (viewModel.isLoading && orderedMessages.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

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
            delegate: _PrivateMessageHeaderDelegate(
              height: viewModel.isBanned ? 114 : 96,
              child: _ConversationHeader(
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _HistoryStatusCard(
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
              child: _EmptyConversationState(isSystem: viewModel.isSystem),
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
                    _DateDividerEntry() => _ConversationDateDivider(
                      date: entry.date,
                    ),
                    _MessageEntry() => _PrivateMessageBubble(
                      message: entry.message,
                      loginPuid: viewModel.loginPuid,
                    ),
                  };
                }, childCount: conversationEntries.length),
              ),
            ),
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

class _ConversationHeader extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final int totalMessages;
  final int? interval;
  final bool isSystem;
  final bool unread;
  final bool isBanned;

  const _ConversationHeader({
    required this.title,
    required this.avatarUrl,
    required this.totalMessages,
    required this.interval,
    required this.isSystem,
    required this.unread,
    required this.isBanned,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final metaSegments = <String>['共 $totalMessages 条消息'];
    if (interval != null && interval! > 0) {
      metaSegments.add('发信间隔 ${interval}s');
    }

    return Material(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ConversationAvatar(
                  avatarUrl: avatarUrl,
                  size: 44,
                  fallbackIcon: isSystem
                      ? Icons.shield_outlined
                      : Icons.chat_bubble_outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metaSegments.join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isSystem)
                  _HeaderBadge(
                    icon: Icons.admin_panel_settings_outlined,
                    label: '系统消息',
                    foregroundColor: colorScheme.onSecondaryContainer,
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
                if (unread)
                  _HeaderBadge(
                    icon: Icons.mark_chat_unread_outlined,
                    label: '未读会话',
                    foregroundColor: colorScheme.onError,
                    backgroundColor: colorScheme.error,
                  ),
                if (isBanned)
                  _HeaderBadge(
                    icon: Icons.lock_outline,
                    label: '当前不可发信',
                    foregroundColor: colorScheme.onTertiaryContainer,
                    backgroundColor: colorScheme.tertiaryContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatusCard extends StatelessWidget {
  final int loadedCount;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingOlder;

  const _HistoryStatusCard({
    required this.loadedCount,
    required this.totalCount,
    required this.hasNextPage,
    required this.isLoadingOlder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget leading;
    final String title;
    final String subtitle;

    if (isLoadingOlder) {
      leading = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
      title = '正在加载更早消息';
      subtitle = '已载入 $loadedCount / $totalCount';
    } else if (hasNextPage) {
      leading = Icon(
        Icons.keyboard_double_arrow_up_rounded,
        size: 20,
        color: colorScheme.primary,
      );
      title = '上滑加载更早消息';
      subtitle = '当前已载入 $loadedCount / $totalCount';
    } else {
      leading = Icon(
        Icons.done_all_rounded,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      );
      title = '已经到最早消息';
      subtitle = '共 $totalCount 条消息';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  final bool isSystem;

  const _EmptyConversationState({required this.isSystem});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSystem ? Icons.inbox_outlined : Icons.forum_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isSystem ? '暂时没有系统消息' : '这个会话还没有内容',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉即可重新刷新消息列表',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationDateDivider extends StatelessWidget {
  final DateTime date;

  const _ConversationDateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class _PrivateMessageBubble extends StatelessWidget {
  final SinglePrivateMessage message;
  final int? loginPuid;

  const _PrivateMessageBubble({required this.message, required this.loginPuid});

  bool get _isMine => loginPuid != null && message.puid == loginPuid;

  Future<void> _copyMessage(BuildContext context) async {
    final plainText = _buildCopyableMessageText(message);
    if (plainText.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: plainText));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制消息'), duration: Duration(seconds: 1)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = _isMine
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final foregroundColor = _isMine
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: _isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isMine) ...[
            _ConversationAvatar(avatarUrl: message.avatarUrlStr),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: _isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm:ss',
                          ).format(message.createTime),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: () => _copyMessage(context),
                          tooltip: '复制消息',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          iconSize: 16,
                          color: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.content_copy_outlined),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(_isMine ? 20 : 8),
                      bottomRight: Radius.circular(_isMine ? 8 : 20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: SelectionArea(
                        child: _MessageBody(
                          message: message,
                          textColor: foregroundColor,
                          linkColor: _isMine
                              ? colorScheme.primary
                              : colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isMine) ...[
            const SizedBox(width: 8),
            _ConversationAvatar(avatarUrl: message.avatarUrlStr),
          ],
        ],
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  final SinglePrivateMessage message;
  final Color textColor;
  final Color linkColor;

  const _MessageBody({
    required this.message,
    required this.textColor,
    required this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasContent = message.content.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasContent)
          HtmlWidget(
            message.content,
            textStyle: textTheme.bodyLarge?.copyWith(
              color: textColor,
              height: 1.5,
            ),
          ),
        if (hasContent && message.cardPm != null) const SizedBox(height: 12),
        if (message.cardPm != null)
          _PrivateMessageCardAttachment(
            cardPm: message.cardPm!,
            messageId: message.pmid,
            accentColor: linkColor,
          ),
      ],
    );
  }
}

class _PrivateMessageCardAttachment extends StatelessWidget {
  final CardPm cardPm;
  final int messageId;
  final Color accentColor;

  const _PrivateMessageCardAttachment({
    required this.cardPm,
    required this.messageId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cardPm.images.isNotEmpty) ...[
            _PrivateMessageCardImageStrip(
              messageId: messageId,
              images: cardPm.images,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            cardPm.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (cardPm.intro.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cardPm.intro,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.open_in_new, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cardPm.redirection.text,
                    style: textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateMessageCardImageStrip extends StatefulWidget {
  final int messageId;
  final List<CardPmImage> images;

  const _PrivateMessageCardImageStrip({
    required this.messageId,
    required this.images,
  });

  @override
  State<_PrivateMessageCardImageStrip> createState() =>
      _PrivateMessageCardImageStripState();
}

class _PrivateMessageCardImageStripState
    extends State<_PrivateMessageCardImageStrip> {
  final ScrollController _scrollController = ScrollController();

  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightFade());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    _updateRightFade();
  }

  void _updateRightFade() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final shouldShowFade =
        widget.images.length > 1 &&
        position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 4;

    if (_showRightFade != shouldShowFade) {
      setState(() {
        _showRightFade = shouldShowFade;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 164,
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _updateRightFade(),
          );

          final imageWidth = (constraints.maxWidth * 0.74)
              .clamp(140.0, 220.0)
              .toDouble();

          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final image = widget.images[index];
                  final imageUrl = image.imageUrl.toString();

                  return SizedBox(
                    width: imageWidth,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoGalleryPage(
                              imageUrls: widget.images
                                  .map((item) => item.imageUrl.toString())
                                  .toList(),
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_showRightFade)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            colorScheme.surface.withValues(alpha: 0),
                            colorScheme.surface.withValues(alpha: 0.96),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final IconData fallbackIcon;

  const _ConversationAvatar({
    required this.avatarUrl,
    this.size = 36,
    this.fallbackIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(
                fallbackIcon,
                size: size * 0.56,
                color: colorScheme.onSurfaceVariant,
              )
            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: size * 0.56,
                    color: colorScheme.onSurfaceVariant,
                  );
                },
              ),
      ),
    );
  }
}

class _PrivateMessageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _PrivateMessageHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PrivateMessageHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

String _buildCopyableMessageText(SinglePrivateMessage message) {
  final segments = <String>[];

  final plainContent = _htmlToPlainText(message.content);
  if (plainContent.isNotEmpty) {
    segments.add(plainContent);
  }

  final cardPm = message.cardPm;
  if (cardPm != null) {
    final title = cardPm.title.trim();
    if (title.isNotEmpty) {
      segments.add(title);
    }

    final intro = cardPm.intro.trim();
    if (intro.isNotEmpty) {
      segments.add(intro);
    }

    final redirectText = cardPm.redirection.text.trim();
    if (redirectText.isNotEmpty) {
      segments.add(redirectText);
    }

    final redirectUrl = cardPm.redirection.redirUrl.toString().trim();
    if (redirectUrl.isNotEmpty) {
      segments.add(redirectUrl);
    }
  }

  return segments.join('\n\n').trim();
}

String _htmlToPlainText(String html) {
  if (html.trim().isEmpty) {
    return '';
  }

  final normalizedHtml = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');

  final plainText = html_parser.parseFragment(normalizedHtml).text ?? '';
  return plainText
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
