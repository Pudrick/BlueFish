import 'dart:async';
import 'dart:convert';

import 'package:bluefish/models/single_floor.dart';
import 'package:bluefish/models/thread_main.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import './http_with_ua.dart';

Future<Map> getThreadInfoMapFromTid(dynamic tid) async {
  if (tid is int) tid = tid.toString();
  Uri threadURL = Uri.parse("https://bbs.hupu.com/$tid.html");
  var response = await HttpwithUA().get(threadURL);
  if (response.statusCode == 200) {
    var threadHTML = parse(response.body);
    return getThreadInfoMapFromHttp(threadHTML);
  } else {
    throw TimeoutException("Failed to get http response.");
  }
}

Map getThreadInfoMapFromHttp(Document rawHttp) {
  var threadJsonStr = rawHttp.getElementById("__NEXT_DATA__")!.innerHtml;
  var threadObject = jsonDecode(threadJsonStr);
  var detailInfo = threadObject["props"]["pageProps"]["detail"];
  return {
    "thread": detailInfo["thread"],
    "lights": detailInfo["lights"],
    "replies": detailInfo["replies"]
  };
}

ThreadMain getMainFloor(Map threadInfoMap) {
  Author OP = Author(threadInfoMap["author"]);
}
// SingleFloor getMainFloor(Document threadHTML) {
  // TODO: need to refactor all.
  // Author OP = Author();
  // OP.avatarURL = getOPAvatarUri(threadHTML);
  // var infoMap = getOPotherInfoMap(threadHTML);
  // OP.authorName = infoMap["ID"];
  // OP.isOP = true;
  // OP.profileURL = Uri.parse(infoMap["userProfileStr"]);
  // SingleFloor mainFloor = SingleFloor();
  // mainFloor.author = OP;
  // mainFloor.postDateTime = infoMap["datetime"];
  // mainFloor.postLocation = infoMap["location"];
  // mainFloor.contentHTML = getMainContentHTML(threadHTML);
  // return mainFloor;
// }
