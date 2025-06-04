import 'package:flutter/material.dart';
import 'vote_info_widget.dart';

import '../../models/vote.dart';

class DualImageVoteWidget extends StatefulWidget {
  final Vote vote;

  static const double outerBorderRoundRadius = 12;
  static const double innerBorderRoundRadius = 10;
  static const double buttonVerticalMargin = 24;

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

  // TODO: add limitation of max vote count.
  Widget canVoteButtonWidget() {
    // const double buttonHeight = 75;
    const double buttonVerticalMargin = 25;
    const double buttonTextSize = 27;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: buttonVerticalMargin),
                  backgroundColor: Colors.redAccent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(
                        DualImageVoteWidget.outerBorderRoundRadius)),
                  )),
              child: Text(widget.vote.voteDetailList[0].content,
                  style: const TextStyle(
                      color: Colors.white, fontSize: buttonTextSize))),
        ),
        // Expanded(
        //   flex: 1,
        //   child: InkWell(
        //     // TODO: stupid implementation. maybe there's better constraints.
        //     borderRadius: const BorderRadius.only(
        //         bottomLeft: Radius.circular(
        //             DualImageVoteWidget.outerBorderRoundRadius)),
        //     onTap: () {},
        //     child: Ink(
        //       decoration: const BoxDecoration(
        //           color: Colors.redAccent,
        //           borderRadius: BorderRadius.only(
        //               bottomLeft: Radius.circular(
        //                   DualImageVoteWidget.outerBorderRoundRadius))),
        //       height: buttonHeight,
        //       child: Center(
        //           child: Text(widget.vote.voteDetailList[0].content,
        //               style: const TextStyle(
        //                   color: Colors.white, fontSize: buttonTextSize))),
        //     ),
        //   ),
        // ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: buttonVerticalMargin),
                  backgroundColor: Colors.blue,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(
                          DualImageVoteWidget.outerBorderRoundRadius)))),
              child: Text(widget.vote.voteDetailList[1].content,
                  style: const TextStyle(
                      color: Colors.white, fontSize: buttonTextSize))),
        ),
        // Expanded(
        //   flex: 1,
        //   child: Material(
        //     child: Ink(
        //       decoration: const BoxDecoration(
        //           color: Colors.blue,
        //           borderRadius: BorderRadius.only(
        //               bottomRight: Radius.circular(
        //                   DualImageVoteWidget.outerBorderRoundRadius))),
        //       height: buttonHeight,
        //       child: InkWell(
        //         // stupid, but works.
        //         borderRadius: const BorderRadius.only(
        //             bottomRight: Radius.circular(
        //                 DualImageVoteWidget.outerBorderRoundRadius)),

        //         onTap: () {},
        //         child: Center(
        //             child: Text(widget.vote.voteDetailList[1].content,
        //                 style: const TextStyle(
        //                     color: Colors.white, fontSize: buttonTextSize))),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // TODO: handle end == true, that is vote expired.
  Widget cannotVoteButtonWidget() {
    const double buttonTextSize = 17;
    const double buttonHeight = 70;
    Color leftColorOfNumberVotes =
        Theme.of(context).colorScheme.onTertiaryContainer;
    Color rightColorOfNumberVotes =
        Theme.of(context).colorScheme.onSecondaryContainer;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: buttonHeight,
            child: Row(children: [
              Card(
                elevation: 2,
                child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(
                              DualImageVoteWidget.outerBorderRoundRadius),
                          // bottomLeft: Radius.circular(
                          //     DualImageVoteWidget.innerBorderRoundRadius),
                        )),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  '${(widget.vote.voteDetailList[0].percentage * 100).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      color: leftColorOfNumberVotes,
                                      fontSize: 20)),
                              Column(children: [
                                if (widget.vote.userVoteRecordList != null)
                                  if (widget.vote.userVoteRecordList![0] == 1)
                                    Icon(Icons.check,
                                        color: leftColorOfNumberVotes),
                                const SizedBox(width: 5),
                                Text(
                                    widget
                                        .vote.voteDetailList[0].optionVoteCount
                                        .toString(),
                                    style: TextStyle(
                                        color: leftColorOfNumberVotes,
                                        fontSize: 18)),
                              ])
                            ]))),
              ),
              const SizedBox(width: 5),
              Expanded(
                  flex: widget.vote.voteDetailList[0].optionVoteCount,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(
                            DualImageVoteWidget.outerBorderRoundRadius)),
                        // border: Border.all(color: Colors.redAccent, width: 3),
                        // color: Colors.red.shade100,
                        color: Theme.of(context).colorScheme.tertiaryContainer),
                  )),
              const SizedBox(width: 5),
              Expanded(
                  flex: widget.vote.voteDetailList[1].optionVoteCount,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(
                            DualImageVoteWidget.outerBorderRoundRadius)),
                        // color: Colors.blue.shade100,
                        color: Theme.of(context).colorScheme.secondaryContainer
                        // border: Border.all(color: Colors.blue, width: 3)
                        ),
                  )),
              const SizedBox(width: 5),
              Card(
                elevation: 2,
                child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                            DualImageVoteWidget.outerBorderRoundRadius),
                        // bottomRight: Radius.circular(
                        //     DualImageVoteWidget.innerBorderRoundRadius),
                      ),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  '${(widget.vote.voteDetailList[1].percentage * 100).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      color: rightColorOfNumberVotes,
                                      fontSize: 20)),
                              Row(children: [
                                if (widget.vote.userVoteRecordList != null)
                                  if (widget.vote.userVoteRecordList![0] == 2)
                                    Icon(Icons.check_circle,
                                        color: rightColorOfNumberVotes),
                                const SizedBox(width: 5),
                                Text(
                                    widget
                                        .vote.voteDetailList[1].optionVoteCount
                                        .toString(),
                                    style: TextStyle(
                                        color: rightColorOfNumberVotes,
                                        fontSize: 18)),
                              ])
                            ]))),
              )
            ])),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: DualImageVoteWidget.buttonVerticalMargin),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(
                              DualImageVoteWidget.outerBorderRoundRadius)))),
                  // height: buttonHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.vote.userVoteRecordList != null)
                        if (widget.vote.userVoteRecordList![0] == 1)
                          Icon(
                            Icons.check,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.38),
                            size: buttonTextSize,
                          ),
                      Text(widget.vote.voteDetailList[0].content,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.38),
                              fontSize: buttonTextSize)),
                    ],
                  ))),
          const SizedBox(width: 7),
          if (widget.vote.userVoteRecordList != null &&
              widget.vote.end == false)
            SizedBox(
              // TODO: adjust this height to value that paired to the other two buttons.
              height: 55,
              child: Expanded(
                // height: buttonHeight,
                child: OutlinedButton(
                  // TODO: cancel vote.
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(
                            DualImageVoteWidget.innerBorderRoundRadius))),
                  ),
                  child: const Text("取消投票",
                      style: TextStyle(fontSize: buttonTextSize)),
                ),
              ),
            ),
          const SizedBox(width: 7),
          Expanded(
              child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: DualImageVoteWidget.buttonVerticalMargin),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(
                              DualImageVoteWidget.outerBorderRoundRadius)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.vote.userVoteRecordList != null)
                        if (widget.vote.userVoteRecordList![0] == 2)
                          Icon(Icons.check_circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.38),
                              size: buttonTextSize),
                      const SizedBox(width: 10),
                      Text(widget.vote.voteDetailList[1].content,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.38),
                              fontSize: buttonTextSize)),
                    ],
                  )))
        ])
      ],
    );
  }

  Widget voteImageWidget() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Expanded(
          flex: 1,
          child: ClipRRect(
              borderRadius: const BorderRadius.all(
                  Radius.circular(DualImageVoteWidget.outerBorderRoundRadius)),
              child: Image.network(
                  widget.vote.voteDetailList[0].attachment.toString(),
                  fit: BoxFit.fill))),
      const SizedBox(width: 10),
      Expanded(
          flex: 1,
          child: ClipRRect(
              borderRadius: const BorderRadius.all(
                  Radius.circular(DualImageVoteWidget.outerBorderRoundRadius)),
              child: Image.network(
                  widget.vote.voteDetailList[1].attachment.toString(),
                  fit: BoxFit.fill)))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        // TODO: add ink effect
        elevation: 6,
        margin: const EdgeInsets.all(7),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(children: [
              VoteInfoWidget(vote: vote),
              const SizedBox(height: 10),
              voteImageWidget(),
              const SizedBox(height: 10),
              if (vote.canVote == true)
                canVoteButtonWidget()
              else
                cannotVoteButtonWidget()
            ])));
  }
}
