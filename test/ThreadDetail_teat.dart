import 'package:bluefish/widgets/thread_main_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bluefish/models/thread_detail.dart';

void main() {
  launchApp();
}

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  var waterbuild = ThreadDetail(629403933, 0);
  await waterbuild.refresh();

  runApp(
    MaterialApp(
      // TODO: theme: userThemeData,

      home: SafeArea(
          child: ThreadMainFloorWidget(mainFloor: waterbuild.mainFloor)),
    ),
  );
}
