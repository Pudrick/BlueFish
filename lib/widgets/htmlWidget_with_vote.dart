import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:bluefish/widgets/VoteWidget/vote_widget.dart';

Widget HtmlWidgetWithVote(String htmlStr, {TextStyle? textStyle}) {
  return HtmlWidget(
    htmlStr,
    textStyle: textStyle,
    customWidgetBuilder: (element) {
      if (element.localName == "span" &&
          element.attributes["data-type"] == "vote") {
        final String voteID = element.attributes["data-vote-id"]!;
        return VoteWidget(voteID: int.parse(voteID));
      }
      return null;
    },
  );
}
