import 'package:bluefish/services/mention_service.dart';
import 'package:flutter/material.dart';

abstract class MentionViewModel<T> extends ChangeNotifier {
  final MentionService<T> _service;

  MentionViewModel(this._service);

  String? pageStr;
  bool hasNextPage = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<T> _newList = [];
  List<T> get newList => _newList;

  List<T> _oldList = [];
  List<T> get oldList => _oldList;

  Future<void> init() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final (newList: newItems, oldList: oldItems, :pageStr, :hasNextPage) =
          await _service.getList();
      _newList = newItems;
      _oldList = oldItems;
      this.pageStr = pageStr;
      this.hasNextPage = hasNextPage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !hasNextPage) return;
    _isLoading = true;
    notifyListeners();
    if (pageStr != null) {
      try {
        final (newList: newItems, oldList: oldItems, :pageStr, :hasNextPage) =
            await _service.getList(currentPageStr: this.pageStr);
        this.pageStr = pageStr;
        this.hasNextPage = hasNextPage;
        if (newItems.isNotEmpty) {
          _newList.addAll(newItems);
        }
        _oldList.addAll(oldItems);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
