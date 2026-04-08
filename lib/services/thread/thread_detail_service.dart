import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:bluefish/models/author_identity.dart';
import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/models/thread/thread_main.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/utils/result.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

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

  static Uri buildThreadUri({
    required String tid,
    required int page,
    AuthorIdentity? authorIdentity,
    String? authorEuid,
    String? authorPuid,
  }) {
    final normalizedTid = tid.trim();
    final resolvedAuthorIdentity = _resolveAuthorIdentity(
      authorIdentity: authorIdentity,
      authorEuid: authorEuid,
      authorPuid: authorPuid,
    );
    final baseSlug = resolvedAuthorIdentity == null
        ? normalizedTid
        : '${normalizedTid}_${resolvedAuthorIdentity.id}';
    final pageSlug = page <= 1 ? baseSlug : '$baseSlug-$page';
    return Uri.parse('https://bbs.hupu.com/$pageSlug.html');
  }

  /// Fetches thread detail for given tid and page.
  ///
  /// Uses cache unless [forceRefresh] is true.
  Future<Result<ThreadDetail>> getThreadDetail(
    String tid,
    int page, {
    AuthorIdentity? authorIdentity,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forced refresh)
    if (!forceRefresh) {
      final cached = _getFromCache(tid, page, authorIdentity: authorIdentity);
      if (cached != null) {
        return Success(cached);
      }
    }

    // Fetch from network
    try {
      final data = await _fetchFromNetwork(
        tid,
        page,
        authorIdentity: authorIdentity,
      );
      _addToCache(tid, page, data, authorIdentity: authorIdentity);
      return Success(data);
    } on Exception catch (e) {
      return Failure('加载帖子失败: ${e.toString()}', e);
    } catch (e) {
      return Failure('未知错误: $e');
    }
  }

  /// Clears all cached pages for a specific thread.
  void clearCache(String tid) {
    final normalizedTid = tid.trim();
    _pageCache.removeWhere(
      (cacheKey, value) => cacheKey.startsWith('$normalizedTid|'),
    );
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
    ThreadDetail Function(ThreadDetail) updater, {
    AuthorIdentity? authorIdentity,
  }) {
    final threadCache = _pageCache[_cacheKey(tid, authorIdentity)];
    if (threadCache != null && threadCache.containsKey(page)) {
      threadCache[page] = updater(threadCache[page]!);
    }
  }

  ThreadDetail? _getFromCache(
    String tid,
    int page, {
    AuthorIdentity? authorIdentity,
  }) {
    final threadCache = _pageCache[_cacheKey(tid, authorIdentity)];
    if (threadCache == null || !threadCache.containsKey(page)) {
      return null;
    }

    // Move to end for LRU (most recently accessed)
    final data = threadCache.remove(page)!;
    threadCache[page] = data;

    return data;
  }

  void _addToCache(
    String tid,
    int page,
    ThreadDetail data, {
    AuthorIdentity? authorIdentity,
  }) {
    final cacheKey = _cacheKey(tid, authorIdentity);
    _pageCache[cacheKey] ??= LinkedHashMap<int, ThreadDetail>();
    final threadCache = _pageCache[cacheKey]!;

    // Evict oldest if at capacity
    while (threadCache.length >= _maxCachedPagesPerThread) {
      threadCache.remove(threadCache.keys.first);
    }

    threadCache[page] = data;

    // Cache main floor separately (shared across pages)
    _mainFloorCache[tid] = data.mainFloor;
  }

  Future<ThreadDetail> _fetchFromNetwork(
    String tid,
    int page, {
    AuthorIdentity? authorIdentity,
  }) async {
    final threadInfo = await _fetchThreadInfoMap(
      tid,
      page,
      authorIdentity: authorIdentity,
    );

    // Use cached main floor if available and not first page
    ThreadMain mainFloor;
    if (page > 1 && _mainFloorCache.containsKey(tid)) {
      mainFloor = _mainFloorCache[tid]!;
    } else {
      mainFloor = ThreadMain.fromJson(
        threadInfo['thread'] as Map<String, dynamic>,
      );
    }

    final repliesInfo = threadInfo['replies'] as Map<String, dynamic>;
    final int topicId = parseInt(threadInfo['topicId']);
    final int totalRepliesNum = repliesInfo['count'] as int;
    final lightedReplies = _parseReplyList('lights', threadInfo);
    final replies = _parseReplyList('replies', threadInfo);

    return ThreadDetail(
      tid: tid,
      topicId: topicId,
      currentPage: page,
      totalRepliesNum: totalRepliesNum,
      repliesPerPage: 20,
      mainFloor: mainFloor,
      lightedReplies: lightedReplies,
      replies: replies,
    );
  }

  Future<Map<String, dynamic>> _fetchThreadInfoMap(
    String tid,
    int page, {
    AuthorIdentity? authorIdentity,
  }) async {
    final threadUrl = buildThreadUri(
      tid: tid,
      page: page,
      authorIdentity: authorIdentity,
    );
    final response = await httpClient.get(threadUrl);

    if (response.statusCode != 200) {
      throw TimeoutException('Failed to get http response.');
    }

    final threadHtml = parse(response.body);
    return _extractThreadInfoMap(threadHtml);
  }

  Map<String, dynamic> _extractThreadInfoMap(Document rawHttp) {
    final threadJsonStr = rawHttp.getElementById('__NEXT_DATA__')!.innerHtml;
    final threadObject = jsonDecode(threadJsonStr) as Map<String, dynamic>;
    final props = threadObject['props'] as Map<String, dynamic>;
    final pageProps = props['pageProps'] as Map<String, dynamic>;
    final detailInfo = pageProps['detail'] as Map<String, dynamic>;

    // TODO: add collect check
    // example API:
    // https://bbs.mobileapi.hupu.com/1/8.0.30/threads/getThreadCollectStatus?tid=628217371

    final thread = Map<String, dynamic>.from(
      detailInfo['thread'] as Map<dynamic, dynamic>,
    );

    // TODO: add isrec check instead of this
    thread['isRecommended'] = detailInfo['isRecommended'];

    return {
      'thread': thread,
      'topicId': thread['topicId'],
      'lights': detailInfo['lights'],
      'replies': detailInfo['replies'],
    };
  }

  List<SingleReplyFloor> _parseReplyList(
    String requireType,
    Map<String, dynamic> threadInfoMap,
  ) {
    late final List<dynamic> repliesMap;
    if (requireType == 'lights') {
      repliesMap = threadInfoMap[requireType] as List<dynamic>;
    } else if (requireType == 'replies') {
      final replies = threadInfoMap['replies'] as Map<String, dynamic>;
      repliesMap = replies['list'] as List<dynamic>;
    } else {
      throw ArgumentError.value(requireType, 'requireType', 'Unsupported type');
    }

    return [
      for (final replyMap in repliesMap)
        SingleReplyFloor.fromJson(Map<String, dynamic>.from(replyMap as Map)),
    ];
  }

  static String _cacheKey(String tid, AuthorIdentity? authorIdentity) {
    final normalizedTid = tid.trim();
    final normalizedAuthorIdentity = authorIdentity == null
        ? ''
        : '${authorIdentity.kind.name}:${authorIdentity.id}';
    return '$normalizedTid|$normalizedAuthorIdentity';
  }

  static AuthorIdentity? _resolveAuthorIdentity({
    AuthorIdentity? authorIdentity,
    String? authorEuid,
    String? authorPuid,
  }) {
    if (authorIdentity != null) {
      return authorIdentity;
    }
    return AuthorIdentity.fromTyped(euid: authorEuid, puid: authorPuid);
  }
}
