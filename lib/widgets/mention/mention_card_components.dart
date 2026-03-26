import 'package:flutter/material.dart';

enum MentionExpandableTextStyle { textLink, fade }

class MentionCardShell extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const MentionCardShell({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class MentionUnavailableBanner extends StatelessWidget {
  final String message;

  const MentionUnavailableBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.errorContainer,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MentionThreadSource extends StatelessWidget {
  final String title;

  const MentionThreadSource({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class MentionExpandableTextSection extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;
  final MentionExpandableTextStyle style;
  final Color accentColor;
  final Color? fadeColor;

  const MentionExpandableTextSection({
    super.key,
    required this.text,
    required this.maxLines,
    required this.textStyle,
    required this.style,
    required this.accentColor,
    this.fadeColor,
  });

  @override
  State<MentionExpandableTextSection> createState() =>
      _MentionExpandableTextSectionState();
}

class _MentionExpandableTextSectionState
    extends State<MentionExpandableTextSection> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _expand() {
    if (_expanded) {
      return;
    }
    setState(() {
      _expanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textLinkStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: widget.accentColor,
      fontWeight: FontWeight.bold,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.textStyle),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;
        final expandedText = Text(
          widget.text,
          textAlign: TextAlign.start,
          style: widget.textStyle,
          maxLines: null,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverflowing)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                reverseDuration: const Duration(milliseconds: 200),
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeOutCubic,
                sizeCurve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildCollapsedText(),
                secondChild: expandedText,
              )
            else
              expandedText,
            if (isOverflowing) _buildAction(textLinkStyle),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedText() {
    switch (widget.style) {
      case MentionExpandableTextStyle.textLink:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _expand,
          child: Text(
            widget.text,
            textAlign: TextAlign.start,
            style: widget.textStyle,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case MentionExpandableTextStyle.fade:
        final fadeColor = widget.fadeColor ?? Theme.of(context).cardColor;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _expand,
          child: Stack(
            children: [
              Text(
                widget.text,
                textAlign: TextAlign.start,
                style: widget.textStyle,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        fadeColor.withValues(alpha: 0),
                        fadeColor.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.accentColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildAction(TextStyle? textLinkStyle) {
    switch (widget.style) {
      case MentionExpandableTextStyle.textLink:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GestureDetector(
            onTap: _toggleExpanded,
            child: Text(_expanded ? "收起" : "展开", style: textLinkStyle),
          ),
        );
      case MentionExpandableTextStyle.fade:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            child: _expanded
                ? Center(
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: widget.accentColor,
                      size: 22,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
    }
  }
}
