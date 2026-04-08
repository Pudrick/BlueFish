import 'package:bluefish/models/author_identity.dart';
import 'package:bluefish/models/internal_settings.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:flutter/foundation.dart';

/// State of the thread detail page.
enum ThreadDetailState { initial, loading, loaded, error }

/// ViewModel for thread detail page.
///
/// Manages state and business logic, communicates with [ThreadDetailService].
class ThreadDetailViewModel extends ChangeNotifier {
  final ThreadDetailService _service;
  final String tid;

  ThreadDetailState _state = ThreadDetailState.initial;
  ThreadDetail? _data;
  String? _errorMessage;
  String? _pendingInterceptMessage;
  int _currentPage;
  AuthorIdentity? _authorFilter;

  ThreadDetailViewModel({
    required this.tid,
    int initialPage = 1,
    AuthorIdentity? initialAuthorFilter,
    ThreadDetailService? service,
  }) : _currentPage = initialPage,
       _authorFilter = initialAuthorFilter,
       _service = service ?? ThreadDetailService();

  // ===== Getters =====

  ThreadDetailState get state => _state;
  ThreadDetail? get data => _data;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  AuthorIdentity? get authorFilter => _authorFilter;
  String? get filterEuid =>
      _authorFilter?.kind == AuthorIdentityKind.euid ? _authorFilter!.id : null;
  String? get filterPuid =>
      _authorFilter?.kind == AuthorIdentityKind.puid ? _authorFilter!.id : null;

  bool get isLoading => _state == ThreadDetailState.loading;
  bool get isLoaded => _state == ThreadDetailState.loaded;
  bool get isError => _state == ThreadDetailState.error;
  bool get hasAuthorFilter => _authorFilter != null;
  bool get isOnlyOp =>
      _authorFilter != null &&
      _data != null &&
      _authorFilter!.matchesAuthor(_data!.mainFloor.meta.author);

  /// Total number of pages (returns 1 if data not loaded).
  int get totalPages => _data?.totalPagesNum ?? 1;

  /// Whether previous page is available.
  bool get canGoPrev => _currentPage > 1;

  /// Whether next page is available.
  bool get canGoNext => _currentPage < totalPages;

  /// Main floor data (null if not loaded).
  get mainFloor => _data?.mainFloor;

  String? get opEuid => _data?.opEuid;
  String? get opPuid => _data?.opPuid;

  String? consumeInterceptMessage() {
    final message = _pendingInterceptMessage;
    _pendingInterceptMessage = null;
    return message;
  }

  /// Reply list for current page (empty if not loaded).
  List get replies => _data?.replies ?? [];

  /// Lighted replies for current page (empty if not loaded).
  List get lightedReplies => _data?.lightedReplies ?? [];

  /// Replies per page constant.
  int get repliesPerPage => _data?.repliesPerPage ?? 20;

  // ===== Actions =====

  /// Loads the initial page or refreshes current page.
  Future<void> loadInitial() async {
    await _loadPage(_currentPage, forceRefresh: false);
  }

  /// Refreshes current page (forces network fetch, ignores cache).
  Future<void> refresh() async {
    await _loadPage(_currentPage, forceRefresh: true);
  }

  Future<void> applyAuthorFilter(AuthorIdentity identity) async {
    if (_authorFilter == identity &&
        _currentPage == 1 &&
        _state == ThreadDetailState.loaded) {
      return;
    }

    _authorFilter = identity;
    _currentPage = 1;
    await _loadPage(1, forceRefresh: false);
  }

  Future<void> clearAuthorFilter() async {
    if (_authorFilter == null &&
        _currentPage == 1 &&
        _state == ThreadDetailState.loaded) {
      return;
    }

    _authorFilter = null;
    _currentPage = 1;
    await _loadPage(1, forceRefresh: false);
  }

  /// Jumps to a specific page.
  Future<void> jumpToPage(int page) async {
    if (page == _currentPage && _state == ThreadDetailState.loaded) {
      return;
    }
    if (page < 1) page = 1;

    _currentPage = page;
    await _loadPage(page, forceRefresh: false);
  }

  /// Goes to previous page.
  Future<void> goToPrevPage() async {
    if (canGoPrev) {
      await jumpToPage(_currentPage - 1);
    }
  }

  /// Goes to next page.
  Future<void> goToNextPage() async {
    if (canGoNext) {
      await jumpToPage(_currentPage + 1);
    }
  }

  /// Clears cache for this thread (call after posting reply, etc.).
  void invalidateCache() {
    _service.clearCache(tid);
  }

  // ===== Private Methods =====

  Future<void> _loadPage(int page, {required bool forceRefresh}) async {
    _state = ThreadDetailState.loading;
    _errorMessage = null;
    _pendingInterceptMessage = null;
    notifyListeners();

    final result = await _service.getThreadDetail(
      tid,
      page,
      authorIdentity: _authorFilter,
      forceRefresh: forceRefresh,
    );

    result.when(
      success: (data) {
        if (data.topicId != mainTopicID) {
          _data = null;
          _errorMessage = null;
          _pendingInterceptMessage = '仅支持打开崩版';
          _state = ThreadDetailState.error;
          return;
        }

        _data = data;
        _currentPage = page;
        _state = ThreadDetailState.loaded;
      },
      failure: (message, exception) {
        _errorMessage = message;
        _state = ThreadDetailState.error;
      },
    );

    notifyListeners();
  }
}
