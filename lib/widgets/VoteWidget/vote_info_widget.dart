import 'package:flutter/material.dart';
import '../../models/vote.dart';

class VoteInfoWidget extends StatelessWidget {
  final Vote vote;

  const VoteInfoWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    const double titleFontSize = 25;

    return Column(children: [
      Text(
        vote.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: titleFontSize, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
            child: ActionChip(
          onPressed: () {},
          avatar: const Icon(Icons.group_outlined),
          label: Text(vote.userCount.toString()),
        )),
        Expanded(
            child: ActionChip(
          onPressed: () {},
          avatar: const Icon(Icons.how_to_vote_outlined),
          label: Text("最多选择${vote.userOptionLimit}项"),
        )),
        if (vote.endTimeStr != "")
          Expanded(
              child: ActionChip(
            onPressed: () {},
            avatar: const Icon(Icons.timer_10_outlined),
            label: Text(vote.endTimeStr),
          )),
        if (vote.end == true)
          Expanded(
              child: ActionChip(
            onPressed: () {},
            avatar: const Icon(Icons.timer_off_outlined),
            label: const Text("投票已结束"),
          ))
      ])
    ]);
  }
}
