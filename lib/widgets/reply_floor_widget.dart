import "package:bluefish/widgets/author_info_widget.dart";
import "package:bluefish/widgets/htmlWidget_with_vote.dart";
import "package:flutter/material.dart";

import 'package:bluefish/models/single_reply_floor.dart';

class ReplyFloor extends StatelessWidget {
  final SingleReplyFloor replyFloor;
  final bool isQuote;

  const ReplyFloor({
    super.key,
    required this.replyFloor,
    required this.isQuote,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 36.0;
    const double capsuleRadius = buttonHeight / 2;
    const double adjacentCornerRadius = 4.0;

    final colorScheme = Theme.of(context).colorScheme;

    var notDisplay =
        replyFloor.isAudit ||
        replyFloor.isDelete ||
        replyFloor.isHidden ||
        replyFloor.isSelfDelete;

    final String? notDisplayReasonText = notDisplay
        ? switch ((
            replyFloor.isDelete,
            replyFloor.isSelfDelete,
            replyFloor.isAudit,
            replyFloor.isHidden,
          )) {
            (true, false, _, _) => '该内容已被删除',
            (true, true, _, _) => '该内容已被作者删除',
            (_, _, true, _) => '该内容正在卡审核',
            (_, _, _, true) => '该内容已被隐藏',
            _ => '该内容不知道为什么不可显示',
          }
        : null;

    final String? notDisplayText = notDisplayReasonText == null
        ? null
        : "其他用户当前无法显示该内容。原因：$notDisplayReasonText";

    return Card(
      color: isQuote
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthorInfoWidget(content: replyFloor),
              // const Divider(),
              SizedBox(height: isQuote ? 8 : 12),
              if (!isQuote && replyFloor.hasQuote) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: _QuoteWidget(
                    quoteWidget: ReplyFloor(
                      replyFloor: replyFloor.quote!,
                      isQuote: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (notDisplay)
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),

                    // according to M3, remove the border lines.
                    // border: Border.all(
                    //   color: Theme.of(context)
                    //       .colorScheme
                    //       .outline
                    //       .withValues(alpha: 0.3),
                    // ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          isQuote ? notDisplayReasonText! : notDisplayText!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isQuote || (isQuote && !notDisplay))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: HtmlWidgetWithVote(replyFloor.contentHTML),
                ),
              if (!isQuote) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActionPill(
                      icon: Icons.wb_incandescent_outlined,
                      label: "${replyFloor.lightCount}",
                      onTap: () {},
                      isLeft: true,
                    ),
                    const SizedBox(width: 2), 
                    _ActionPill(
                      icon: Icons.thumb_down_alt_outlined,
                      onTap: () {},
                      isLeft: false,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: add a button that can directly reply to quote.
class _QuoteWidget extends StatefulWidget {
  final Widget quoteWidget;
  final double maxHeight;

  const _QuoteWidget({required this.quoteWidget, this.maxHeight = 180});

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

  void _checkHeight() {
    final renderBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      if (height <= widget.maxHeight) {
        if (mounted) {
          setState(() {
            _needsExpansion = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_needsExpansion) {
      return Container(key: _contentKey, child: widget.quoteWidget);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: _isExpanded
          ? _buildExpandedView(colorScheme)
          : _buildCollapsedView(colorScheme),
    );
  }

  Widget _buildExpandedView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(key: _contentKey, child: widget.quoteWidget),
        InkWell(
          onTap: () => setState(() => _isExpanded = false),
          child: SizedBox(
            height: 30,
            child: Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedView(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: AbsorbPointer(
                  child: Container(key: _contentKey, child: widget.quoteWidget),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0),
                    colorScheme.surfaceContainerHighest,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Icon(
                  Icons.expand_more_rounded,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isLeft;

  const _ActionPill({
    required this.icon,
    this.label,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(18) : const Radius.circular(4),
        right: isLeft ? const Radius.circular(4) : const Radius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
