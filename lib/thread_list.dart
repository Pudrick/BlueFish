import 'dart:convert';

import 'single_thread_title.dart';
import 'package:http/http.dart' as http;

class ThreadTitleList {
  late List<SingleThreadTitle> threadTitleList = List.empty(growable: true);

  int topicID = 788;
  int fid = 4875;

  /// 0 => main topic
  int zoneID = 0;
  int page = 1;
  String appVersion = "8.0.68";

  /// same as tab_type, 2 for newest repy, 1 for newest publish, 4 for 24h rank, 3 for essenses
  int pickMethod = 2;

  // ThreadTitleList();
  ThreadTitleList.defaultList();
  ThreadTitleList(this.topicID, this.zoneID, this.page, this.pickMethod);

  Uri baseURL() {
    return Uri.parse(
        "https://bbs.mobileapi.hupu.com/1/$appVersion/topics/getTopicThreads?");
  }

  Uri pinnedURL() {
    return Uri.parse(
        "https://bbs.mobileapi.hupu.com/1/$appVersion/topics/$topicID");
  }

  Uri generateURL() {
    String baseurl = baseURL().toString();
    var res = "$baseurl&topic_id=$topicID&tab_type=$pickMethod";
    if (zoneID == 0) {
      return Uri.parse(res);
    }
    return Uri.parse("$res&zoneId=$zoneID");
  }

  void toNextPage() {
    page++;
  }

  Future<void> getPinnedThreads() async {
    var jsonPinned = await http.get(pinnedURL());
    var mappedThreads = jsonDecode(jsonPinned.body);
    var pinnedList = mappedThreads["data"]["topicTopList"];
    for (var Thread in pinnedList) {
      SingleThreadTitle pinThead = SingleThreadTitle.fromJson(Thread);
      pinThead.isPinned = true;
      threadTitleList.add(pinThead);
    }
  }

  Future<void> getNormalThreads() async {
    var URL = generateURL();
    var jsonThreads = await http.get(URL);
    var mappedthreads = jsonDecode(jsonThreads.body);
    var threadList = mappedthreads["data"]["list"];
    for (var Thread in threadList) {
      SingleThreadTitle newThread = SingleThreadTitle.fromJson(Thread);
      threadTitleList.add(newThread);
    }
  }

  Future<void> refresh() async {
    await getPinnedThreads();
    await getNormalThreads();
  }
}
