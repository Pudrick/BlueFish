import 'package:bluefish/models/thread/floor_meta.dart';
import 'package:bluefish/widgets/thread/author_info_widget.dart';
import 'package:bluefish/widgets/html/bluefish_html_widget.dart';
import 'package:bluefish/widgets/thread/thread_inline_video_widget.dart';
import 'package:flutter/material.dart';

import 'package:bluefish/models/thread/single_reply_floor.dart';

class ReplyFloor extends StatelessWidget {
  final SingleReplyFloor replyFloor;
  final bool isLightedByViewer;
  final bool isLightingLightAction;
  final bool isQuote;
  final int? floorNumber;
  final int? lightCountOverride;
  final double contentMaxWidth;
  final String? imageHeroScope;
  final String cardKeyPrefix;
  final VoidCallback? onLightTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onReplyChainTap;
  final VoidCallback? onOnlySeeAuthorTap;
  final bool showActionRow;
  final bool showOverflowAction;
  final String? viewerPuid;

  const ReplyFloor({
    super.key,
    required this.replyFloor,
    this.isLightedByViewer = false,
    this.isLightingLightAction = false,
    required this.isQuote,
    this.floorNumber,
    this.lightCountOverride,
    this.contentMaxWidth = double.infinity,
    this.imageHeroScope,
    this.cardKeyPrefix = 'reply-floor-card',
    this.onLightTap,
    this.onReplyTap,
    this.onReplyChainTap,
    this.onOnlySeeAuthorTap,
    this.showActionRow = true,
    this.showOverflowAction = true,
    this.viewerPuid,
  });

  @override
  Widget build(BuildContext context) {
    return _ReplyFloorContent(
      content: replyFloor,
      isLightedByViewer: isLightedByViewer,
      isLightingLightAction: isLightingLightAction,
      isQuote: isQuote,
      floorNumber: floorNumber ?? replyFloor.serverFloorNumber,
      lightCount: lightCountOverride ?? replyFloor.lightCount,
      showOpBadge: replyFloor.isOp,
      contentMaxWidth: contentMaxWidth,
      imageHeroScope: imageHeroScope,
      cardKeyPrefix: cardKeyPrefix,
      onLightTap: onLightTap,
      replyCount: replyFloor.replyNum,
      onReplyTap: onReplyTap,
      onReplyChainTap: onReplyChainTap,
      onOnlySeeAuthorTap: onOnlySeeAuthorTap,
      showActionRow: showActionRow,
      showOverflowAction: showOverflowAction,
      isMine: viewerPuid != null && viewerPuid == replyFloor.meta.author.puid,
    );
  }
}

class _ReplyFloorContent extends StatelessWidget {
  final ReplyContent content;
  final bool isLightedByViewer;
  final bool isLightingLightAction;
  final bool isQuote;
  final int? floorNumber;
  final int? lightCount;
  final bool showOpBadge;
  final double contentMaxWidth;
  final String? imageHeroScope;
  final String cardKeyPrefix;
  final VoidCallback? onLightTap;
  final int? replyCount;
  final VoidCallback? onReplyTap;
  final VoidCallback? onReplyChainTap;
  final VoidCallback? onOnlySeeAuthorTap;
  final bool showActionRow;
  final bool showOverflowAction;
  final bool isMine;

  const _ReplyFloorContent({
    required this.content,
    required this.isLightedByViewer,
    required this.isLightingLightAction,
    required this.isQuote,
    required this.floorNumber,
    required this.lightCount,
    required this.showOpBadge,
    required this.contentMaxWidth,
    required this.imageHeroScope,
    required this.cardKeyPrefix,
    required this.onLightTap,
    required this.replyCount,
    required this.onReplyTap,
    required this.onReplyChainTap,
    required this.onOnlySeeAuthorTap,
    required this.showActionRow,
    required this.showOverflowAction,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = theme.textTheme;
    final double cardMaxWidth = contentMaxWidth.isFinite
        ? contentMaxWidth + 24
        : double.infinity;

    final bool notDisplay = !content.visibility.canDisplay;
    final String? notDisplayReasonText = notDisplay
        ? content.visibility.hiddenReasonText
        : null;
    final String? notDisplayText = notDisplayReasonText == null
        ? null
        : isQuote
        ? notDisplayReasonText
        : '其他用户当前无法显示该内容。原因：$notDisplayReasonText';

    final int? displayFloorNumber = floorNumber != null && floorNumber! > 0
        ? floorNumber
        : null;
    final resolvedImageHeroScope =
        imageHeroScope ?? 'thread-reply:${content.pid}';
    final VoidCallback? resolvedOnMoreTap = !isQuote && showOverflowAction
        ? () {
            _showReplyOverflowActionsSheet(
              context,
              isMine: isMine,
              onOnlySeeAuthorTap: onOnlySeeAuthorTap,
            );
          }
        : null;
    final bool showHeaderActions =
        !isQuote &&
        _ReplyHeaderActions.hasVisibleActions(
          client: content.meta.client,
          floor: displayFloorNumber,
          onMoreTap: resolvedOnMoreTap,
        );
    final SingleReplyFloor? singleReplyFloor = content is SingleReplyFloor
        ? content as SingleReplyFloor
        : null;

    final Widget bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isQuote && content.quote != null) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: colorScheme.outlineVariant, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: _QuoteWidget(
              quoteWidget: _ReplyFloorContent(
                content: content.quote!,
                isLightedByViewer: false,
                isLightingLightAction: false,
                isQuote: true,
                floorNumber: null,
                lightCount: null,
                showOpBadge: content.quote!.isOp,
                contentMaxWidth: contentMaxWidth,
                imageHeroScope: '$resolvedImageHeroScope:quote',
                cardKeyPrefix: cardKeyPrefix,
                onLightTap: null,
                replyCount: null,
                onReplyTap: null,
                onReplyChainTap: null,
                onOnlySeeAuthorTap: null,
                showActionRow: false,
                showOverflowAction: false,
                isMine: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (notDisplay) _NotDisplayBanner(text: notDisplayText!),
        if (!isQuote || !notDisplay)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: BluefishHtmlWidget(
              content.contentHtml,
              enableImageGallery: true,
              imageHeroScope: resolvedImageHeroScope,
              textStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        if (!isQuote && singleReplyFloor != null) ...[
          if (singleReplyFloor.hasInlineVideo) ...[
            const SizedBox(height: 12),
            ThreadInlineVideoWidget(
              videoUrl: singleReplyFloor.resolvedReplyVideoUrl,
              coverUrl: singleReplyFloor.resolvedReplyVideoCover,
              sectionKey: ValueKey('reply-floor-video-section-${content.pid}'),
              playButtonKey: ValueKey('reply-floor-video-play-${content.pid}'),
            ),
          ],
        ],
        if (showActionRow && !isQuote && lightCount != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _ReplyActionRow(
              replyPid: content.pid,
              lightCount: lightCount!,
              isLightedByViewer: isLightedByViewer,
              isLightingLightAction: isLightingLightAction,
              replyCount: replyCount ?? 0,
              onLightTap: onLightTap,
              onReplyChainTap: onReplyChainTap,
              onGiftTap: () {},
              onReplyTap: onReplyTap ?? () {},
            ),
          ),
      ],
    );

    Widget contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AuthorInfoWidget(
                meta: content.meta,
                showOpBadge: showOpBadge,
                showClientBadge: isQuote,
              ),
            ),
            if (showHeaderActions) ...[
              const SizedBox(width: 8),
              _ReplyHeaderActions(
                client: content.meta.client,
                floor: displayFloorNumber,
                onMoreTap: resolvedOnMoreTap,
              ),
            ],
          ],
        ),
        SizedBox(height: isQuote ? 10 : 12),
        bodyContent,
      ],
    );

    if (contentMaxWidth.isFinite) {
      contentColumn = Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: contentColumn,
        ),
      );
    }

    final Widget floorContent = Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, isQuote ? 10 : 12),
      child: contentColumn,
    );

    if (isQuote) {
      return floorContent;
    }

    final Widget card = Card(
      key: ValueKey('$cardKeyPrefix-${content.pid}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: floorContent,
    );

    if (!cardMaxWidth.isFinite) {
      return card;
    }

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardMaxWidth),
        child: card,
      ),
    );
  }
}

class _NotDisplayBanner extends StatelessWidget {
  final String text;

  const _NotDisplayBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorNumberPill extends StatelessWidget {
  final int floor;

  const _FloorNumberPill({required this.floor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('reply-header-floor-pill'),
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '#$floor',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReplyHeaderActions extends StatelessWidget {
  final PostClient client;
  final int? floor;
  final VoidCallback? onMoreTap;

  const _ReplyHeaderActions({
    required this.client,
    required this.floor,
    required this.onMoreTap,
  });

  static bool hasVisibleActions({
    required PostClient client,
    required int? floor,
    required VoidCallback? onMoreTap,
  }) {
    return iconForPostClient(client) != null ||
        (floor != null && floor > 0) ||
        onMoreTap != null;
  }

  @override
  Widget build(BuildContext context) {
    final IconData? clientIcon = iconForPostClient(client);
    final actions = <Widget>[];

    if (clientIcon != null) {
      actions.add(_HeaderClientBadge(client: client, icon: clientIcon));
    }
    if (floor != null && floor! > 0) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 6));
      }
      actions.add(_FloorNumberPill(floor: floor!));
    }
    if (onMoreTap != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 6));
      }
      actions.add(
        _HeaderIconButton(
          icon: Icons.more_horiz_rounded,
          tooltip: '更多操作',
          onTap: onMoreTap!,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

class _HeaderClientBadge extends StatelessWidget {
  final PostClient client;
  final IconData icon;

  const _HeaderClientBadge({required this.client, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: _clientTooltip(client),
      child: Container(
        key: const ValueKey('reply-header-client-badge'),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

String _clientTooltip(PostClient client) {
  return switch (client) {
    PostClient.android => 'Android 客户端',
    PostClient.iphone => 'iPhone 客户端',
    PostClient.pc => 'PC 客户端',
    PostClient.unknown => '未知设备',
  };
}

// TODO: add a button that can directly reply to quote.
// TODO: adjust the visual effect as the same with userhome's reply.
class _QuoteWidget extends StatefulWidget {
  static const double maxHeight = 180;

  final Widget quoteWidget;

  const _QuoteWidget({required this.quoteWidget});

  @override
  State<_QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends State<_QuoteWidget> {
  bool _isExpanded = false;

  bool _needsExpansion = true;

  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHeight();
    });
  }

  @override
  void didUpdateWidget(covariant _QuoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHeight();
    });
  }

  void _checkHeight() {
    final renderObject = _contentKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final bool needExpansion =
          renderObject.size.height > _QuoteWidget.maxHeight;
      if (needExpansion != _needsExpansion && mounted) {
        setState(() {
          _needsExpansion = needExpansion;
          if (!needExpansion) {
            _isExpanded = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: double.infinity,
        child: _isExpanded
            ? _buildExpandedView(context)
            : _buildCollapsedView(context),
      ),
    );
  }

  Widget _buildExpandedView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuoteContent(),
        InkWell(
          onTap: () => setState(() => _isExpanded = false),
          child: SizedBox(
            height: 30,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _needsExpansion ? () => setState(() => _isExpanded = true) : null,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (_needsExpansion)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: _QuoteWidget.maxHeight,
              ),
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: AbsorbPointer(child: _buildQuoteContent()),
                ),
              ),
            )
          else
            _buildQuoteContent(),
          if (_needsExpansion)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: Container(
                  height: 76,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0,
                        ),
                        colorScheme.surfaceContainerHighest,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: colorScheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteContent() {
    return SizedBox(
      key: _contentKey,
      width: double.infinity,
      child: widget.quoteWidget,
    );
  }
}

class _ReplyActionRow extends StatelessWidget {
  final String replyPid;
  final int lightCount;
  final bool isLightedByViewer;
  final bool isLightingLightAction;
  final int replyCount;
  final VoidCallback? onLightTap;
  final VoidCallback? onReplyChainTap;
  final VoidCallback onGiftTap;
  final VoidCallback onReplyTap;

  const _ReplyActionRow({
    required this.replyPid,
    required this.lightCount,
    required this.isLightedByViewer,
    required this.isLightingLightAction,
    required this.replyCount,
    required this.onLightTap,
    required this.onReplyChainTap,
    required this.onGiftTap,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final compactActions = <Widget>[
      _CountActionChip(
        actionKey: ValueKey('reply-light-chip-$replyPid'),
        icon: isLightedByViewer
            ? Icons.wb_incandescent
            : Icons.wb_incandescent_outlined,
        count: lightCount,
        isActive: isLightedByViewer,
        isBusy: isLightingLightAction,
        tooltip: isLightedByViewer ? '已点亮 · 亮了 $lightCount' : '亮了 $lightCount',
        onTap: onLightTap,
      ),
      if (replyCount > 0 && onReplyChainTap != null)
        _CountActionChip(
          icon: Icons.format_quote_rounded,
          count: replyCount,
          tooltip: '查看回复 $replyCount',
          onTap: onReplyChainTap!,
        ),
      _IconActionChip(
        icon: Icons.card_giftcard_rounded,
        tooltip: '送礼',
        onTap: onGiftTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stackReplyAction =
            constraints.maxWidth < 400 && compactActions.length >= 3;

        if (stackReplyAction) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: compactActions),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _PrimaryIconActionChip(
                  icon: Icons.add_comment_outlined,
                  tooltip: '回复该内容',
                  onTap: onReplyTap,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(spacing: 8, runSpacing: 8, children: compactActions),
            ),
            const SizedBox(width: 8),
            _PrimaryIconActionChip(
              icon: Icons.add_comment_outlined,
              tooltip: '回复该内容',
              onTap: onReplyTap,
            ),
          ],
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        key: const ValueKey('reply-header-more-button'),
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _CountActionChip extends StatelessWidget {
  final Key? actionKey;
  final IconData icon;
  final int count;
  final bool isActive;
  final bool isBusy;
  final String tooltip;
  final VoidCallback? onTap;

  const _CountActionChip({
    this.actionKey,
    required this.icon,
    required this.count,
    this.isActive = false,
    this.isBusy = false,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = isActive
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isActive
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSurfaceVariant;
    final borderColor = isActive
        ? colorScheme.tertiary.withValues(alpha: 0.22)
        : colorScheme.outlineVariant.withValues(alpha: 0.38);

    return Tooltip(
      message: tooltip,
      child: Material(
        key: actionKey,
        color: backgroundColor,
        shape: StadiumBorder(side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  _formatCompactCount(count),
                  style: textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _PrimaryIconActionChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PrimaryIconActionChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.secondaryContainer,
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.secondary.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

void _showReplyOverflowActionsSheet(
  BuildContext context, {
  required bool isMine,
  VoidCallback? onOnlySeeAuthorTap,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: true,
    builder: (context) {
      return _ReplyOverflowActionsSheet(
        isMine: isMine,
        onOnlySeeAuthorTap: onOnlySeeAuthorTap,
      );
    },
  );
}

class _ReplyOverflowActionsSheet extends StatelessWidget {
  final bool isMine;
  final VoidCallback? onOnlySeeAuthorTap;

  const _ReplyOverflowActionsSheet({
    required this.isMine,
    this.onOnlySeeAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '更多操作',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (onOnlySeeAuthorTap != null)
                      _OverflowActionTile(
                        icon: Icons.filter_alt_outlined,
                        label: '只看TA',
                        onTap: () {
                          Navigator.of(context).pop();
                          onOnlySeeAuthorTap!();
                        },
                      ),
                    if (!isMine)
                      _OverflowActionTile(
                        icon: Icons.flag_outlined,
                        label: '举报',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    if (isMine)
                      _OverflowActionTile(
                        icon: Icons.delete_outline_rounded,
                        label: '删除回复',
                        danger: true,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _OverflowActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = danger
        ? colorScheme.errorContainer.withValues(alpha: 0.88)
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = danger
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCompactCount(int count) {
  if (count > 99) {
    return '99+';
  }
  return '$count';
}
