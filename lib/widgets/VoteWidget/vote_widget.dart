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

  @override
  Future<void> initState() async {
    // TODO: implement initState
    super.initState();
    await vote.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (vote.type == VoteType.dualImage) {
      return DualImageVoteWidget(vote: vote);
    } else {
      return NoImageVoteWidget(vote: vote);
    }
  }
}
