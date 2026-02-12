import 'package:bluefish/models/user_homepage/user_home_thread_title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserHomeThreadListWidget extends StatelessWidget {
  final List<UserHomeThreadTitle> threadsList;

  final bool isLoading;
  final bool isLastPage;

  const UserHomeThreadListWidget({
    super.key,
    required this.threadsList,
    required this.isLoading,
    required this.isLastPage,
  });

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _threadCard(BuildContext context, UserHomeThreadTitle threadTitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {},
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: colorScheme.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "发送时间：${DateFormat("yyyy-MM-dd HH:mm:ss").format(threadTitle.postTime)}",
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.timer_outlined,
                    color: colorScheme.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "最后回复：${DateFormat("yyyy-MM-dd HH:mm:ss").format(threadTitle.lastReplyTime)}",
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              // horizontalDivider,
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    if (threadTitle.videoInfo != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    TextSpan(
                      text: threadTitle.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (threadTitle.mainFloorPeek != null) ...[
                const SizedBox(height: 6),
                Text(
                  threadTitle.mainFloorPeek!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                // horizontalDivider,
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (threadTitle.isLock) const Icon(Icons.lock_outline),
                  const SizedBox(width: 2),
                  const Spacer(),
                  _buildStatItem(
                    context,
                    Icons.remove_red_eye_outlined,
                    "${threadTitle.visits}",
                  ),
                  _buildStatItem(
                    context,
                    Icons.thumb_up_outlined,
                    "${threadTitle.lights}",
                  ),
                  _buildStatItem(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    "${threadTitle.repliesNum}",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLastPage
          ? Text(
              "—— 后面没有了 ——",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index == threadsList.length) return _buildFooter(context);
        final item = threadsList[index];
        return _threadCard(context, item);
      }, childCount: threadsList.length + 1),
    );
  }
}
