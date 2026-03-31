import 'package:bluefish/models/abstract_floor_content.dart';
import 'package:bluefish/models/single_reply_floor.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AuthorInfoWidget extends StatelessWidget {
  final FloorContent content;
  const AuthorInfoWidget({super.key, required this.content});

  void _navigateToUserHome(BuildContext context) {
    context.pushNamed(
      AppRouteNames.userHome,
      pathParameters: {'euid': content.author.euid},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String dateText = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(content.postTime);
    final List<String> metaTexts = [
      '$dateText (${content.postTimeReadable})',
      if (content.postLocation.trim().isNotEmpty) 'IP:${content.postLocation}',
    ];

    final IconData? clientIcon = switch (content.client) {
      'ANDROID' => Icons.android,
      'IPHONE' => Icons.apple,
      'PC' => Icons.desktop_windows_outlined,
      String() => null,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToUserHome(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                content.author.avatarURL.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToUserHome(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        content.author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (content.author.adminsInfo != null)
                    _MetaBadge(
                      label: content.author.adminsInfo!,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  if (content case SingleReplyFloor replyContent)
                    if (replyContent.isOP)
                      _MetaBadge(
                        label: '楼主',
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  for (final text in metaTexts)
                    Text(
                      text,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (clientIcon != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              clientIcon,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MetaBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
