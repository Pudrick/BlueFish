import 'dart:convert';

import 'package:flutter/material.dart';

import 'single_thread_title.dart';
import '../userdata/user_settings.dart';
import 'package:http/http.dart' as http;
import 'internal_settings.dart';

/// position 0 just for index offset.
/// as tab_type, 2 for newest reply, 1 for newest publish, 4 for 24h rank, 3 for essences
enum SortType { sortType0Position, newestPublish, newestReply, essences, rank }

class ThreadTitleList extends ChangeNotifier {
  List<SingleThreadTitle> threadTitleList = List.empty(growable: true);

  int topicID = mainTopicID;
  int fid = 4875;

  /// 0 => main topic
  int zoneID = mainZoneID;
  void setZoneID(int newZone) {
    zoneID = newZone;
    refresh();
  }

  int page = 1;

  bool isRefreshing = false;

  SortType sortType = SortType.newestReply;

  void setSortType(SortType newType) {
    sortType = newType;
    refresh();
  }

  // ThreadTitleList();
  ThreadTitleList.defaultList() {
    refresh();
  }
  ThreadTitleList(this.topicID, this.zoneID, this.page, this.sortType)
      : assert(sortType.index != 0) {
    refresh();
  }

  //just for main page thread sort refresh

  Uri baseURL() {
    return Uri.parse(
        "https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/getTopicThreads?");
  }

  Uri pinnedURL() {
    return Uri.parse(
        "https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/$topicID");
  }

  Uri generateURL() {
    assert(sortType.index != 0);
    String baseurl = baseURL().toString();
    int tabType = sortType.index;
    var res = "$baseurl&topic_id=$topicID&tab_type=$tabType";
    if (zoneID == 0) {
      return Uri.parse(res);
    }
    return Uri.parse("$res&zoneId=$zoneID");
  }

  void toNextPage() {
    page++;
    notifyListeners();
  }

  Future<void> getPinnedThreads() async {
    var jsonPinned = await http.get(pinnedURL());
    var mappedThreads = jsonDecode(jsonPinned.body);
    var pinnedList = mappedThreads["data"]["topicTopList"];
    for (var thread in pinnedList) {
      SingleThreadTitle pinThead = SingleThreadTitle.fromJson(thread);
      pinThead.isPinned = true;
      threadTitleList.add(pinThead);
    }
  }

  Future<void> getNormalThreads() async {
    var URL = generateURL();
    var jsonThreads = await http.get(URL);
    var mappedthreads = jsonDecode(jsonThreads.body);
    var threadList = mappedthreads["data"]["list"];
    for (var thread in threadList) {
      SingleThreadTitle newThread = SingleThreadTitle.fromJson(thread);
      if (zoneID != 253 && newThread.zoneId != 253) {
        threadTitleList.add(newThread);
      } else if (zoneID == 253 && newThread.zoneId == 253) {
        threadTitleList.add(newThread);
      }
    }
  }

  void refresh() async {
    isRefreshing = true;
    notifyListeners();
    threadTitleList.clear();
    await getPinnedThreads();
    await getNormalThreads();
    isRefreshing = false;
    notifyListeners();
  }
}
