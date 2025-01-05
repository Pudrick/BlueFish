import 'package:bluefish/widgets/thread_main_widget.dart';
import 'package:flutter/material.dart';
import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/userdata/theme_settings.dart';

void main() {
  launchApp();
}

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  var waterbuild = ThreadDetail(626582908);
  await waterbuild.refresh();
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

      home: SafeArea(
          child: ThreadMainFloorWidget(mainFloor: waterbuild.mainFloor)),
    ),
  );
}
