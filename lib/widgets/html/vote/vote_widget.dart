import 'package:bluefish/models/vote.dart';
import 'package:bluefish/services/vote/vote_service.dart';
import 'package:bluefish/widgets/html/vote/dual_image_vote_widget.dart';
import 'package:bluefish/widgets/html/vote/no_image_vote_widget.dart';
import 'package:bluefish/widgets/html/vote/vote_card_shell.dart';
import 'package:flutter/material.dart';

class VoteWidget extends StatefulWidget {
  final int voteId;
  final VoteService? voteService;

  const VoteWidget({super.key, required this.voteId, this.voteService});

  @override
  State<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends State<VoteWidget> {
  late Future<Vote> _voteFuture;

  VoteService get _voteService => widget.voteService ?? VoteService();

  @override
  void initState() {
    super.initState();
    _voteFuture = _loadVote();
  }

  @override
  void didUpdateWidget(covariant VoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voteId != widget.voteId ||
        oldWidget.voteService != widget.voteService) {
      _voteFuture = _loadVote();
    }
  }

  Future<Vote> _loadVote() {
    return _voteService.getVote(widget.voteId);
  }

  void _retry() {
    setState(() {
      _voteFuture = _loadVote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Vote>(
      future: _voteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _VoteLoadingCard();
        }

        if (snapshot.hasError) {
          return _VoteLoadError(onRetry: _retry);
        }

        final vote = snapshot.data;
        if (vote == null) {
          return const SizedBox.shrink();
        }

        if (vote.isDualImageLayout) {
          return DualImageVoteWidget(vote: vote);
        }

        return NoImageVoteWidget(vote: vote);
      },
    );
  }
}

class _VoteLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _VoteLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return VoteCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                '投票加载失败',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '网络状态不稳定时可能会出现这个问题，你可以稍后再试一次。',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _VoteLoadingCard extends StatelessWidget {
  const _VoteLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return VoteCardShell(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Text(
            '正在加载投票内容',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
