import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/temp/tstwgt.dart';
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
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              mainFloor.author.avatarURL.toString(),
                              scale: 4,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(mainFloor.author.name,
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    if (mainFloor.author.adminsInfo != null)
                                      Text(
                                        mainFloor.author.adminsInfo!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal),
                                        overflow: TextOverflow.visible,
                                      )
                                  ],
                                ),
                                Text(
                                    "${DateFormat("yyyy-MM-dd HH:mm:ss").format(mainFloor.postDateTime)} (${mainFloor.postDateTimeReadable})"),
                              ]),
                          Expanded(
                            child: Container(), // just for position holding
                          ),
                          Container(
                              alignment: Alignment.center,
                              child: switch (mainFloor.client) {
                                "ANDROID" => const Icon(Icons.android),
                                "IPHONE" => const Icon(Icons.apple),
                                "PC" =>
                                  const Icon(Icons.desktop_windows_outlined),
                                String() => Container(),
                              })
                        ],
                      ),
                      const Divider(),
                      Text(mainFloor.contentHTML),
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
