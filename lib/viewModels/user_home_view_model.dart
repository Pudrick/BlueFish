import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:bluefish/services/user_home_service.dart';
import 'package:flutter/foundation.dart';

class UserHomeViewModel extends ChangeNotifier {
  UserHome? _data;
  final UserHomeService _service = UserHomeService();
  final int euid;

  UserHomeViewModel({required this.euid});

  UserHome? get data => _data;

  int _currentThreadPage = 1;
  bool _isLoadingThreads = false;
  bool _isLastThreadPage = false;

  int _currentRecommendPage = 1;
  bool _isLoadingRecommends = false;
  bool _isLastRecommendPage = false;

  int _currentReplyPage = 1;
  bool _isLoadingReplies = false;
  bool _isLastReplyPage = false;

  bool get isLoadingThreads => _isLoadingThreads;
  bool get isLoadingRecommends => _isLoadingRecommends;

  Future<void> init() async {
    _data = await _service.getAuthorHomeByEuid(euid);
    await loadMoreThreads();
    await loadMoreReplies();
    notifyListeners();
  }

  Future<void> loadMoreThreads() async {
    if (_isLastThreadPage || _isLoadingThreads || _data == null) return;

    _isLoadingThreads = true;
    notifyListeners();

    try {
      final newThreads = await _service.loadThreadsPage(
        authorEuid: _data!.euid,
        type: ThreadListType.post,
        page: _currentThreadPage,
      );

      _data = _data!.copyWith(threads: [..._data!.threads, ...newThreads]);

      if (newThreads.length < UserHome.threadPageSize) {
        _isLastThreadPage = true;
      } else {
        _currentThreadPage++;
      }
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreRecommends() async {
    if (_isLastRecommendPage || _isLoadingRecommends || _data == null) return;

    _isLoadingRecommends = true;
    notifyListeners();

    try {
      final newRecommends = await _service.loadThreadsPage(
        authorEuid: _data!.euid,
        type: ThreadListType.recommend,
        page: _currentRecommendPage,
      );

      _data = _data!.copyWith(
        recommendThreads: [..._data!.recommendThreads, ...newRecommends],
      );

      if (newRecommends.length < UserHome.threadPageSize) {
        _isLastRecommendPage = true;
      } else {
        _currentRecommendPage++;
      }
    } finally {
      _isLoadingRecommends = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReplies() async {
    if (_isLastReplyPage || _isLoadingReplies || _data == null) return;

    _isLoadingReplies = true;
    notifyListeners();

    try {
      final newReplies = await _service.loadRepliesPage(
        authorEuid: _data!.euid,
        page: _currentReplyPage,
      );

      _data = _data!.copyWith(replies: [..._data!.replies, ...newReplies]);

      if (newReplies.length < UserHome.replyPageSize) {
        _isLastReplyPage = true;
      } else {
        _currentReplyPage++;
      }
    } finally {
      _isLoadingReplies = false;
      notifyListeners();
    }
  }
}
