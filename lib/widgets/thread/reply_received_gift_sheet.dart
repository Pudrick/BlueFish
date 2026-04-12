import 'dart:async';

import 'package:bluefish/models/thread/thread_gift_detail_page.dart';
import 'package:bluefish/services/thread/thread_gift_service.dart';
import 'package:flutter/material.dart';

const int _kDefaultGiftDetailPageSize = 20;

Future<void> showReplyReceivedGiftDetailSheet({
  required BuildContext context,
  required ThreadGiftService threadGiftService,
  required String tid,
  required String pid,
  int pageSize = _kDefaultGiftDetailPageSize,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) {
      return _ReplyReceivedGiftDetailSheet(
        threadGiftService: threadGiftService,
        tid: tid,
        pid: pid,
        pageSize: pageSize,
      );
    },
  );
}

class _ReplyReceivedGiftDetailSheet extends StatefulWidget {
  final ThreadGiftService threadGiftService;
  final String tid;
  final String pid;
  final int pageSize;

  const _ReplyReceivedGiftDetailSheet({
    required this.threadGiftService,
    required this.tid,
    required this.pid,
    required this.pageSize,
  });

  @override
  State<_ReplyReceivedGiftDetailSheet> createState() =>
      _ReplyReceivedGiftDetailSheetState();
}

class _ReplyReceivedGiftDetailSheetState
    extends State<_ReplyReceivedGiftDetailSheet> {
  static const double _kSheetHeightFactor = 0.55;
  static const double _kLoadMoreTriggerDistance = 220;

  List<ThreadGiftDetailItem> _items = const <ThreadGiftDetailItem>[];
  int _currentPage = 0;
  bool _hasNextPage = false;
  int _total = 0;
  int _totalPage = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _initialErrorMessage;
  String? _loadMoreErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialPage());
  }

  Future<void> _loadInitialPage() {
    return _loadPage(page: 1, reset: true);
  }

  Future<void> _loadPage({required int page, required bool reset}) async {
    if (reset) {
      setState(() {
        _isInitialLoading = true;
        _initialErrorMessage = null;
        _loadMoreErrorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _loadMoreErrorMessage = null;
      });
    }

    final result = await widget.threadGiftService.getThreadGiftDetailList(
      tid: widget.tid,
      pid: widget.pid,
      page: page,
      pageSize: widget.pageSize,
    );

    if (!mounted) {
      return;
    }

    result.when(
      success: (pageData) {
        setState(() {
          final resolvedItems = reset
              ? List<ThreadGiftDetailItem>.from(pageData.list)
              : <ThreadGiftDetailItem>[..._items, ...pageData.list];
          _items = resolvedItems;
          _currentPage = page;
          _hasNextPage = pageData.nextPage;
          _total = pageData.total;
          _totalPage = pageData.totalPage;
          _isInitialLoading = false;
          _isLoadingMore = false;
          _initialErrorMessage = null;
          _loadMoreErrorMessage = null;
        });
      },
      failure: (message, exception) {
        setState(() {
          if (reset) {
            _isInitialLoading = false;
            _initialErrorMessage = message;
            _hasNextPage = false;
          } else {
            _isLoadingMore = false;
            _loadMoreErrorMessage = message;
          }
        });
      },
    );
  }

  Future<void> _tryLoadMore() async {
    if (_isInitialLoading ||
        _isLoadingMore ||
        !_hasNextPage ||
        _currentPage < 1) {
      return;
    }

    await _loadPage(page: _currentPage + 1, reset: false);
  }

  String _buildSummary() {
    if (_total > 0) {
      return '共 $_total 个礼物';
    }
    if (_totalPage > 0) {
      return '共 $_totalPage 页';
    }
    return '礼物明细';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final sheetHeight = (availableHeight * _kSheetHeightFactor)
            .clamp(280.0, availableHeight)
            .toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    height: sheetHeight,
                    child: _buildSheetSurface(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetSurface(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      key: const ValueKey('reply-received-gift-sheet'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '收到的礼物',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildSummary(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('reply-received-gift-close-button'),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitialLoading) {
      return const _GiftSheetStateView(
        icon: Icons.hourglass_empty_rounded,
        title: '正在加载礼物记录',
        subtitle: '稍等一下，正在拉取该回复收到的礼物列表。',
        useProgress: true,
      );
    }

    final initialErrorMessage = _initialErrorMessage;
    if (initialErrorMessage != null) {
      return _GiftSheetStateView(
        icon: Icons.error_outline_rounded,
        title: '加载失败',
        subtitle: initialErrorMessage,
        action: FilledButton.tonalIcon(
          onPressed: () {
            unawaited(_loadInitialPage());
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重试'),
        ),
      );
    }

    if (_items.isEmpty) {
      return const _GiftSheetStateView(
        icon: Icons.card_giftcard_rounded,
        title: '暂无收到的礼物',
        subtitle: '这条回复暂时还没有收到礼物。',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _kLoadMoreTriggerDistance) {
          unawaited(_tryLoadMore());
        }
        return false;
      },
      child: ListView.separated(
        key: const ValueKey('reply-received-gift-list'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _GiftSheetFooter(
              isLoadingMore: _isLoadingMore,
              loadMoreErrorMessage: _loadMoreErrorMessage,
              hasNextPage: _hasNextPage,
              onRetry: _loadMoreErrorMessage == null
                  ? null
                  : () {
                      unawaited(_tryLoadMore());
                    },
            );
          }

          return _GiftSheetItem(gift: _items[index]);
        },
        separatorBuilder: (context, index) => index == _items.length - 1
            ? const SizedBox(height: 0)
            : const SizedBox(height: 8),
      ),
    );
  }
}

class _GiftSheetItem extends StatelessWidget {
  final ThreadGiftDetailItem gift;

  const _GiftSheetItem({required this.gift});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ValueKey(
        'reply-received-gift-item-${gift.giftId}-${gift.giverPuid}',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _SmallRoundImage(
            imageUrl: gift.giverAvatarUrl,
            size: 30,
            fallbackIcon: Icons.person_rounded,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gift.giverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '送出了礼物',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SmallRoundImage(
            imageUrl: gift.giftIconUrl,
            size: 28,
            fallbackIcon: Icons.card_giftcard_rounded,
          ),
          const SizedBox(width: 6),
          Text(
            'x${gift.giftNum}',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallRoundImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final IconData fallbackIcon;

  const _SmallRoundImage({
    required this.imageUrl,
    required this.size,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: imageUrl.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                ),
                child: Icon(
                  fallbackIcon,
                  size: size * 0.58,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                    ),
                    child: Icon(
                      fallbackIcon,
                      size: size * 0.58,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _GiftSheetFooter extends StatelessWidget {
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final bool hasNextPage;
  final VoidCallback? onRetry;

  const _GiftSheetFooter({
    required this.isLoadingMore,
    required this.loadMoreErrorMessage,
    required this.hasNextPage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '正在加载更多',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (loadMoreErrorMessage != null && onRetry != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              loadMoreErrorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试加载更多'),
            ),
          ],
        ),
      );
    }

    if (!hasNextPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '已显示全部礼物',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}

class _GiftSheetStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool useProgress;

  const _GiftSheetStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.useProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useProgress)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: colorScheme.primary,
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: colorScheme.onSurfaceVariant),
              ),
            if (!useProgress) const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
