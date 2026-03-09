// fully comes from vibe.

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/services/mention_reply_service.dart';
import 'package:flutter/material.dart';

class MentionReplyViewModel extends ChangeNotifier {
  final MentionReplyService _service = MentionReplyService();

  String? pageStr;
  bool hasNextPage = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MentionReply> _newList = [];
  List<MentionReply> get newList => _newList;

  List<MentionReply> _oldList = [];
  List<MentionReply> get oldList => _oldList;

  Future<void> init() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final (
        newList: newItems,
        oldList: oldItems,
        :pageStr,
        :hasNextPage,
      ) = await _service
          .getList();
      _newList = newItems;
      _oldList = oldItems;
      this.pageStr = pageStr;
      this.hasNextPage = hasNextPage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMoreReplies() async {
    if (_isLoading || !hasNextPage) return;
    _isLoading = true;
    notifyListeners();
    if (pageStr != null) {
      try {
        final (
          newList: newItems,
          oldList: oldItems,
          :pageStr,
          :hasNextPage,
        ) = await _service.getList(
          currentPageStr: this.pageStr,
        );
        this.pageStr = pageStr;
        this.hasNextPage = hasNextPage;
        // now newItems should be empty here, so addAll will add nothing eventually ...?
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
