import 'package:bluefish/models/internal_settings.dart';
import 'package:bluefish/models/thread/single_thread_title.dart';
import 'package:bluefish/models/thread/thread_list.dart';
import 'package:bluefish/services/thread/thread_list_service.dart';
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

  final Map<ThreadListBoard, int> _boardPaginationCurrentPages = {
    ThreadListBoard.main: 1,
    ThreadListBoard.theater: 1,
    ThreadListBoard.essence: 1,
  };

  final Map<ThreadListBoard, int> _boardPaginationTotalPages = {
    ThreadListBoard.main: 1,
    ThreadListBoard.theater: 1,
    ThreadListBoard.essence: 1,
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

  bool hasNextPage = false;

  bool isRefreshing = false;

  double boardScrollOffset(ThreadListBoard board) {
    return _boardScrollOffsets[board] ?? 0;
  }

  void saveBoardScrollOffset(ThreadListBoard board, double offset) {
    _boardScrollOffsets[board] = offset < 0 ? 0 : offset;
  }

  int boardPaginationCurrentPage(ThreadListBoard board) {
    return _boardPaginationCurrentPages[board] ?? 1;
  }

  int boardPaginationTotalPages(ThreadListBoard board) {
    return _boardPaginationTotalPages[board] ?? 1;
  }

  int get currentBoardPaginationCurrentPage {
    return boardPaginationCurrentPage(_currentBoard);
  }

  int get currentBoardPaginationTotalPages {
    final int currentPage = boardPaginationCurrentPage(_currentBoard);
    final int totalPages = boardPaginationTotalPages(_currentBoard);
    return totalPages < currentPage ? currentPage : totalPages;
  }

  void setBoardPaginationPlaceholder(
    ThreadListBoard board, {
    int? currentPage,
    int? totalPages,
  }) {
    // TODO: Replace this placeholder updater after real pagination API is wired.
    bool hasChanged = false;

    if (currentPage != null) {
      final int normalizedPage = currentPage < 1 ? 1 : currentPage;
      if (_boardPaginationCurrentPages[board] != normalizedPage) {
        _boardPaginationCurrentPages[board] = normalizedPage;
        hasChanged = true;
      }
    }

    if (totalPages != null) {
      final int normalizedTotalPages = totalPages < 1 ? 1 : totalPages;
      if (_boardPaginationTotalPages[board] != normalizedTotalPages) {
        _boardPaginationTotalPages[board] = normalizedTotalPages;
        hasChanged = true;
      }
    }

    if (hasChanged) {
      notifyListeners();
    }
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
    final int normalizedInitialPage = page < 1 ? 1 : page;
    page = normalizedInitialPage;
    _boardPaginationCurrentPages[_currentBoard] = normalizedInitialPage;
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
    page = boardPaginationCurrentPage(newBoard);
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
    _boardPaginationCurrentPages[_currentBoard] = 1;
    _boardPaginationTotalPages[_currentBoard] = 1;
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
    final int? zoneID =
        (_currentBoard == ThreadListBoard.essence ||
            currentZoneID == mainZoneID)
        ? null
        : currentZoneID;
    final int requestedPage = boardPaginationCurrentPage(_currentBoard);

    return _service.threadListUrl(
      topicID: topicID,
      tabType: tabType,
      zoneID: zoneID,
      page: requestedPage,
    );
  }

  Future<void> toPage(int targetPage) async {
    if (isRefreshing) {
      return;
    }

    // TODO: Confirm API-allowed page lower/upper bounds and update this clamp.
    final int normalizedPage = targetPage < 1 ? 1 : targetPage;
    final int currentPage = boardPaginationCurrentPage(_currentBoard);
    if (normalizedPage == currentPage) {
      return;
    }

    _boardPaginationCurrentPages[_currentBoard] = normalizedPage;
    page = normalizedPage;
    await refresh();
  }

  Future<void> toPrevPage() async {
    if (boardPaginationCurrentPage(_currentBoard) <= 1) {
      return;
    }
    await toPage(boardPaginationCurrentPage(_currentBoard) - 1);
  }

  Future<void> toNextPage() async {
    if (!hasNextPage) {
      return;
    }
    await toPage(boardPaginationCurrentPage(_currentBoard) + 1);
  }

  Future<List<SingleThreadTitle>> getPinnedThreads() async {
    return _service.getPinnedThreads(topicID: topicID);
  }

  Future<List<SingleThreadTitle>> getNormalThreads() async {
    final (:threads, :hasNextPage) = await _service.getNormalThreads(
      url: generateURL(),
    );
    this.hasNextPage = hasNextPage;
    final normalThreads = <SingleThreadTitle>[];

    for (final newThread in threads) {
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
