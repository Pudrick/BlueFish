import 'package:flutter/material.dart';

import '../../models/vote.dart';
import 'vote_info_widget.dart';

class NoImageVoteButton extends StatefulWidget {
  final Vote vote;

  const NoImageVoteButton({super.key, required this.vote});

  @override
  State<NoImageVoteButton> createState() => _NoImageVoteButtonState();
}

class _NoImageVoteButtonState extends State<NoImageVoteButton> {
  List<int> selectedOptions = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.vote.userVoteRecordList != null) {
      selectedOptions = widget.vote.userVoteRecordList!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var option in widget.vote.voteDetailList)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 70),
            child:
                // ElevatedButton(
                //   onPressed: () {},
                //   child: Text(option.content),
                // )
                ChoiceChip.elevated(
                    label: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(option.content)),
                    selected: selectedOptions.contains(option.sort),
                    onSelected: ((selectedOptions.length <
                                    widget.vote.userOptionLimit ||
                                selectedOptions.contains(option.sort)) &&
                            widget.vote.canVote)
                        ? (value) {
                            setState(() {
                              if (selectedOptions.contains(option.sort)) {
                                selectedOptions.remove(option.sort);
                              } else {
                                selectedOptions.add(option.sort);
                              }
                            });
                          }
                        : null)),
    ]);
  }
}

class NoImageVoteWidget extends StatelessWidget {
  final Vote vote;

  const NoImageVoteWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(7),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          VoteInfoWidget(vote: vote),
          const SizedBox(height: 10),
          NoImageVoteButton(vote: vote),
          const SizedBox(height: 10),
          if (vote.userVoteRecordList != null && vote.end == false)
            ElevatedButton(child: const Text("取消投票"), onPressed: () {})
          // TODO: add a pie chart to show the percentage of each option
        ]),
      ),
    );
  }
}
