import 'package:flutter/material.dart';

class ThreadReplySheetContextCard extends StatefulWidget {
  final String? label;
  final String? preview;
  final int collapsedMaxLines;

  const ThreadReplySheetContextCard({
    super.key,
    this.label,
    this.preview,
    required this.collapsedMaxLines,
  });

  @override
  State<ThreadReplySheetContextCard> createState() =>
      _ThreadReplySheetContextCardState();
}

class _ThreadReplySheetContextCardState
    extends State<ThreadReplySheetContextCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.trim().isNotEmpty)
            Text(
              widget.label!,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (widget.preview != null && widget.preview!.trim().isNotEmpty) ...[
            if (widget.label != null && widget.label!.trim().isNotEmpty)
              const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final previewText = widget.preview!.trim();
                final previewStyle = textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                );

                final textPainter = TextPainter(
                  text: TextSpan(text: previewText, style: previewStyle),
                  maxLines: widget.collapsedMaxLines,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);

                final hasOverflow = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Text(
                        previewText,
                        maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: previewStyle,
                      ),
                    ),
                    if (hasOverflow) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey(
                          'thread_reply_sheet_context_toggle',
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        icon: Icon(
                          _isExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 18,
                        ),
                        label: Text(_isExpanded ? '收起引用' : '展开引用'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
