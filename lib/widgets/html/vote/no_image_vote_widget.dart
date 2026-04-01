import 'package:bluefish/models/vote.dart';
import 'package:bluefish/widgets/html/vote/vote_info_widget.dart';
import 'package:flutter/material.dart';

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
    super.initState();
    selectedOptions = List<int>.from(
      widget.vote.userSelectedOptionSorts ?? const <int>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in widget.vote.options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 70),
            child: ChoiceChip.elevated(
              label: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(option.content),
              ),
              selected: selectedOptions.contains(option.sort),
              onSelected:
                  ((selectedOptions.length < widget.vote.userOptionLimit ||
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
                  : null,
            ),
          ),
        if (widget.vote.options.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('暂无投票选项'),
          ),
      ],
    );
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
        child: Column(
          children: [
            VoteInfoWidget(vote: vote),
            const SizedBox(height: 10),
            NoImageVoteButton(vote: vote),
            const SizedBox(height: 10),
            if (vote.canCancelVote)
              ElevatedButton(child: const Text("取消投票"), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
