import 'package:flutter/material.dart';

class PrivateMessageConversationHeader extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final int totalMessages;
  final int? interval;
  final bool isSystem;
  final bool unread;
  final bool isBanned;

  const PrivateMessageConversationHeader({
    super.key,
    required this.title,
    required this.avatarUrl,
    required this.totalMessages,
    required this.interval,
    required this.isSystem,
    required this.unread,
    required this.isBanned,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final metaSegments = <String>['共 $totalMessages 条消息'];
    if (interval != null && interval! > 0) {
      metaSegments.add('发信间隔 ${interval}s');
    }

    return Material(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PrivateMessageConversationAvatar(
                  avatarUrl: avatarUrl,
                  size: 44,
                  fallbackIcon: isSystem
                      ? Icons.shield_outlined
                      : Icons.chat_bubble_outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metaSegments.join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isSystem)
                  _PrivateMessageHeaderBadge(
                    icon: Icons.admin_panel_settings_outlined,
                    label: '系统消息',
                    foregroundColor: colorScheme.onSecondaryContainer,
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
                if (unread)
                  _PrivateMessageHeaderBadge(
                    icon: Icons.mark_chat_unread_outlined,
                    label: '未读会话',
                    foregroundColor: colorScheme.onError,
                    backgroundColor: colorScheme.error,
                  ),
                if (isBanned)
                  _PrivateMessageHeaderBadge(
                    icon: Icons.lock_outline,
                    label: '当前不可发信',
                    foregroundColor: colorScheme.onTertiaryContainer,
                    backgroundColor: colorScheme.tertiaryContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateMessageHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _PrivateMessageHeaderBadge({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateMessageConversationAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final IconData fallbackIcon;

  const PrivateMessageConversationAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 36,
    this.fallbackIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(
                fallbackIcon,
                size: size * 0.56,
                color: colorScheme.onSurfaceVariant,
              )
            : Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: size * 0.56,
                    color: colorScheme.onSurfaceVariant,
                  );
                },
              ),
      ),
    );
  }
}

class PrivateMessageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const PrivateMessageHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant PrivateMessageHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
