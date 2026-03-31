import 'dart:collection';

import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/utils/get_thread_info.dart';
import 'package:bluefish/utils/result.dart';

/// Service for fetching thread detail data with LRU caching.
class ThreadDetailService {
  /// Max pages to cache per thread.
  static const int _maxCachedPagesPerThread = 5;

  /// Cache structure: tid -> LinkedHashMap<page, ThreadDetail>
  /// LinkedHashMap maintains insertion order for LRU eviction.
  final Map<String, LinkedHashMap<int, ThreadDetail>> _pageCache = {};

  /// Cached main floor per thread (doesn't change between pages).
  final Map<String, ThreadMain> _mainFloorCache = {};

  ThreadDetailService();

  /// Fetches thread detail for given tid and page.
  ///
  /// Uses cache unless [forceRefresh] is true.
  Future<Result<ThreadDetail>> getThreadDetail(
    String tid,
    int page, {
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forced refresh)
    if (!forceRefresh) {
      final cached = _getFromCache(tid, page);
      if (cached != null) {
        return Success(cached);
      }
    }

    // Fetch from network
    try {
      final data = await _fetchFromNetwork(tid, page);
      _addToCache(tid, page, data);
      return Success(data);
    } on Exception catch (e) {
      return Failure('加载帖子失败: ${e.toString()}', e);
    } catch (e) {
      return Failure('未知错误: $e');
    }
  }

  /// Clears all cached pages for a specific thread.
  void clearCache(String tid) {
    _pageCache.remove(tid);
    _mainFloorCache.remove(tid);
  }

  /// Clears all caches.
  void clearAllCache() {
    _pageCache.clear();
    _mainFloorCache.clear();
  }

  /// Updates a specific cached page (e.g., after like/favorite action).
  void updateCachedData(
    String tid,
    int page,
    ThreadDetail Function(ThreadDetail) updater,
  ) {
    final threadCache = _pageCache[tid];
    if (threadCache != null && threadCache.containsKey(page)) {
      threadCache[page] = updater(threadCache[page]!);
    }
  }

  ThreadDetail? _getFromCache(String tid, int page) {
    final threadCache = _pageCache[tid];
    if (threadCache == null || !threadCache.containsKey(page)) {
      return null;
    }

    // Move to end for LRU (most recently accessed)
    final data = threadCache.remove(page)!;
    threadCache[page] = data;

    return data;
  }

  void _addToCache(String tid, int page, ThreadDetail data) {
    _pageCache[tid] ??= LinkedHashMap<int, ThreadDetail>();
    final threadCache = _pageCache[tid]!;

    // Evict oldest if at capacity
    while (threadCache.length >= _maxCachedPagesPerThread) {
      threadCache.remove(threadCache.keys.first);
    }

    threadCache[page] = data;

    // Cache main floor separately (shared across pages)
    _mainFloorCache[tid] = data.mainFloor;
  }

  Future<ThreadDetail> _fetchFromNetwork(String tid, int page) async {
    final threadInfo = await getThreadInfoMapFromTid(tid, page);

    // Use cached main floor if available and not first page
    ThreadMain mainFloor;
    if (page > 1 && _mainFloorCache.containsKey(tid)) {
      mainFloor = _mainFloorCache[tid]!;
    } else {
      mainFloor = ThreadMain(threadInfo["thread"]);
    }

    final int totalRepliesNum = threadInfo["replies"]["count"];
    final lightedReplies = getReplyListFromWholeMap("lights", threadInfo);
    final replies = getReplyListFromWholeMap("replies", threadInfo);

    return ThreadDetail(
      tid: tid,
      currentPage: page,
      totalRepliesNum: totalRepliesNum,
      repliesPerPage: 20,
      mainFloor: mainFloor,
      lightedReplies: lightedReplies,
      replies: replies,
    );
  }
}
