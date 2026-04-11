import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/widgets/thread/reply_floor_widget.dart';
import 'package:bluefish/widgets/thread/thread_main_widget.dart';
import 'package:flutter/material.dart';

class ThreadLightedRepliesSection extends StatefulWidget {
  final List<SingleReplyFloor> lightedReplies;
  final Set<String> persistedLightedPids;
  final bool initiallyCollapsed;
  final double contentMaxWidth;
  final String? viewerPuid;
  final VoidCallback? Function(SingleReplyFloor reply)? onReplyTapBuilder;
  final VoidCallback? Function(SingleReplyFloor reply)? onReplyChainTapBuilder;
  final VoidCallback? Function(SingleReplyFloor reply)?
  onOnlySeeAuthorTapBuilder;

  const ThreadLightedRepliesSection({
    super.key,
    required this.lightedReplies,
    this.persistedLightedPids = const <String>{},
    required this.initiallyCollapsed,
    required this.contentMaxWidth,
    this.viewerPuid,
    this.onReplyTapBuilder,
    this.onReplyChainTapBuilder,
    this.onOnlySeeAuthorTapBuilder,
  });

  @override
  State<ThreadLightedRepliesSection> createState() =>
      _ThreadLightedRepliesSectionState();
}

class _ThreadLightedRepliesSectionState
    extends State<ThreadLightedRepliesSection> {
  static const double _headerHeight = 68;

  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final replies = widget.lightedReplies;

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPersistentHeader(
          key: const ValueKey('thread-lighted-replies-header'),
          pinned: !_isCollapsed,
          delegate: StickyHeaderDelegate(
            height: _headerHeight,
            child: _ThreadLightedRepliesHeader(
              replyCount: replies.length,
              isCollapsed: _isCollapsed,
              onTap: _toggleCollapsed,
            ),
          ),
        ),
        if (!_isCollapsed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  for (var i = 0; i < replies.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                      child: ReplyFloor(
                        replyFloor: replies[i],
                        isLightedByViewer: widget.persistedLightedPids.contains(
                          replies[i].pid,
                        ),
                        isQuote: false,
                        contentMaxWidth: widget.contentMaxWidth,
                        imageHeroScope:
                            'thread-lighted-reply:${replies[i].pid}',
                        cardKeyPrefix: 'lighted-reply-floor-card',
                        viewerPuid: widget.viewerPuid,
                        onReplyTap: widget.onReplyTapBuilder?.call(replies[i]),
                        onReplyChainTap: widget.onReplyChainTapBuilder?.call(
                          replies[i],
                        ),
                        onOnlySeeAuthorTap: widget.onOnlySeeAuthorTapBuilder
                            ?.call(replies[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ThreadLightedRepliesHeader extends StatelessWidget {
  final int replyCount;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _ThreadLightedRepliesHeader({
    required this.replyCount,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: Card(
          key: const ValueKey('thread-lighted-replies-section'),
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.secondary.withValues(alpha: 0.18),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('thread-lighted-replies-toggle'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.wb_incandescent_outlined,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '亮回复',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCollapsed
                              ? '已收起 · 共 $replyCount 条'
                              : '点击收起 · 共 $replyCount 条',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCollapsed ? '展开' : '收起',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isCollapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
