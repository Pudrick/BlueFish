import 'package:bluefish/models/vote.dart';
import 'package:bluefish/widgets/html/vote/dual_image_vote_widget.dart';
import 'package:bluefish/widgets/html/vote/no_image_vote_widget.dart';
import 'package:flutter/material.dart';

class VoteWidget extends StatefulWidget {
  final int voteID;

  const VoteWidget({super.key, required this.voteID});

  @override
  State<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends State<VoteWidget> {
  late Vote vote;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    vote = Vote(widget.voteID);
    _initVote();
  }

  Future<void> _initVote() async {
    await vote.refresh();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (vote.type == VoteType.dualImage) {
      return DualImageVoteWidget(vote: vote);
    }

    return NoImageVoteWidget(vote: vote);
  }
}
