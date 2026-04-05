import 'dart:async';

import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/services/thread_reply_service.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;

Future<void> showThreadReplySheet({
  required BuildContext context,
  required String tid,
  required SingleReplyFloor rootReply,
  int? rootFloorNumber,
  required int threadPage,
  String? onlyEuid,
  String? onlyPuid,
  ThreadReplyService? service,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return ThreadReplySheet(
        tid: tid,
        rootReply: rootReply,
        rootFloorNumber: rootFloorNumber,
        threadPage: threadPage,
        onlyEuid: onlyEuid,
        onlyPuid: onlyPuid,
        service: service,
      );
    },
  );
}

class ThreadReplySheet extends StatefulWidget {
  final String tid;
  final SingleReplyFloor rootReply;
  final int? rootFloorNumber;
  final int threadPage;
  final String? onlyEuid;
  final String? onlyPuid;
  final ThreadReplyService? service;

  const ThreadReplySheet({
    super.key,
    required this.tid,
    required this.rootReply,
    required this.rootFloorNumber,
    required this.threadPage,
    this.onlyEuid,
    this.onlyPuid,
    this.service,
  });

  @override
  State<ThreadReplySheet> createState() => _ThreadReplySheetState();
}

class _ThreadReplySheetState extends State<ThreadReplySheet> {
  static const double _kInitialSheetSize = 0.85;
  static const double _kMinSheetSize = 0.18;
  static const double _kMaxSheetSize = 0.96;
  static const double _kHandleFlingVelocity = 700;
  static const Duration _kSheetSettleDuration = Duration(milliseconds: 220);

  late final ThreadReplyService _service;
  late final ScrollController _contentScrollController;
  late final Map<String, _ReplyChainNodeState> _nodesByPid;
  late final List<String> _navigationStack;
  double _sheetSize = _kInitialSheetSize;
  bool _isHandleDragging = false;
  double? _dragStartSheetSize;
  double _dragOffset = 0;
  double? _draggedSheetSize;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ThreadReplyService();
    _contentScrollController = ScrollController();
    final rootNode = _ReplyChainNodeState(
      reply: widget.rootReply,
      floorNumber: widget.rootFloorNumber,
    );
    _nodesByPid = <String, _ReplyChainNodeState>{
      widget.rootReply.pid: rootNode,
    };
    _navigationStack = <String>[widget.rootReply.pid];
    unawaited(_ensureLoaded(rootNode));
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  _ReplyChainNodeState get _currentNode => _nodesByPid[_navigationStack.last]!;

  Future<void> _ensureLoaded(_ReplyChainNodeState node) async {
    if (node.hasLoadedInitial || node.isLoadingInitial) {
      return;
    }

    setState(() {
      node.isLoadingInitial = true;
      node.initialErrorMessage = null;
    });

    try {
      final page = await _service.getReplyPage(
        tid: widget.tid,
        pid: node.reply.pid,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        node.isLoadingInitial = false;
        node.hasLoadedInitial = true;
        node.replies
          ..clear()
          ..addAll(page.replies);
        node.nextPage = page.nextPage;
        node.loadMoreErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        node.isLoadingInitial = false;
        node.initialErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadMore(_ReplyChainNodeState node) async {
    if (node.isLoadingInitial ||
        node.isLoadingMore ||
        !node.hasNextPage ||
        node.nextPage <= 0) {
      return;
    }

    final nextPage = node.nextPage;
    setState(() {
      node.isLoadingMore = true;
      node.loadMoreErrorMessage = null;
    });

    try {
      final page = await _service.getReplyPage(
        tid: widget.tid,
        pid: node.reply.pid,
        page: nextPage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        node.isLoadingMore = false;
        node.replies.addAll(page.replies);
        node.nextPage = page.nextPage;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        node.isLoadingMore = false;
        node.loadMoreErrorMessage = error.toString();
      });
    }
  }

  void _openReplyChain(SingleReplyFloor reply) {
    final nextNode =
        _nodesByPid[reply.pid] ??
        _ReplyChainNodeState(
          reply: reply,
          floorNumber: reply.serverFloorNumber,
        );

    if (!_nodesByPid.containsKey(reply.pid)) {
      _nodesByPid[reply.pid] = nextNode;
    }

    setState(() {
      _navigationStack.add(reply.pid);
    });

    _resetBodyScrollPosition();
    unawaited(_ensureLoaded(nextNode));
  }

  void _handleBack() {
    if (_navigationStack.length <= 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _navigationStack.removeLast();
    });

    _resetBodyScrollPosition();
  }

  void _handleReplyTap(SingleReplyFloor reply) {
    final floorLabel =
        reply.serverFloorNumber != null && reply.serverFloorNumber! > 0
        ? '回复给 ${reply.serverFloorNumber} 楼 · ${reply.meta.author.name}'
        : '回复给 ${reply.meta.author.name}';

    context.pushThreadReplyComposer(
      tid: widget.tid,
      pid: reply.pid,
      page: widget.threadPage,
      onlyEuid: widget.onlyEuid,
      onlyPuid: widget.onlyPuid,
      contextLabel: floorLabel,
      contextPreview: _replyContextPreviewFromHtml(reply.contentHtml),
    );
  }

  void _resetBodyScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_contentScrollController.hasClients) {
        return;
      }
      _contentScrollController.jumpTo(0);
    });
  }

  double get _currentSheetSize => _sheetSize;

  void _handleSheetDragStart(DragStartDetails details) {
    setState(() {
      _isHandleDragging = true;
      _dragStartSheetSize = _currentSheetSize;
      _dragOffset = 0;
      _draggedSheetSize = _currentSheetSize;
    });
  }

  void _handleSheetDragUpdate(
    DragUpdateDetails details,
    double availableHeight,
  ) {
    if (availableHeight <= 0) {
      return;
    }

    final delta = details.primaryDelta ?? 0;
    if (delta == 0) {
      return;
    }

    _dragOffset += delta;
    final dragBaseSize = _dragStartSheetSize ?? _currentSheetSize;
    final nextSize = (dragBaseSize - (_dragOffset / availableHeight))
        .clamp(_kMinSheetSize, _kMaxSheetSize)
        .toDouble();
    if (!mounted) {
      return;
    }
    setState(() {
      _draggedSheetSize = nextSize;
      _sheetSize = nextSize;
    });
  }

  void _handleSheetDragEnd(DragEndDetails details) {
    final currentSize = _draggedSheetSize ?? _currentSheetSize;
    final velocity = details.primaryVelocity ?? 0;
    final targetSize = _resolveSheetTargetSize(currentSize, velocity);
    _handleSheetDragCancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _sheetSize = targetSize;
    });
  }

  void _handleSheetDragCancel() {
    if (!mounted) {
      _dragStartSheetSize = null;
      _dragOffset = 0;
      _draggedSheetSize = null;
      _isHandleDragging = false;
      return;
    }

    setState(() {
      _dragStartSheetSize = null;
      _dragOffset = 0;
      _draggedSheetSize = null;
      _isHandleDragging = false;
    });
  }

  double _resolveSheetTargetSize(double currentSize, double velocity) {
    if (velocity <= -_kHandleFlingVelocity) {
      return _kMaxSheetSize;
    }

    if (velocity >= _kHandleFlingVelocity) {
      return _kMinSheetSize;
    }

    const collapseThreshold = (_kMinSheetSize + _kInitialSheetSize) / 2;
    const expandThreshold = (_kInitialSheetSize + _kMaxSheetSize) / 2;

    if (currentSize <= collapseThreshold) {
      return _kMinSheetSize;
    }

    if (currentSize >= expandThreshold) {
      return _kMaxSheetSize;
    }

    return _kInitialSheetSize;
  }

  Widget _buildDragHandle({
    required ColorScheme colorScheme,
    required double availableHeight,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        key: const ValueKey('thread-reply-sheet-drag-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _handleSheetDragStart,
        onVerticalDragUpdate: (details) =>
            _handleSheetDragUpdate(details, availableHeight),
        onVerticalDragEnd: _handleSheetDragEnd,
        onVerticalDragCancel: _handleSheetDragCancel,
        child: SizedBox(
          height: 36,
          child: Center(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentNode = _currentNode;
    final canGoBack = _navigationStack.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final sheetHeight = (availableHeight * _sheetSize)
            .clamp(
              availableHeight * _kMinSheetSize,
              availableHeight * _kMaxSheetSize,
            )
            .toDouble();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedContainer(
                duration: _isHandleDragging
                    ? Duration.zero
                    : _kSheetSettleDuration,
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: sheetHeight,
                child: Material(
                  key: const ValueKey('thread-reply-sheet'),
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.42,
                        ),
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
                          padding: const EdgeInsets.only(top: 6),
                          child: _buildDragHandle(
                            colorScheme: colorScheme,
                            availableHeight: availableHeight,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: canGoBack
                                    ? IconButton(
                                        key: const ValueKey(
                                          'thread-reply-sheet-back',
                                        ),
                                        tooltip: '返回上一层',
                                        onPressed: _handleBack,
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                        ),
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      canGoBack ? '查看回复' : '回复列表',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _buildHeaderSubtitle(currentNode),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('thread-reply-sheet-close'),
                                tooltip: '关闭',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _buildSheetBody(currentNode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetBody(_ReplyChainNodeState node) {
    return NotificationListener<ScrollNotification>(
      key: ValueKey('list-${node.reply.pid}'),
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) {
          unawaited(_loadMore(node));
        }
        return false;
      },
      child: CustomScrollView(
        controller: _contentScrollController,
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _SourceReplySection(
                key: ValueKey('source-${node.reply.pid}'),
                reply: node.reply,
                floorNumber: node.floorNumber,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WeakSectionDivider(
                label: node.reply.replyNum > 0 ? '以下是回复' : '暂时还没有回复',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ..._buildReplyListSlivers(node),
        ],
      ),
    );
  }

  String _buildHeaderSubtitle(_ReplyChainNodeState node) {
    final floorLabel = node.floorNumber != null && node.floorNumber! > 0
        ? '#${node.floorNumber} · '
        : '';
    final replyCountLabel = node.reply.replyNum > 0
        ? '${node.reply.replyNum} 条回复'
        : '暂无回复';
    return '$floorLabel${node.reply.meta.author.name} · $replyCountLabel';
  }

  List<Widget> _buildReplyListSlivers(_ReplyChainNodeState node) {
    if (node.isLoadingInitial && node.replies.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _SheetStateView(
            icon: Icons.hourglass_empty_rounded,
            title: '正在加载回复',
            subtitle: '稍等一下，正在拉取这条回复下的内容。',
            useProgress: true,
          ),
        ),
      ];
    }

    if (node.initialErrorMessage != null && node.replies.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _SheetStateView(
            icon: Icons.error_outline_rounded,
            title: '加载失败',
            subtitle: node.initialErrorMessage!,
            action: FilledButton.tonalIcon(
              onPressed: () => unawaited(_ensureLoaded(node)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ),
        ),
      ];
    }

    if (node.replies.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _SheetStateView(
            icon: Icons.forum_outlined,
            title: '还没有回复',
            subtitle: '这条内容下面暂时没有新的回复。',
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == node.replies.length) {
              return _ReplyListFooter(
                isLoadingMore: node.isLoadingMore,
                loadMoreErrorMessage: node.loadMoreErrorMessage,
                onRetry: node.loadMoreErrorMessage == null
                    ? null
                    : () => unawaited(_loadMore(node)),
              );
            }

            final reply = node.replies[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == node.replies.length - 1 ? 0 : 10,
              ),
              child: ReplyFloor(
                replyFloor: reply,
                isQuote: false,
                floorNumber: reply.serverFloorNumber,
                imageHeroScope:
                    'thread-reply-sheet:${node.reply.pid}:reply:${reply.pid}',
                onReplyTap: () => _handleReplyTap(reply),
                onReplyChainTap: reply.replyNum > 0
                    ? () => _openReplyChain(reply)
                    : null,
                showOverflowAction: false,
              ),
            );
          }, childCount: node.replies.length + 1),
        ),
      ),
    ];
  }
}

class _ReplyChainNodeState {
  final SingleReplyFloor reply;
  final int? floorNumber;
  final List<SingleReplyFloor> replies = <SingleReplyFloor>[];
  bool hasLoadedInitial = false;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  String? initialErrorMessage;
  String? loadMoreErrorMessage;
  int nextPage = 0;

  _ReplyChainNodeState({required this.reply, required this.floorNumber});

  bool get hasNextPage => nextPage > 0;
}

class _SourceReplySection extends StatelessWidget {
  final SingleReplyFloor reply;
  final int? floorNumber;

  const _SourceReplySection({
    super.key,
    required this.reply,
    required this.floorNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _CollapsibleReplyCard(
            reply: reply,
            floorNumber: floorNumber,
            imageHeroScope: 'thread-reply-sheet:${reply.pid}:source',
          ),
        ),
      ),
    );
  }
}

class _CollapsibleReplyCard extends StatefulWidget {
  static const double maxCollapsedHeight = 280;

  final SingleReplyFloor reply;
  final int? floorNumber;
  final String imageHeroScope;

  const _CollapsibleReplyCard({
    required this.reply,
    required this.floorNumber,
    required this.imageHeroScope,
  });

  @override
  State<_CollapsibleReplyCard> createState() => _CollapsibleReplyCardState();
}

class _CollapsibleReplyCardState extends State<_CollapsibleReplyCard> {
  final GlobalKey _contentKey = GlobalKey();
  bool _isExpanded = false;
  bool _needsExpansion = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHeight();
    });
  }

  @override
  void didUpdateWidget(covariant _CollapsibleReplyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHeight();
    });
  }

  void _checkHeight() {
    final renderObject = _contentKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final needsExpansion =
        renderObject.size.height > _CollapsibleReplyCard.maxCollapsedHeight;
    if (!mounted || needsExpansion == _needsExpansion) {
      return;
    }

    setState(() {
      _needsExpansion = needsExpansion;
      if (!needsExpansion) {
        _isExpanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isExpanded ? _buildExpandedCard() : _buildCollapsedCard(),
        ),
        if (_needsExpansion)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('thread-reply-sheet-source-toggle'),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(
                _isExpanded ? '收起原文' : '展开原文',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedCard() {
    return _buildReplyCard();
  }

  Widget _buildCollapsedCard() {
    if (!_needsExpansion) {
      return _buildReplyCard();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: _CollapsibleReplyCard.maxCollapsedHeight,
          ),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: AbsorbPointer(child: _buildReplyCard()),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface,
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyCard() {
    return SizedBox(
      key: _contentKey,
      width: double.infinity,
      child: ReplyFloor(
        replyFloor: widget.reply,
        isQuote: false,
        floorNumber: widget.floorNumber,
        imageHeroScope: widget.imageHeroScope,
        showActionRow: false,
        showOverflowAction: false,
      ),
    );
  }
}

class _WeakSectionDivider extends StatelessWidget {
  final String label;

  const _WeakSectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SheetStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool useProgress;

  const _SheetStateView({
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

class _ReplyListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final VoidCallback? onRetry;

  const _ReplyListFooter({
    required this.isLoadingMore,
    required this.loadMoreErrorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (loadMoreErrorMessage != null && onRetry != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Text(
              '继续加载失败',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 8);
  }
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
