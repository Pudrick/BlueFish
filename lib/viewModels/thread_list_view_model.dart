import 'package:bluefish/models/internal_settings.dart';
import 'package:bluefish/models/single_thread_title.dart';
import 'package:bluefish/models/thread_list.dart';
import 'package:bluefish/services/thread_list_service.dart';
import 'package:flutter/material.dart';

class ThreadListViewModel extends ChangeNotifier {
  List<SingleThreadTitle> threadTitleList = List.empty(growable: true);

  final ThreadListService _service;

  final int topicID;
  int fid;

  final Map<int, SortType> _zoneSortMemory = {
    mainZoneID: SortType.newestReply,
    theaterZoneID: SortType.newestReply,
  };

  final Map<ThreadListBoard, double> _boardScrollOffsets = {
    ThreadListBoard.main: 0,
    ThreadListBoard.theater: 0,
    ThreadListBoard.essence: 0,
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

  int page;

  bool isRefreshing = false;

  double boardScrollOffset(ThreadListBoard board) {
    return _boardScrollOffsets[board] ?? 0;
  }

  void saveBoardScrollOffset(ThreadListBoard board, double offset) {
    _boardScrollOffsets[board] = offset < 0 ? 0 : offset;
  }

  ThreadListViewModel.defaultList({ThreadListService? service})
    : _service = service ?? ThreadListService(),
      topicID = mainTopicID,
      fid = 4875,
      page = 1 {
    refresh();
  }

  ThreadListViewModel(
    this.topicID,
    int initialZoneID,
    this.page,
    SortType initialSortType, {
    ThreadListService? service,
    this.fid = 4875,
  }) : assert(initialSortType.index != 0),
       _service = service ?? ThreadListService() {
    _currentBoard = initialZoneID == theaterZoneID
        ? ThreadListBoard.theater
        : ThreadListBoard.main;
    if (initialSortType == SortType.newestPublish ||
        initialSortType == SortType.newestReply) {
      _zoneSortMemory[currentZoneID] = initialSortType;
    }
    refresh();
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

  Uri baseURL() {
    return _service.topicThreadsBaseUrl();
  }

  Uri pinnedURL() {
    return _service.pinnedThreadsUrl(topicID: topicID);
  }

  Uri generateURL() {
    final int tabType = currentSortType.index;
    final int? zoneID = (_currentBoard == ThreadListBoard.essence ||
            currentZoneID == mainZoneID)
        ? null
        : currentZoneID;

    return _service.threadListUrl(
      topicID: topicID,
      tabType: tabType,
      zoneID: zoneID,
    );
  }

  void toNextPage() {
    page++;
    notifyListeners();
  }

  Future<List<SingleThreadTitle>> getPinnedThreads() async {
    return _service.getPinnedThreads(topicID: topicID);
  }

  Future<List<SingleThreadTitle>> getNormalThreads() async {
    final threadList = await _service.getNormalThreads(url: generateURL());
    final normalThreads = <SingleThreadTitle>[];

    for (final newThread in threadList) {
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
