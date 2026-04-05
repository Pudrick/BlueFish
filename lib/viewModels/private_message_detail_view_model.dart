import 'package:bluefish/models/private_message/private_message_detail.dart';
import 'package:bluefish/services/private_message_detail_service.dart';
import 'package:flutter/foundation.dart';

class PrivateMessageDetailViewModel extends ChangeNotifier {
  static const int defaultPageSize = 10;

  final PrivateMessageDetailService _service;
  final int puid;
  final int pageSize;
  final bool prependHistoryOnLoadMore;

  PrivateMessageDetailViewModel({
    required this.puid,
    PrivateMessageDetailService? service,
    this.pageSize = defaultPageSize,
    this.prependHistoryOnLoadMore = true,
  }) : _service = service ?? PrivateMessageDetailService();

  PrivateMessageDetail? _data;
  PrivateMessageDetail? get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;
  bool get hasNextPage => !_isLastPage;

  int _nextPage = 1;
  int get nextPage => _nextPage;

  List<SinglePrivateMessage> get messages =>
      _data?.messages ?? const <SinglePrivateMessage>[];

  PrivateMessagePageInfo? get pageInfo => _data?.pageInfo;

  bool get isSystem => _data?.isSystem ?? false;
  bool get unread => _data?.unread ?? false;
  bool get isBanned => _data?.isBanned ?? false;
  int? get loginPuid => _data?.loginPuid;
  int? get interval => _data?.interval;

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

  Future<void> _fetchPage({required int pageNum, required bool reset}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getDetail(
        puid: puid,
        pageNum: pageNum,
        pageSize: pageSize,
      );

      final mergedMessages = reset
          ? result.messages
          : _mergeMessages(messages, result.messages);

      _data = PrivateMessageDetail(
        isSystemInt: result.isSystemInt,
        unReadInt: result.unReadInt,
        isBanInt: result.isBanInt,
        messages: mergedMessages,
        loginPuid: result.loginPuid,
        pageInfo: result.pageInfo,
        interval: result.interval,
      );

      _nextPage = result.pageInfo.nextPage > result.pageInfo.pageNum
          ? result.pageInfo.nextPage
          : result.pageInfo.pageNum + 1;
      _isLastPage = result.pageInfo.isEnd || result.messages.length < pageSize;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SinglePrivateMessage> _mergeMessages(
    List<SinglePrivateMessage> currentMessages,
    List<SinglePrivateMessage> incomingMessages,
  ) {
    // TODO: Confirm the API paging order for pm details.
    // We currently assume loadMore() returns older history pages, so the newly
    // fetched messages are prepended. If the backend returns a different order,
    // switch this merge strategy or normalize by timestamp before rendering.
    final mergedSource = prependHistoryOnLoadMore
        ? [...incomingMessages, ...currentMessages]
        : [...currentMessages, ...incomingMessages];

    final seenPmids = <int>{};
    final mergedMessages = <SinglePrivateMessage>[];

    for (final message in mergedSource) {
      if (seenPmids.add(message.pmid)) {
        mergedMessages.add(message);
      }
    }

    return mergedMessages;
  }
}
