import 'package:bluefish/models/vote.dart';
import 'package:bluefish/theme/bluefish_semantic_colors.dart';
import 'package:bluefish/widgets/html/vote/vote_action_bar.dart';
import 'package:bluefish/widgets/html/vote/vote_card_shell.dart';
import 'package:bluefish/widgets/html/vote/vote_info_widget.dart';
import 'package:flutter/material.dart';

class NoImageVoteWidget extends StatefulWidget {
  final Vote vote;

  const NoImageVoteWidget({super.key, required this.vote});

  @override
  State<NoImageVoteWidget> createState() => _NoImageVoteWidgetState();
}

class _NoImageVoteWidgetState extends State<NoImageVoteWidget> {
  late List<int> _selectedOptions;

  Vote get _vote => widget.vote;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List<int>.from(
      widget.vote.userSelectedOptionSorts ?? const <int>[],
    );
  }

  @override
  void didUpdateWidget(covariant NoImageVoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vote != widget.vote) {
      _selectedOptions = List<int>.from(
        widget.vote.userSelectedOptionSorts ?? const <int>[],
      );
    }
  }

  bool _isSelected(int sort) => _selectedOptions.contains(sort);

  bool _canToggleOption(int sort) {
    if (!_vote.canVote) {
      return false;
    }

    return _isSelected(sort) ||
        _vote.userOptionLimit <= 1 ||
        _selectedOptions.length < _vote.userOptionLimit;
  }

  void _toggleOption(int sort) {
    if (!_vote.canVote) {
      return;
    }

    setState(() {
      if (_selectedOptions.contains(sort)) {
        _selectedOptions.remove(sort);
        return;
      }

      if (_vote.userOptionLimit <= 1) {
        _selectedOptions = <int>[sort];
        return;
      }

      if (_selectedOptions.length < _vote.userOptionLimit) {
        _selectedOptions.add(sort);
      }
    });
  }

  void _showPendingSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return VoteCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VoteInfoWidget(vote: _vote),
          const SizedBox(height: 16),
          if (_vote.options.isEmpty)
            const _EmptyVoteState()
          else
            Column(
              children: [
                for (var index = 0; index < _vote.options.length; index++) ...[
                  _TextVoteOptionTile(
                    option: _vote.options[index],
                    isSelected: _isSelected(_vote.options[index].sort),
                    enabled: _canToggleOption(_vote.options[index].sort),
                    showResults: !_vote.canVote,
                    onTap: _canToggleOption(_vote.options[index].sort)
                        ? () => _toggleOption(_vote.options[index].sort)
                        : null,
                  ),
                  if (index != _vote.options.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          if (_vote.canVote) ...[
            const SizedBox(height: 16),
            VoteActionBar(
              selectedCount: _selectedOptions.length,
              optionLimit: _vote.userOptionLimit,
              onSubmit: _selectedOptions.isEmpty
                  ? null
                  : () => _showPendingSnackBar('投票提交尚未接入'),
            ),
          ],
          if (_vote.canCancelVote) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showPendingSnackBar('取消投票尚未接入'),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('取消投票'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextVoteOptionTile extends StatelessWidget {
  final VoteOption option;
  final bool isSelected;
  final bool enabled;
  final bool showResults;
  final VoidCallback? onTap;

  const _TextVoteOptionTile({
    required this.option,
    required this.isSelected,
    required this.enabled,
    required this.showResults,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(16);
    final foregroundColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.55);
    final outlineColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.65);
    final backgroundColor = showResults
        ? (isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.75))
        : (isSelected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.92)
              : colorScheme.surface.withValues(alpha: 0.7));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: outlineColor,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      option.content,
                      style: textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (showResults)
                    _ResultPercentBadge(
                      percentage: option.percentage,
                      selected: isSelected,
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              if (showResults) ...[
                const SizedBox(height: 12),
                _VoteProgressBar(
                  value: option.percentage,
                  selected: isSelected,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${option.optionVoteCount}票',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '已选择',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPercentBadge extends StatelessWidget {
  final double percentage;
  final bool selected;

  const _ResultPercentBadge({required this.percentage, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = selected
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.surface;
    final foregroundColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${(percentage * 100).toStringAsFixed(0)}%',
        style: textTheme.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VoteProgressBar extends StatelessWidget {
  final double value;
  final bool selected;

  const _VoteProgressBar({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = context.semanticColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: selected
              ? colorScheme.primary
              : semanticColors.voteTrailingAccent,
        ),
      ),
    );
  }
}

class _EmptyVoteState extends StatelessWidget {
  const _EmptyVoteState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '暂无投票选项',
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
