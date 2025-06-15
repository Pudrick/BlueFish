import "package:bluefish/widgets/author_info_widget.dart";
import "package:bluefish/widgets/htmlWidget_with_vote.dart";
import "package:flutter/material.dart";

import 'package:bluefish/models/single_reply_floor.dart';

class ReplyFloor extends StatelessWidget {
  final SingleReplyFloor replyFloor;

  const ReplyFloor({super.key, required this.replyFloor});

  @override
  Widget build(BuildContext context) {
    if (replyFloor.isDelete || replyFloor.isSelfDelete || replyFloor.isHidden) {
      return const SizedBox.shrink();
    } else {
      const double buttonHeight = 36.0;
      const double capsuleRadius = buttonHeight / 2;
      const double adjacentCornerRadius = 4.0;

      return Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorInfoWidget(content: replyFloor),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: HtmlWidgetWithVote(replyFloor.contentHTML),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(capsuleRadius),
                                  right:
                                      Radius.circular(adjacentCornerRadius)))),

                      // the effect is same.

                      //  ButtonStyle(
                      // shape:
                      //     WidgetStateProperty.all<RoundedRectangleBorder>(
                      //         const RoundedRectangleBorder(
                      //             borderRadius: BorderRadius.horizontal(
                      //                 left: Radius.circular(capsuleRadius),
                      //                 right: Radius.circular(
                      //                     adjacentCornerRadius))))),
                      child: Row(
                        children: [
                          const Icon(Icons.wb_incandescent_outlined),
                          Text(" ${replyFloor.lightCount}"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(capsuleRadius),
                                  left:
                                      Radius.circular(adjacentCornerRadius)))),
                      child: const Icon(Icons.thumb_down_alt_outlined),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }
  }
}
