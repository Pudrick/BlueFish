import 'package:flutter/material.dart';

import '../models/vote.dart';

class DualImageCanVoteWidget extends StatelessWidget {
  final Vote vote;

  static const double borderRoundRadius = 17;

  const DualImageCanVoteWidget({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(5),
      child: Column(
        children: [
          Text(
            vote.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(borderRoundRadius),
                    bottomLeft: Radius.circular(borderRoundRadius)),
                child:
                    Image.network(vote.voteDetailList[0].attachment.toString()),
              ),
              Container(
                width: 10,
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(borderRoundRadius),
                    bottomRight: Radius.circular(borderRoundRadius)),
                child:
                    Image.network(vote.voteDetailList[1].attachment.toString()),
              )
            ],
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
              ),
              AnimatedContainer(duration: const Duration(milliseconds: 700))
            ],
          )
        ],
      ),
    );
  }
}
