import 'package:bluefish/models/single_thread_title.dart';
import 'package:flutter/material.dart';

class SingleThreadTitleCard extends StatelessWidget {
  final SingleThreadTitle threadTitle;
  final VoidCallback? onTap;
  final bool showEssenceBadge;

  const SingleThreadTitleCard({
    super.key,
    required this.threadTitle,
    this.onTap,
    this.showEssenceBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final leadingBadges = _buildLeadingTitleBadges(colorScheme);
    final badges = _buildStatusBadges(colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (threadTitle.isPinned == true) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leadingBadges.isNotEmpty) ...[
                          for (var i = 0; i < leadingBadges.length; i++) ...[
                            leadingBadges[i],
                            if (i != leadingBadges.length - 1)
                              const SizedBox(width: 6),
                          ],
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            threadTitle.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: badges),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _ThreadInfoItem(
                          icon: Icons.thumb_up_outlined,
                          text: '${threadTitle.recommends}推荐',
                        ),
                        _ThreadInfoItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: '${threadTitle.repliesNum}回复',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ThreadInfoItem(
                            icon: Icons.schedule_outlined,
                            text: threadTitle.time,
                            maxWidth: 150,
                          ),
                          _ThreadInfoItem(
                            icon: Icons.account_circle_outlined,
                            text: threadTitle.authorName,
                            maxWidth: 110,
                          ),
                        ],
                      ),
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

  List<Widget> _buildLeadingTitleBadges(ColorScheme colorScheme) {
    final badges = <Widget>[];

    if (showEssenceBadge) {
      badges.add(
        _ThreadStatusBadge(
          icon: Icons.auto_awesome_rounded,
          label: '精华',
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      );
    }

    if (threadTitle.threadType == 'video') {
      badges.add(
        _ThreadStatusBadge(
          icon: Icons.play_circle_outline_rounded,
          label: '视频',
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      );
    } else if (threadTitle.threadType == 'vote') {
      badges.add(
        _ThreadStatusBadge(
          icon: Icons.bar_chart_rounded,
          label: '投票',
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        ),
      );
    }

    return badges;
  }

  List<Widget> _buildStatusBadges(ColorScheme colorScheme) {
    final badges = <Widget>[];

    if (threadTitle.isGif) {
      badges.add(
        _ThreadStatusBadge(
          icon: Icons.gif_box_outlined,
          label: 'GIF',
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
        ),
      );
    }

    return badges;
  }
}

class _ThreadStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ThreadStatusBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final double? maxWidth;

  const _ThreadInfoItem({
    required this.icon,
    required this.text,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 220),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
