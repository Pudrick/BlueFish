import 'package:bluefish/models/vote.dart';
import 'package:bluefish/theme/bluefish_semantic_colors.dart';
import 'package:bluefish/widgets/html/vote/vote_action_bar.dart';
import 'package:bluefish/widgets/html/vote/vote_card_shell.dart';
import 'package:bluefish/widgets/html/vote/vote_info_widget.dart';
import 'package:flutter/material.dart';

enum _DualImageVoteTone { leading, trailing }

Color _resolveVoteToneColor(BuildContext context, _DualImageVoteTone tone) {
  final semanticColors = context.semanticColors;

  return switch (tone) {
    _DualImageVoteTone.leading => semanticColors.voteLeadingAccent,
    _DualImageVoteTone.trailing => semanticColors.voteTrailingAccent,
  };
}

class DualImageVoteWidget extends StatefulWidget {
  final Vote vote;

  DualImageVoteWidget({super.key, required this.vote})
    : assert(vote.isDualImageLayout);

  @override
  State<DualImageVoteWidget> createState() => _DualImageVoteWidgetState();
}

class _DualImageVoteWidgetState extends State<DualImageVoteWidget> {
  late List<int> _selectedOptionSorts;

  Vote get _vote => widget.vote;

  VoteOption get _leftOption => _vote.options[0];

  VoteOption get _rightOption => _vote.options[1];

  @override
  void initState() {
    super.initState();
    _selectedOptionSorts = List<int>.from(
      _vote.userSelectedOptionSorts ?? const <int>[],
    );
  }

  @override
  void didUpdateWidget(covariant DualImageVoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vote != widget.vote) {
      _selectedOptionSorts = List<int>.from(
        _vote.userSelectedOptionSorts ?? const <int>[],
      );
    }
  }

  bool _isSelected(VoteOption option) {
    return _selectedOptionSorts.contains(option.sort);
  }

  bool _canToggle(VoteOption option) {
    if (!_vote.canVote) {
      return false;
    }

    return _isSelected(option) ||
        _vote.userOptionLimit <= 1 ||
        _selectedOptionSorts.length < _vote.userOptionLimit;
  }

  void _toggle(VoteOption option) {
    if (!_vote.canVote) {
      return;
    }

    setState(() {
      if (_isSelected(option)) {
        _selectedOptionSorts.remove(option.sort);
        return;
      }

      if (_vote.userOptionLimit <= 1) {
        _selectedOptionSorts = <int>[option.sort];
        return;
      }

      if (_selectedOptionSorts.length < _vote.userOptionLimit) {
        _selectedOptionSorts.add(option.sort);
      }
    });
  }

  int _resolvedFlex(int value) => value > 0 ? value : 1;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumn = constraints.maxWidth < 440;

              if (useColumn) {
                return Column(
                  children: [
                    _DualImageVoteOptionCard(
                      option: _leftOption,
                      selected: _isSelected(_leftOption),
                      enabled: _canToggle(_leftOption),
                      showResults: !_vote.canVote,
                      tone: _DualImageVoteTone.leading,
                      onTap: _canToggle(_leftOption)
                          ? () => _toggle(_leftOption)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _DualImageVoteOptionCard(
                      option: _rightOption,
                      selected: _isSelected(_rightOption),
                      enabled: _canToggle(_rightOption),
                      showResults: !_vote.canVote,
                      tone: _DualImageVoteTone.trailing,
                      onTap: _canToggle(_rightOption)
                          ? () => _toggle(_rightOption)
                          : null,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DualImageVoteOptionCard(
                      option: _leftOption,
                      selected: _isSelected(_leftOption),
                      enabled: _canToggle(_leftOption),
                      showResults: !_vote.canVote,
                      tone: _DualImageVoteTone.leading,
                      onTap: _canToggle(_leftOption)
                          ? () => _toggle(_leftOption)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DualImageVoteOptionCard(
                      option: _rightOption,
                      selected: _isSelected(_rightOption),
                      enabled: _canToggle(_rightOption),
                      showResults: !_vote.canVote,
                      tone: _DualImageVoteTone.trailing,
                      onTap: _canToggle(_rightOption)
                          ? () => _toggle(_rightOption)
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
          if (!_vote.canVote) ...[
            const SizedBox(height: 16),
            _VoteComparisonBar(
              leftOption: _leftOption,
              rightOption: _rightOption,
              leftSelected: _isSelected(_leftOption),
              rightSelected: _isSelected(_rightOption),
              leftFlex: _resolvedFlex(_leftOption.optionVoteCount),
              rightFlex: _resolvedFlex(_rightOption.optionVoteCount),
            ),
          ],
          if (_vote.canVote) ...[
            const SizedBox(height: 16),
            VoteActionBar(
              selectedCount: _selectedOptionSorts.length,
              optionLimit: _vote.userOptionLimit,
              onSubmit: _selectedOptionSorts.isEmpty
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

class _DualImageVoteOptionCard extends StatelessWidget {
  final VoteOption option;
  final bool selected;
  final bool enabled;
  final bool showResults;
  final _DualImageVoteTone tone;
  final VoidCallback? onTap;

  const _DualImageVoteOptionCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.showResults,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = context.semanticColors;
    final accentColor = _resolveVoteToneColor(context, tone);
    final borderRadius = BorderRadius.circular(18);
    final imageBorderRadius = BorderRadius.circular(15);
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.7);
    final backgroundColor = showResults
        ? (selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.78))
        : (selected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.95)
              : colorScheme.surface.withValues(alpha: 0.75));

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
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: imageBorderRadius,
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _VoteImage(url: option.attachment.toString()),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  semanticColors.mediaOverlay.withValues(
                                    alpha: 0.02,
                                  ),
                                  semanticColors.mediaOverlay.withValues(
                                    alpha: 0.38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: semanticColors.mediaOverlay
                                          .withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: semanticColors.onMediaOverlay,
                                  size: 20,
                                ),
                              ),
                            ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Text(
                              option.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: semanticColors.onMediaOverlay,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!showResults && !enabled && !selected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Text(
                      '已达到选择上限',
                      style: textTheme.bodySmall?.copyWith(
                        color: accentColor.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteImage extends StatelessWidget {
  final String url;

  const _VoteImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes == null
                  ? null
                  : loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 36,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _VoteComparisonBar extends StatelessWidget {
  final VoteOption leftOption;
  final VoteOption rightOption;
  final bool leftSelected;
  final bool rightSelected;
  final int leftFlex;
  final int rightFlex;

  const _VoteComparisonBar({
    required this.leftOption,
    required this.rightOption,
    required this.leftSelected,
    required this.rightSelected,
    required this.leftFlex,
    required this.rightFlex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final leftColor = leftSelected
        ? colorScheme.primary
        : _resolveVoteToneColor(context, _DualImageVoteTone.leading);
    final rightColor = rightSelected
        ? colorScheme.primary
        : _resolveVoteToneColor(context, _DualImageVoteTone.trailing);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投票结果',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VoteScore(
                  alignment: CrossAxisAlignment.start,
                  percentage: leftOption.percentage,
                  voteCount: leftOption.optionVoteCount,
                  accentColor: leftColor,
                  emphasized: leftSelected,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VoteScore(
                  alignment: CrossAxisAlignment.end,
                  percentage: rightOption.percentage,
                  voteCount: rightOption.optionVoteCount,
                  accentColor: rightColor,
                  emphasized: rightSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 28,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: leftFlex,
                        child: Container(
                          color: leftColor.withValues(alpha: 0.88),
                        ),
                      ),
                      Expanded(
                        flex: rightFlex,
                        child: Container(
                          color: rightColor.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VoteLegend(
                  label: leftOption.content,
                  voteCount: leftOption.optionVoteCount,
                  percentage: leftOption.percentage,
                  accentColor: leftColor,
                  selected: leftSelected,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VoteLegend(
                  label: rightOption.content,
                  voteCount: rightOption.optionVoteCount,
                  percentage: rightOption.percentage,
                  accentColor: rightColor,
                  selected: rightSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteScore extends StatelessWidget {
  final CrossAxisAlignment alignment;
  final double percentage;
  final int voteCount;
  final Color accentColor;
  final bool emphasized;

  const _VoteScore({
    required this.alignment,
    required this.percentage,
    required this.voteCount,
    required this.accentColor,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: textTheme.headlineSmall?.copyWith(
            color: accentColor,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$voteCount票',
          style: textTheme.labelMedium?.copyWith(
            color: accentColor.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VoteLegend extends StatelessWidget {
  final String label;
  final int voteCount;
  final double percentage;
  final Color accentColor;
  final bool selected;

  const _VoteLegend({
    required this.label,
    required this.voteCount,
    required this.percentage,
    required this.accentColor,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$voteCount票 · ${(percentage * 100).toStringAsFixed(0)}%',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (selected)
                Text(
                  '我的选择',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
