import 'package:bluefish/models/mention_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class MentionLightCard extends StatelessWidget {
  final MentionLight light;

  const MentionLightCard({super.key, required this.light});

  bool get _notDisplay =>
      light.post.auditStatus != 1 ||
      light.post.isDelete ||
      light.post.isHide;

  bool get _quoteNotDisplay =>
      (light.post.quoteAuditStatus != null && light.post.quoteAuditStatus != 1) ||
      (light.post.quoteIsDeleted != null && light.post.quoteIsDeleted != 0) ||
      (light.post.quoteIsHide != null && light.post.quoteIsHide != 0);

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
        // Stacked overlapping avatars
        SizedBox(
          width: 40 + (displayCount > 1 ? (displayCount - 1) * 14.0 : 0),
          height: 40,
          child: displayCount > 0
              ? Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(displayCount, (index) {
                    final operator = operators[index];
                    return Positioned(
                      left: index * 14.0,
                      top: 0,
                      bottom: 0,
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
              : const SizedBox.shrink(),
        ),
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
                DateFormat("yyyy-MM-dd HH:mm:ss").format(light.lastTime),
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
              "该回复当前可能无法查看",
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.thumb_up_outlined,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            light.post.content,
            textAlign: TextAlign.start,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
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
              // Render quoteInfo - may contain HTML content from forum
              _buildQuoteContent(quoteInfo, colorScheme, textTheme),
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
          "该引用可能无法查看",
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteContent(
    String quoteInfo,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Unescape HTML entities that are escaped in the quoteInfo
    final unescapedQuote = _unescapeHtmlEntities(quoteInfo);

    // Replace BBCode-style [b] tags with HTML <b> tags
    final htmlContent = unescapedQuote
        .replaceAll('[b]', '<b>')
        .replaceAll('[/b]', '</b>')
        .replaceAll('[i]', '<i>')
        .replaceAll('[/i]', '</i>')
        .replaceAll('[u]', '<u>')
        .replaceAll('[/u]', '</u>');

    return HtmlWidget(
      htmlContent,
      textStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      customStylesBuilder: (element) {
        if (element.localName == 'a') {
          final colorInt = colorScheme.tertiary.toARGB32();
          final hexColor = '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          return {'color': hexColor};
        }
        return null;
      },
    );
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