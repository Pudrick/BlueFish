import 'package:bluefish/widgets/thread/author_info_widget.dart';
import 'package:bluefish/widgets/html/bluefish_html_widget.dart';
import 'package:flutter/material.dart';

import 'package:bluefish/models/single_reply_floor.dart';

class ReplyFloor extends StatelessWidget {
  final SingleReplyFloor replyFloor;
  final bool isQuote;
  final int? floorNumber;

  const ReplyFloor({
    super.key,
    required this.replyFloor,
    required this.isQuote,
    this.floorNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = theme.textTheme;

    final bool notDisplay =
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
        : '其他用户当前无法显示该内容。原因：$notDisplayReasonText';

    final int resolvedFloorNumber = floorNumber ?? replyFloor.replyNum;
    final int displayFloorNumber = resolvedFloorNumber > 0
        ? resolvedFloorNumber
        : 1;

    final Widget floorContent = Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, isQuote ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AuthorInfoWidget(content: replyFloor)),
              if (!isQuote) ...[
                const SizedBox(width: 8),
                _FloorNumberPill(floor: displayFloorNumber),
              ],
            ],
          ),
          SizedBox(height: isQuote ? 10 : 12),
          if (!isQuote && replyFloor.hasQuote) ...[
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
                quoteWidget: ReplyFloor(
                  replyFloor: replyFloor.quote!,
                  isQuote: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (notDisplay)
            _NotDisplayBanner(
              text: isQuote ? notDisplayReasonText! : notDisplayText!,
            ),
          if (!isQuote || !notDisplay)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: BluefishHtmlWidget(
                replyFloor.contentHTML,
                textStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          if (!isQuote)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionPill(
                    icon: Icons.wb_incandescent_outlined,
                    label: '${replyFloor.lightCount}',
                    onTap: () {},
                  ),
                  _ActionPill(
                    icon: Icons.thumb_down_alt_outlined,
                    label: '',
                    onTap: () {},
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (isQuote) {
      return floorContent;
    }

    return Card(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
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

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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
