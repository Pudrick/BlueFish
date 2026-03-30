import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:bluefish/models/single_thread_title.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart';
import 'package:bluefish/userdata/user_settings.dart';
import 'package:bluefish/models/internal_settings.dart';

/// position 0 just for index offset.
/// as tab_type, 2 for newest reply, 1 for newest publish, 4 for 24h rank, 3 for essences
enum SortType { sortType0Position, newestPublish, newestReply, essences, rank }

enum ThreadListBoard { main, theater, essence }

class ThreadTitleList extends ChangeNotifier {
  List<SingleThreadTitle> threadTitleList = List.empty(growable: true);
  final HttpwithUA _client = HttpwithUA();

  int topicID = mainTopicID;
  int fid = 4875;

  final Map<int, SortType> _zoneSortMemory = {
    mainZoneID: SortType.newestReply,
    theaterZoneID: SortType.newestReply,
  };

  ThreadListBoard _currentBoard = ThreadListBoard.main;
  ThreadListBoard get currentBoard => _currentBoard;

  bool get showSortSwitcher => _currentBoard != ThreadListBoard.essence;

  int get currentZoneID => _zoneIdForBoard(_currentBoard);

  String get currentBoardLabel {
    switch (_currentBoard) {
      case ThreadListBoard.main:
        return '主版';
      case ThreadListBoard.theater:
        return '剧场';
      case ThreadListBoard.essence:
        return '精华';
    }
  }

  SortType get currentSortType {
    if (!showSortSwitcher) {
      return SortType.essences;
    }
    return _zoneSortMemory[currentZoneID] ?? SortType.newestReply;
  }

  int _zoneIdForBoard(ThreadListBoard board) {
    switch (board) {
      case ThreadListBoard.main:
      case ThreadListBoard.essence:
        return mainZoneID;
      case ThreadListBoard.theater:
        return theaterZoneID;
    }
  }

  void setBoard(ThreadListBoard newBoard) {
    if (_currentBoard == newBoard) {
      return;
    }
    _currentBoard = newBoard;
    page = 1;
    refresh();
  }

  /// 0 => main topic
  void setZoneID(int newZone) {
    if (newZone == theaterZoneID) {
      setBoard(ThreadListBoard.theater);
      return;
    }
    setBoard(ThreadListBoard.main);
  }

  int page = 1;

  bool isRefreshing = false;

  void setSortType(SortType newType) {
    if (!showSortSwitcher) {
      return;
    }
    if (newType != SortType.newestPublish && newType != SortType.newestReply) {
      return;
    }
    if (_zoneSortMemory[currentZoneID] == newType) {
      return;
    }
    _zoneSortMemory[currentZoneID] = newType;
    page = 1;
    refresh();
  }

  // ThreadTitleList();
  ThreadTitleList.defaultList() {
    refresh();
  }

  ThreadTitleList(
    this.topicID,
    int initialZoneID,
    this.page,
    SortType initialSortType,
  ) : assert(initialSortType.index != 0) {
    _currentBoard = initialZoneID == theaterZoneID
        ? ThreadListBoard.theater
        : ThreadListBoard.main;
    if (initialSortType == SortType.newestPublish ||
        initialSortType == SortType.newestReply) {
      _zoneSortMemory[currentZoneID] = initialSortType;
    }
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
    String baseurl = baseURL().toString();
    int tabType = currentSortType.index;
    var res = "$baseurl&topic_id=$topicID&tab_type=$tabType";
    if (_currentBoard == ThreadListBoard.essence ||
        currentZoneID == mainZoneID) {
      return Uri.parse(res);
    }
    return Uri.parse("$res&zoneId=$currentZoneID");
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
      if (_currentBoard == ThreadListBoard.essence) {
        normalThreads.add(newThread);
      } else if (currentZoneID != theaterZoneID &&
          newThread.zoneId != theaterZoneID) {
        normalThreads.add(newThread);
      } else if (currentZoneID == theaterZoneID &&
          newThread.zoneId == theaterZoneID) {
        normalThreads.add(newThread);
      }
    }

    return normalThreads;
  }

  Future<void> refresh() async {
    isRefreshing = true;
    notifyListeners();

    try {
      final pinnedThreads = _currentBoard == ThreadListBoard.essence
          ? <SingleThreadTitle>[]
          : await getPinnedThreads();
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
