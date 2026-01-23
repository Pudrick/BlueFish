import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/widgets/author_info_widget.dart';
import 'package:flutter/material.dart';

// html widget package.
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:bluefish/widgets/htmlWidget_with_vote.dart';

class ThreadTitleWidget extends StatelessWidget {
  final String title;

  const ThreadTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      child: Card(
        // color: Theme.of(context).colorScheme.surfaceContainerHighest,
        // maybe enablet this will have some performance cost
        // according to the document
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            alignment: Alignment.centerLeft,
            child: Text.rich(TextSpan(
                text: title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          // maybe default color is enlugh.
          // splashColor: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

class ThreadMainFloorWidget extends StatelessWidget {
  final bool hasVote;
  final ThreadMain mainFloor;
  const ThreadMainFloorWidget(
      {super.key, this.hasVote = false, required this.mainFloor});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Column(children: [
      Card(
        // maybe enablet this will have some performance cost
        // according to the document
        clipBehavior: Clip.hardEdge,
        child: Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
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
    ]);
  }
}

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyHeaderDelegate({required this.child, this.height = 60.0});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
