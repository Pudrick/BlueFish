import 'package:bluefish/models/thread_main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../models/thread_detail.dart';

class ThreadMainFloorWidget extends StatelessWidget {
  bool hasVote;
  ThreadMain mainFloor;
  ThreadMainFloorWidget(
      {super.key, this.hasVote = false, required this.mainFloor});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return SafeArea(
      child: ListView(children: [
        Container(
          constraints: const BoxConstraints(minHeight: 40),
          child: Card(
            // maybe enablet this will have some performance cost
            // according to the document
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {},
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(
                    text: mainFloor.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              // maybe default color is enlugh.
              // splashColor: theme.colorScheme.secondary,
            ),
          ),
        ),
        Container(
          height: 500,
          child: Card(
            // maybe enablet this will have some performance cost
            // according to the document
            clipBehavior: Clip.hardEdge,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                splashFactory: InkRipple.splashFactory,
                child: Container(
                  margin: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              mainFloor.author.avatarURL.toString(),
                              scale: 4,
                            ),
                          ),
                          Column(children: [
                            Text.rich(TextSpan(
                                text: mainFloor.author.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            Text(
                                "${DateFormat("yyyy-MM-dd HH:mm:ss").format(mainFloor.postDateTime)} (${mainFloor.postDateTimeReadable})"),
                          ])
                        ],
                      )
                    ],
                  ),
                ),
                // maybe default color is enlugh.
                // splashColor: theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
