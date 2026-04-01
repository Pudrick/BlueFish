import 'package:bluefish/models/vote.dart';
import 'package:bluefish/services/vote_service.dart';
import 'package:bluefish/widgets/html/vote/dual_image_vote_widget.dart';
import 'package:bluefish/widgets/html/vote/no_image_vote_widget.dart';
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
          return const Center(child: CircularProgressIndicator());
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

    return Card(
      margin: const EdgeInsets.all(7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '投票加载失败',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
