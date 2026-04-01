import 'package:flutter/material.dart';

class VoteActionBar extends StatelessWidget {
  final int selectedCount;
  final int optionLimit;
  final VoidCallback? onSubmit;

  const VoteActionBar({
    super.key,
    required this.selectedCount,
    required this.optionLimit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final clampedLimit = optionLimit < 1 ? 1 : optionLimit;
    final helperText = selectedCount == 0 ? '请选择后再确认投票' : '确认后将提交当前选择';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '已选择 $selectedCount / $clampedLimit 项',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                helperText,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: selectedCount > 0 ? onSubmit : null,
            icon: const Icon(Icons.how_to_vote_rounded),
            label: const Text('确认投票'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}
