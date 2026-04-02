import 'package:bluefish/models/private_message_list.dart';
import 'package:bluefish/services/private_message_list_service.dart';
import 'package:flutter/foundation.dart';

class PrivateMessageListViewModel extends ChangeNotifier {
  static const int defaultPageSize = 10;

  final PrivateMessageListService _service;
  final int pageSize;

  bool _unreadOnly;

  PrivateMessageListViewModel({
    PrivateMessageListService? service,
    this.pageSize = defaultPageSize,
    bool unreadOnly = false,
  }) : _service = service ?? PrivateMessageListService(),
       _unreadOnly = unreadOnly;

  PrivateMessageList? _data;
  PrivateMessageList? get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;
  bool get hasNextPage => !_isLastPage;

  bool get unreadOnly => _unreadOnly;

  int _nextPage = 1;
  int get nextPage => _nextPage;

  List<PrivateMessagePeek> get messagePeeks =>
      _data?.messagePeeks ?? const <PrivateMessagePeek>[];

  PrivateMessageListPageInfo? get pageInfo => _data?.pageInfo;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    await _fetchPage(pageNum: 1, reset: true);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLastPage) return;
    await _fetchPage(pageNum: _nextPage, reset: false);
  }

  Future<void> setUnreadOnly(bool unreadOnly) async {
    if (_unreadOnly == unreadOnly) return;

    _unreadOnly = unreadOnly;
    notifyListeners();
    await refresh();
  }

  Future<void> _fetchPage({required int pageNum, required bool reset}) async {
    _isLoading = true;
    if (reset) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final result = await _service.getList(
        unreadOnly: _unreadOnly,
        pageNum: pageNum,
        pageSize: pageSize,
      );

      final mergedMessagePeeks = reset
          ? result.messagePeeks
          : _mergeMessagePeeks(messagePeeks, result.messagePeeks);

      _data = PrivateMessageList(
        pageInfo: result.pageInfo,
        messagePeeks: mergedMessagePeeks,
      );

      _nextPage = result.pageInfo.nextPage > result.pageInfo.pageNum
          ? result.pageInfo.nextPage
          : result.pageInfo.pageNum + 1;
      _isLastPage =
          result.pageInfo.isEnd || result.messagePeeks.length < pageSize;
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = reset ? '消息列表加载失败，请稍后重试。' : '加载更多失败，请稍后重试。';
      debugPrint('Failed to fetch private message list: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PrivateMessagePeek> _mergeMessagePeeks(
    List<PrivateMessagePeek> currentPeeks,
    List<PrivateMessagePeek> incomingPeeks,
  ) {
    final seenSids = <int>{};
    final mergedPeeks = <PrivateMessagePeek>[];

    for (final peek in [...currentPeeks, ...incomingPeeks]) {
      if (seenSids.add(peek.sid)) {
        mergedPeeks.add(peek);
      }
    }

    return mergedPeeks;
  }
}
