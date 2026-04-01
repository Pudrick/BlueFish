import 'package:bluefish/models/vote.dart';
import 'package:flutter/material.dart';

class VoteInfoWidget extends StatelessWidget {
  final Vote vote;

  const VoteInfoWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vote.title,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VoteMetaPill(
              icon: Icons.how_to_vote_outlined,
              label: vote.userOptionLimit == 1
                  ? '单选'
                  : '最多${vote.userOptionLimit}项',
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
            _VoteMetaPill(
              icon: Icons.group_outlined,
              label: '${vote.userCount}人参与',
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            _VoteMetaPill(
              icon: Icons.bar_chart_rounded,
              label: '${vote.voteCount}票',
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            if (vote.end)
              _VoteMetaPill(
                icon: Icons.timer_off_outlined,
                label: '投票已结束',
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              )
            else if (vote.endTimeStr.trim().isNotEmpty)
              _VoteMetaPill(
                icon: Icons.schedule_rounded,
                label: vote.endTimeStr,
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
              ),
          ],
        ),
      ],
    );
  }
}

class _VoteMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _VoteMetaPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
