import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:bluefish/models/single_reply_floor.dart';
import '../models/author.dart';
import 'package:bluefish/models/thread_main.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import './http_with_ua.dart';

Future<Map> getThreadInfoMapFromTid(dynamic tid, int page) async {
  if (tid is int) tid = tid.toString();
  Uri threadURL = Uri.parse("https://bbs.hupu.com/$tid-$page.html");
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

List<SingleReplyFloor> getReplyListFromWholeMap(
    String requireType, Map threadInfoMap) {
  List<SingleReplyFloor> res = List.empty(growable: true);
  late List repliesMap;
  if (requireType == "lights") {
    repliesMap = threadInfoMap[requireType];
  } else if (requireType == "replies") {
    repliesMap = threadInfoMap["replies"]["list"];
  }
  for (var lightReplyMap in repliesMap) {
    var reply = SingleReplyFloor.fromReplyMap(lightReplyMap);
    res.add(reply);
  }
  return res;
}

ThreadMain getMainFloorFromWholeMap(Map threadInfoMap) {
  return ThreadMain(threadInfoMap["thread"]);
}

int getTotalRepliesNumFromWholeMap(Map threadInfoMap) {
  return threadInfoMap["replies"]["count"];
}

// List getReplyFloorsFromWholeMap(Map threadInfoMap) {}
