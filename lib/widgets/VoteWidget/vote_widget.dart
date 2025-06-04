import 'package:bluefish/models/vote.dart';
import 'package:flutter/material.dart';

import 'no_image_vote_widget.dart';
import 'dual_image_vote_widget.dart';

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
    // TODO: implement initState
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
    } else {
      if (vote.type == VoteType.dualImage) {
        return DualImageVoteWidget(vote: vote);
      } else {
        return NoImageVoteWidget(vote: vote);
      }
    }
  }
}
