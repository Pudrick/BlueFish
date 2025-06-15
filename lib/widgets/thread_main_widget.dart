import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/widgets/author_info_widget.dart';
import 'package:flutter/material.dart';

// html widget package.
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:bluefish/widgets/htmlWidget_with_vote.dart';

class ThreadMainFloorWidget extends StatelessWidget {
  final bool hasVote;
  final ThreadMain mainFloor;
  const ThreadMainFloorWidget(
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
        Card(
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
                    AuthorInfoWidget(content: mainFloor),
                    const Divider(),
                    HtmlWidgetWithVote(
                      // TODO: add html parser and connect it with video parser.
                      mainFloor.contentHTML,
                      textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      // TODO: add recommend and its number
                    ),
                  ],
                ),
              ),
              // maybe default color is enlugh.
              // splashColor: theme.colorScheme.secondary,
            ),
          ),
        ),
      ]),
    );
  }
}
