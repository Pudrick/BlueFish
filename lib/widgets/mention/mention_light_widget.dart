// almost pure from vibe.

// TODO: check vibe results.

import 'package:bluefish/models/mention/mention_light.dart';
import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/theme/bluefish_semantic_colors.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/widgets/html/bluefish_html_widget_factory.dart';
import 'package:bluefish/widgets/mention/mention_card_components.dart';
import 'package:bluefish/widgets/mention/mention_grouped_sliver_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MentionLightCard extends StatefulWidget {
  final MentionLight light;
  final VoidCallback? onTap;

  const MentionLightCard({super.key, required this.light, this.onTap});

  @override
  State<MentionLightCard> createState() => _MentionLightCardState();
}

class _MentionLightCardState extends State<MentionLightCard> {
  MentionLight get light => widget.light;

  // TODO: manually changed here to 0. make sure what value it is.
  bool get _notDisplay =>
      light.post.auditStatus != 0 || light.post.isDelete || light.post.isHide;

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
      (light.post.quoteAuditStatus != null &&
          light.post.quoteAuditStatus != 0) ||
      (light.post.quoteIsDeleted != null && light.post.quoteIsDeleted != 0) ||
      (light.post.quoteIsHide != null && light.post.quoteIsHide != 0);

  String get _quoteNotDisplayReason {
    if (light.post.quoteAuditStatus != null &&
        light.post.quoteAuditStatus != 0) {
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

    return MentionCardShell(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme, textTheme),
          if (_notDisplay)
            MentionUnavailableBanner(message: "该回复 $_notDisplayReason"),
          const SizedBox(height: 16),
          _buildContent(context, colorScheme, textTheme),
          if (light.post.quoteInfo != null && light.post.quoteInfo!.isNotEmpty)
            _buildQuote(context, colorScheme, textTheme),
          const SizedBox(height: 12),
          MentionThreadSource(title: light.threadTitle),
        ],
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
                    padding: EdgeInsets.only(
                      right: index < displayCount - 1 ? 2 : 0,
                    ),
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
      return "${operators[0].username} 和 ${operators[1].username} 等 ${widget.light.lightNum} 人";
    }
    return "${operators[0].username} 等 ${operators.length} 人";
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
              Icon(Icons.thumb_up, size: 18, color: colorScheme.primary),
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
        MentionExpandableTextSection(
          text: displayContent,
          maxLines: 4,
          textStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
          style: MentionExpandableTextStyle.textLink,
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
              _ExpandableHtmlSection(
                html: _buildQuoteHtml(quoteInfo),
                collapsedMaxHeight: 120,
                textStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
}

class MentionLightListWidget extends StatelessWidget {
  final List<MentionLight> newLights;
  final List<MentionLight> oldLights;
  final bool hasNextPage;
  final bool isLoading;
  final ValueChanged<MentionLight>? onLightTap;

  const MentionLightListWidget({
    super.key,
    required this.newLights,
    required this.oldLights,
    required this.hasNextPage,
    required this.isLoading,
    this.onLightTap,
  });

  @override
  Widget build(BuildContext context) {
    return MentionGroupedSliverList<MentionLight>(
      newItems: newLights,
      oldItems: oldLights,
      hasNextPage: hasNextPage,
      isLoading: isLoading,
      itemBuilder: (context, item) => MentionLightCard(
        light: item,
        onTap: onLightTap == null ? null : () => onLightTap!(item),
      ),
    );
  }
}

class _ExpandableHtmlSection extends StatefulWidget {
  final String html;
  final double collapsedMaxHeight;
  final TextStyle? textStyle;

  const _ExpandableHtmlSection({
    required this.html,
    required this.collapsedMaxHeight,
    required this.textStyle,
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

  Widget _buildHtmlWidget({
    required Color linkColor,
    required double imageShrinkTriggerWidthFactor,
    required double imageShrinkTargetWidthFactor,
  }) {
    return HtmlWidget(
      widget.html,
      textStyle: widget.textStyle,
      factoryBuilder: () => BluefishHtmlWidgetFactory(
        enableImageShrink: false,
        imageShrinkTriggerWidthFactor: imageShrinkTriggerWidthFactor,
        imageShrinkTargetWidthFactor: imageShrinkTargetWidthFactor,
      ),
      customStylesBuilder: (element) {
        if (element.localName == 'a') {
          final colorInt = linkColor.toARGB32();
          final hexColor =
              '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          return {'color': hexColor};
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = context.semanticColors;
    final settings = context.select<AppSettingsViewModel?, AppSettings?>(
      (vm) => vm?.settings,
    );
    final imageShrinkTriggerWidthFactor =
        settings?.imageShrinkTriggerWidthFactor ??
        AppSettings.defaultImageShrinkTriggerWidthFactor;
    final imageShrinkTargetWidthFactor =
        settings?.imageShrinkTargetWidthFactor ??
        AppSettings.defaultImageShrinkTargetWidthFactor;
    final linkColor = semanticColors.mentionQuoteAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedHtml = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _expanded = true;
          }),
          child: SizedBox(
            height: widget.collapsedMaxHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                      minHeight: widget.collapsedMaxHeight,
                      maxHeight: double.infinity,
                      child: _buildHtmlWidget(
                        linkColor: linkColor,
                        imageShrinkTriggerWidthFactor:
                            imageShrinkTriggerWidthFactor,
                        imageShrinkTargetWidthFactor:
                            imageShrinkTargetWidthFactor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
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
                        color: semanticColors.mentionQuoteAccent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_shouldCollapse)
              Align(
                alignment: Alignment.topLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  reverseDuration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey<bool>(_expanded),
                    child: _expanded
                        ? _buildHtmlWidget(
                            linkColor: linkColor,
                            imageShrinkTriggerWidthFactor:
                                imageShrinkTriggerWidthFactor,
                            imageShrinkTargetWidthFactor:
                                imageShrinkTargetWidthFactor,
                          )
                        : collapsedHtml,
                  ),
                ),
              )
            else
              _buildHtmlWidget(
                linkColor: linkColor,
                imageShrinkTriggerWidthFactor: imageShrinkTriggerWidthFactor,
                imageShrinkTargetWidthFactor: imageShrinkTargetWidthFactor,
              ),
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
                      color: semanticColors.mentionQuoteAccent,
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
