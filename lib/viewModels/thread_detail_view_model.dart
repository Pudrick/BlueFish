import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/services/thread_detail_service.dart';
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
  int _currentPage;
  String? _filterEuid;

  ThreadDetailViewModel({
    required this.tid,
    int initialPage = 1,
    String? initialFilterEuid,
    ThreadDetailService? service,
  }) : _currentPage = initialPage,
       _filterEuid = _normalizeFilterEuid(initialFilterEuid),
       _service = service ?? ThreadDetailService();

  // ===== Getters =====

  ThreadDetailState get state => _state;
  ThreadDetail? get data => _data;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get filterEuid => _filterEuid;

  bool get isLoading => _state == ThreadDetailState.loading;
  bool get isLoaded => _state == ThreadDetailState.loaded;
  bool get isError => _state == ThreadDetailState.error;
  bool get hasAuthorFilter => _filterEuid != null;
  bool get isOnlyOp =>
      _filterEuid != null && _data != null && _filterEuid == _data!.opEuid;

  /// Total number of pages (returns 1 if data not loaded).
  int get totalPages => _data?.totalPagesNum ?? 1;

  /// Whether previous page is available.
  bool get canGoPrev => _currentPage > 1;

  /// Whether next page is available.
  bool get canGoNext => _currentPage < totalPages;

  /// Main floor data (null if not loaded).
  get mainFloor => _data?.mainFloor;

  String? get opEuid => _data?.opEuid;

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

  Future<void> applyAuthorFilter(String euid) async {
    final normalizedEuid = _normalizeFilterEuid(euid);
    if (normalizedEuid == null) {
      return;
    }

    if (_filterEuid == normalizedEuid &&
        _currentPage == 1 &&
        _state == ThreadDetailState.loaded) {
      return;
    }

    _filterEuid = normalizedEuid;
    _currentPage = 1;
    await _loadPage(1, forceRefresh: false);
  }

  Future<void> clearAuthorFilter() async {
    if (_filterEuid == null &&
        _currentPage == 1 &&
        _state == ThreadDetailState.loaded) {
      return;
    }

    _filterEuid = null;
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
    notifyListeners();

    final result = await _service.getThreadDetail(
      tid,
      page,
      authorEuid: _filterEuid,
      forceRefresh: forceRefresh,
    );

    result.when(
      success: (data) {
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

  static String? _normalizeFilterEuid(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
