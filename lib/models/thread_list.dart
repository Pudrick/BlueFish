import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:bluefish/models/single_thread_title.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart';
import 'package:bluefish/userdata/user_settings.dart';
import 'package:bluefish/models/internal_settings.dart';

/// position 0 just for index offset.
/// as tab_type, 2 for newest reply, 1 for newest publish, 4 for 24h rank, 3 for essences
enum SortType { sortType0Position, newestPublish, newestReply, essences, rank }

class ThreadTitleList extends ChangeNotifier {
  List<SingleThreadTitle> threadTitleList = List.empty(growable: true);
  final HttpwithUA _client = HttpwithUA();

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
      "https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/getTopicThreads?",
    );
  }

  Uri pinnedURL() {
    return Uri.parse(
      "https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/$topicID",
    );
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

  Future<List<SingleThreadTitle>> getPinnedThreads() async {
    var jsonPinned = await _client.get(pinnedURL());
    var mappedThreads = jsonDecode(jsonPinned.body);
    var pinnedList = mappedThreads["data"]["topicTopList"] as List? ?? [];

    return [
      for (final thread in pinnedList)
        SingleThreadTitle.fromJson({
          ...Map<String, dynamic>.from(thread as Map),
          'isPinned': true,
        }),
    ];
  }

  Future<List<SingleThreadTitle>> getNormalThreads() async {
    var url = generateURL();
    var jsonThreads = await _client.get(url);
    var mappedthreads = jsonDecode(jsonThreads.body);
    var threadList = mappedthreads["data"]["list"] as List? ?? [];
    final normalThreads = <SingleThreadTitle>[];

    for (var thread in threadList) {
      final newThread = SingleThreadTitle.fromJson(
        Map<String, dynamic>.from(thread as Map),
      );
      if (zoneID != 253 && newThread.zoneId != 253) {
        normalThreads.add(newThread);
      } else if (zoneID == 253 && newThread.zoneId == 253) {
        normalThreads.add(newThread);
      }
    }

    return normalThreads;
  }

  Future<void> refresh() async {
    isRefreshing = true;
    notifyListeners();

    try {
      final pinnedThreads = await getPinnedThreads();
      final normalThreads = await getNormalThreads();
      threadTitleList
        ..clear()
        ..addAll(pinnedThreads)
        ..addAll(normalThreads);
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }
}
