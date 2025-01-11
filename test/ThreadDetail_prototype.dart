import 'package:flutter/material.dart';
import 'package:bluefish/models/vote.dart';
import 'package:bluefish/widgets/vote_widget.dart';
import 'package:bluefish/userdata/theme_settings.dart';

void main() {
  launchApp();
}

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  Vote vote = Vote();
  vote.voteID = 11124946;
  await vote.refresh();
  // var co = waterbuild.mainFloor.contentHTML;
  // var doc = parse(co).body;
  // var l1 = 0;
  // for (var nod in doc!.nodes) {
  //   if (nod.attributes["class"] == "slate-video") l1++;
  // }
  // var a = waterbuild.mainFloor.rawContent;
  // var re = jsonDecode(a);
  // var ht = re["htmlV3"];
  // var res = parse(ht).body!.nodes;

  runApp(
    MaterialApp(
      // TODO: theme: userThemeData,
      theme: initUserThemeSettings(),
      home: Scaffold(
        body: SafeArea(
          child: DualImageVoteWidget(vote: vote),
        ),
      ),
    ),
  );
}
