import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrivateMessageHistoryStatusCard extends StatelessWidget {
  final int loadedCount;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingOlder;

  const PrivateMessageHistoryStatusCard({
    super.key,
    required this.loadedCount,
    required this.totalCount,
    required this.hasNextPage,
    required this.isLoadingOlder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget leading;
    final String title;
    final String subtitle;

    if (isLoadingOlder) {
      leading = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
      title = '正在加载更早消息';
      subtitle = '已载入 $loadedCount / $totalCount';
    } else if (hasNextPage) {
      leading = Icon(
        Icons.keyboard_double_arrow_up_rounded,
        size: 20,
        color: colorScheme.primary,
      );
      title = '上滑加载更早消息';
      subtitle = '当前已载入 $loadedCount / $totalCount';
    } else {
      leading = Icon(
        Icons.done_all_rounded,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      );
      title = '已经到最早消息';
      subtitle = '共 $totalCount 条消息';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateMessageEmptyConversationState extends StatelessWidget {
  final bool isSystem;

  const PrivateMessageEmptyConversationState({
    super.key,
    required this.isSystem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSystem ? Icons.inbox_outlined : Icons.forum_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isSystem ? '暂时没有系统消息' : '这个会话还没有内容',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉即可重新刷新消息列表',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivateMessageConversationDateDivider extends StatelessWidget {
  final DateTime date;

  const PrivateMessageConversationDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
        ],
      ),
    );
  }
}
