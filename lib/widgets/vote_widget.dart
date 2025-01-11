import 'package:flutter/material.dart';

import '../models/vote.dart';

class DualImageVoteWidget extends StatefulWidget {
  final Vote vote;

  static const double borderRoundRadius = 17;

  const DualImageVoteWidget({super.key, required this.vote});

  @override
  State<DualImageVoteWidget> createState() => _DualImageVoteWidgetState();
}

class _DualImageVoteWidgetState extends State<DualImageVoteWidget> {
  late Vote vote;

  @override
  void initState() {
    super.initState();
    vote = widget.vote;
  }

  Widget canVoteButtonWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: InkWell(
            // TODO: stupid implementation. maybe there's better constraints.
            borderRadius: const BorderRadius.only(
                bottomLeft:
                    Radius.circular(DualImageVoteWidget.borderRoundRadius)),

            onTap: () {},
            child: Ink(
              decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                          DualImageVoteWidget.borderRoundRadius))),
              height: 85,
              child: Center(
                  child: Text(widget.vote.voteDetailList[0].content,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 27))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Material(
            child: Ink(
              decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(
                          DualImageVoteWidget.borderRoundRadius))),
              height: 85,
              child: InkWell(
                // stupid, but works.
                borderRadius: const BorderRadius.only(
                    bottomRight:
                        Radius.circular(DualImageVoteWidget.borderRoundRadius)),

                onTap: () {},
                child: Center(
                    child: Text(widget.vote.voteDetailList[1].content,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 27))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          children: [
            Text(
              widget.vote.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(
                            DualImageVoteWidget.borderRoundRadius)),
                    child: Image.network(
                        widget.vote.voteDetailList[0].attachment.toString(),
                        fit: BoxFit.fill),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(
                            DualImageVoteWidget.borderRoundRadius)),
                    child: Image.network(
                        widget.vote.voteDetailList[1].attachment.toString(),
                        fit: BoxFit.fill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (vote.canVote == true) canVoteButtonWidget()
          ],
        ),
      ),
    );
  }
}
