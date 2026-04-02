import 'package:bluefish/models/floor_meta.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AuthorInfoWidget extends StatelessWidget {
  final FloorMeta meta;
  final bool showOpBadge;

  const AuthorInfoWidget({
    super.key,
    required this.meta,
    this.showOpBadge = false,
  });

  void _navigateToUserHome(BuildContext context) {
    context.pushUserHome(euid: meta.author.euid);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String dateText = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(meta.postTime);
    final List<String> metaTexts = [
      '$dateText (${meta.postTimeReadable})',
      if (meta.postLocation.trim().isNotEmpty) 'IP:${meta.postLocation}',
    ];

    final IconData? clientIcon = switch (meta.client) {
      PostClient.android => Icons.android,
      PostClient.iphone => Icons.apple,
      PostClient.pc => Icons.desktop_windows_outlined,
      PostClient.unknown => null,
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
                meta.author.avatarURL.toString(),
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
                        meta.author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (meta.author.adminsInfo != null)
                    _MetaBadge(
                      label: meta.author.adminsInfo!,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  if (showOpBadge)
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
