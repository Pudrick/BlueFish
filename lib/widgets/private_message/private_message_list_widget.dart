import 'package:bluefish/models/private_message_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrivateMessageCard extends StatelessWidget {
  final PrivateMessagePeek messagePeek;
  final ValueChanged<PrivateMessagePeek>? onTap;

  const PrivateMessageCard({super.key, required this.messagePeek, this.onTap});

  String get _sanitizedPreview {
    final preview = messagePeek.lastMessagePeek
        .replaceAllMapped(
          RegExp(r'(\[(?:图片|多图|视频)\][^\/]*).*?/quality.*$'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();

    if (preview.isEmpty) {
      return messagePeek.isSystem ? '系统消息' : '暂无消息内容';
    }

    return preview;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(messagePeek),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MessageAvatar(messagePeek: messagePeek),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      messagePeek.nickName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (messagePeek.certIconUrl != null) ...[
                                    const SizedBox(width: 6),
                                    _CertIcon(
                                      url: messagePeek.certIconUrl.toString(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm:ss',
                              ).format(messagePeek.lastMessageTime),
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: messagePeek.isUnread
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.45,
                                  )
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                messagePeek.isSystem
                                    ? Icons.campaign_outlined
                                    : Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: messagePeek.isUnread
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _sanitizedPreview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    height: 1.45,
                                    fontWeight: messagePeek.isUnread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivateMessageListWidget extends StatelessWidget {
  final List<PrivateMessagePeek> messagePeeks;
  final bool isLoading;
  final bool isLastPage;
  final ValueChanged<PrivateMessagePeek>? onTap;

  const PrivateMessageListWidget({
    super.key,
    required this.messagePeeks,
    required this.isLoading,
    required this.isLastPage,
    this.onTap,
  });

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLastPage
          ? Text(
              '—— 后面没有了 ——',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              '继续上滑加载更多',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index == messagePeeks.length) {
          return _buildFooter(context);
        }

        return PrivateMessageCard(
          messagePeek: messagePeeks[index],
          onTap: onTap,
        );
      }, childCount: messagePeeks.length + 1),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  final PrivateMessagePeek messagePeek;

  const _MessageAvatar({required this.messagePeek});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                messagePeek.avatarUrl.toString(),
                fit: BoxFit.cover,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    messagePeek.isSystem
                        ? Icons.notifications_none
                        : Icons.person,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (messagePeek.isUnread ||
              messagePeek.isSystem ||
              messagePeek.isBlocked) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                if (messagePeek.isUnread)
                  _StatusIconBadge(
                    icon: Icons.mark_chat_unread_outlined,
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                if (messagePeek.isSystem)
                  _StatusIconBadge(
                    icon: Icons.verified_user_outlined,
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                if (messagePeek.isBlocked)
                  _StatusIconBadge(
                    icon: Icons.block_outlined,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusIconBadge extends StatelessWidget {
  static const double _badgeHeight = 18;
  static const double _badgeWidth = 28;

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatusIconBadge({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _badgeWidth,
      height: _badgeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, size: 12, color: foregroundColor),
    );
  }
}

class _CertIcon extends StatelessWidget {
  final String url;

  const _CertIcon({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: 16,
      height: 16,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
