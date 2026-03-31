import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/widgets/html/bluefish_html_widget.dart';
import 'package:bluefish/widgets/thread/author_info_widget.dart';
import 'package:flutter/material.dart';

// html widget package.
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ThreadTitleWidget extends StatelessWidget {
  final String title;
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  const ThreadTitleWidget({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        constraints: BoxConstraints(minHeight: totalPages > 1 ? 72 : 64),
        padding: EdgeInsets.fromLTRB(8, totalPages > 1 ? 8 : 10, 16, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: '返回',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '第$currentPage页 / 共$totalPages页',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThreadMainFloorWidget extends StatelessWidget {
  final bool hasVote;
  final ThreadMain mainFloor;
  final double contentMaxWidth;

  const ThreadMainFloorWidget({
    super.key,
    this.hasVote = false,
    required this.mainFloor,
    this.contentMaxWidth = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorInfoWidget(content: mainFloor),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MainMetaPill(
                  icon: Icons.thumb_up_outlined,
                  label: '${mainFloor.recommendNum}推荐',
                ),
                _MainMetaPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${mainFloor.repliesNum}回复',
                ),
                _MainMetaPill(
                  icon: Icons.visibility_outlined,
                  label: '${mainFloor.readNum}浏览',
                ),
                if (mainFloor.hasVote)
                  const _MainMetaPill(
                    icon: Icons.bar_chart_rounded,
                    label: '投票贴',
                  ),
                if (mainFloor.hasVideo)
                  const _MainMetaPill(
                    icon: Icons.play_circle_outline_rounded,
                    label: '视频贴',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: BluefishHtmlWidget(
                  mainFloor.contentHTML,
                  enableImageGallery: true,
                  imageHeroScope: 'thread-main:${mainFloor.tid}',
                  textStyle: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MainMetaPill({required this.icon, required this.label});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyHeaderDelegate({required this.child, this.height = 64.0});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
