import 'package:flutter/material.dart';
import 'package:bluefish/models/vote.dart';

void main() {
  launchApp();
}

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  Vote vote = Vote();
  vote.voteID = 11124697;
  await vote.refresh();
  print(vote.title);
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

  // runApp(
  //   MaterialApp(
  //     // TODO: theme: userThemeData,
  //     theme: initUserThemeSettings(),

  //     home: SafeArea(
  //         child: ThreadMainFloorWidget(mainFloor: waterbuild.mainFloor)),
  //   ),
  // );
}
