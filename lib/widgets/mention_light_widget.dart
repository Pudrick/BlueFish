// almost pure from vibe.

// TODO: check vibe results.

import 'package:bluefish/models/mention_light.dart';
import 'package:bluefish/widgets/mention_grouped_sliver_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class MentionLightCard extends StatefulWidget {
  final MentionLight light;

  const MentionLightCard({super.key, required this.light});

  @override
  State<MentionLightCard> createState() => _MentionLightCardState();
}

class _MentionLightCardState extends State<MentionLightCard> {
  MentionLight get light => widget.light;

  // TODO: manually changed here to 0. make sure what value it is.
  bool get _notDisplay =>
      light.post.auditStatus != 0 ||
      light.post.isDelete ||
      light.post.isHide;

  String get _notDisplayReason {
    if (light.post.auditStatus != 0) {
      return "卡审核";
    }
    if (light.post.isDelete) {
      return "已删除";
    }
    if (light.post.isHide) {
      return "已隐藏";
    }
    return "无法查看";
  }

  bool get _quoteNotDisplay =>
      (light.post.quoteAuditStatus != null && light.post.quoteAuditStatus != 0) ||
      (light.post.quoteIsDeleted != null && light.post.quoteIsDeleted != 0) ||
      (light.post.quoteIsHide != null && light.post.quoteIsHide != 0);

  String get _quoteNotDisplayReason {
    if (light.post.quoteAuditStatus != null && light.post.quoteAuditStatus != 0) {
      return "卡审核";
    }
    if (light.post.quoteIsDeleted != null && light.post.quoteIsDeleted != 0) {
      return "已删除";
    }
    if (light.post.quoteIsHide != null && light.post.quoteIsHide != 0) {
      return "已隐藏";
    }
    return "无法查看";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          // TODO: jump to thread detail.
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme, textTheme),
              if (_notDisplay)
                _buildNotDisplayWarning(context, colorScheme, textTheme),
              const SizedBox(height: 16),
              _buildContent(context, colorScheme, textTheme),
              if (light.post.quoteInfo != null && light.post.quoteInfo!.isNotEmpty)
                _buildQuote(context, colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildThreadSource(context, colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final operators = light.operators;
    final displayCount = operators.length > 3 ? 3 : operators.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Horizontally arranged avatars
        displayCount > 0
            ? Row(
                children: List.generate(displayCount, (index) {
                  final operator = operators[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index < displayCount - 1 ? 2 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surfaceContainerHigh,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          operator.avatarUrl.toString(),
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stack) => Container(
                            width: 36,
                            height: 36,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              )
            : const SizedBox(width: 36, height: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _buildOperatorsText(operators),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                // check if there's Chinese characters in time str.
                RegExp(r"[\u4e00-\u9fa5]").hasMatch(light.createTimeString)
                    ? "${DateFormat("yyyy-MM-dd HH:mm:ss").format(light.lastTime)} (${light.createTimeString})"
                    : DateFormat("yyyy-MM-dd HH:mm:ss").format(light.lastTime),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildOperatorsText(List<Operator> operators) {
    if (operators.isEmpty) {
      return "未知用户";
    }
    if (operators.length == 1) {
      return operators.first.username;
    }
    if (operators.length == 2) {
      return "${operators[0].username} 和 ${operators[1].username}";
    }
    return "${operators[0].username} 等 ${operators.length} 人";
  }

  Widget _buildNotDisplayWarning(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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
              "该回复 $_notDisplayReason",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final displayContent = _sanitizePostContent(light.post.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.thumb_up,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    const TextSpan(text: "共"),
                    TextSpan(
                      text: "${light.lightNum}",
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: "个人偶点亮了"),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableTextSection(
          text: displayContent,
          maxLines: 4,
          textStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _sanitizePostContent(String input) {
    return input.replaceAllMapped(
      RegExp(r'(\[(?:图片|多图|视频)\]).*?/quality.*$'),
      (match) => match.group(1) ?? '',
    );
  }

  Widget _buildQuote(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final quoteInfo = light.post.quoteInfo;
    if (quoteInfo == null || quoteInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: colorScheme.tertiary, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_quoteNotDisplay)
              _buildQuoteNotDisplayWarning(context, colorScheme, textTheme)
            else ...[
              if (light.post.quoteUsername != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "@${light.post.quoteUsername}",
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              _ExpandableHtmlSection(
                html: _buildQuoteHtml(quoteInfo),
                collapsedMaxHeight: 120,
                textStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                linkColor: colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteNotDisplayWarning(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(
          Icons.visibility_off,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          "该引用 $_quoteNotDisplayReason",
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _buildQuoteHtml(String quoteInfo) {
    final unescapedQuote = _unescapeHtmlEntities(quoteInfo);

    return unescapedQuote
        .replaceAll('[b]', '<b>')
        .replaceAll('[/b]', '</b>')
        .replaceAll('[i]', '<i>')
        .replaceAll('[/i]', '</i>')
        .replaceAll('[u]', '<u>')
        .replaceAll('[/u]', '</u>');
  }

  String _unescapeHtmlEntities(String input) {
    return input
        .replaceAll(r'\u003C', '<')
        .replaceAll(r'\u003E', '>')
        .replaceAll(r'\u0026', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  Widget _buildThreadSource(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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
              light.threadTitle,
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

class MentionLightListWidget extends StatelessWidget {
  final List<MentionLight> newLights;
  final List<MentionLight> oldLights;
  final bool hasNextPage;

  const MentionLightListWidget({
    super.key,
    required this.newLights,
    required this.oldLights,
    required this.hasNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return MentionGroupedSliverList<MentionLight>(
      newItems: newLights,
      oldItems: oldLights,
      hasNextPage: hasNextPage,
      itemBuilder: (context, item) => MentionLightCard(light: item),
    );
  }
}

class _ExpandableTextSection extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;

  const _ExpandableTextSection({
    required this.text,
    required this.maxLines,
    required this.textStyle,
  });

  @override
  State<_ExpandableTextSection> createState() => _ExpandableTextSectionState();
}

class _ExpandableTextSectionState extends State<_ExpandableTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              textAlign: TextAlign.start,
              style: widget.textStyle,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _expanded = !_expanded;
                  }),
                  child: Text(
                    _expanded ? "收起" : "展开",
                    style: linkStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExpandableHtmlSection extends StatefulWidget {
  final String html;
  final double collapsedMaxHeight;
  final TextStyle? textStyle;
  final Color linkColor;

  const _ExpandableHtmlSection({
    required this.html,
    required this.collapsedMaxHeight,
    required this.textStyle,
    required this.linkColor,
  });

  @override
  State<_ExpandableHtmlSection> createState() => _ExpandableHtmlSectionState();
}

class _ExpandableHtmlSectionState extends State<_ExpandableHtmlSection> {
  bool _expanded = false;

  bool get _shouldCollapse {
    final plainText = widget.html.replaceAll(RegExp(r'<[^>]+>'), '');
    return plainText.length > 90;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final htmlWidget = HtmlWidget(
      widget.html,
      textStyle: widget.textStyle,
      customStylesBuilder: (element) {
        if (element.localName == 'a') {
          final colorInt = widget.linkColor.toARGB32();
          final hexColor =
              '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          return {'color': hexColor};
        }
        return null;
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_shouldCollapse && !_expanded)
              SizedBox(
                height: widget.collapsedMaxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          minHeight: widget.collapsedMaxHeight,
                          maxHeight: double.infinity,
                          child: htmlWidget,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          _expanded = true;
                        }),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.tertiaryContainer.withValues(alpha: 0),
                                colorScheme.tertiaryContainer.withValues(alpha: 0.95),
                              ],
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colorScheme.tertiary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              htmlWidget,
            if (_shouldCollapse && _expanded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _expanded = !_expanded;
                  }),
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: colorScheme.tertiary,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
