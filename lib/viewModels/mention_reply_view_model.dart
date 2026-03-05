// fully comes from vibe.

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/services/mention_reply_service.dart';
import 'package:flutter/material.dart';

class MentionReplyViewModel extends ChangeNotifier {
  final MentionReplyService _service = MentionReplyService();

  String? pageStr;
  bool hasNextPage = true;
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
        newReplyList: newList,
        oldReplyList: oldList,
        :pageStr,
        :hasNextPage,
      ) = await _service
          .getReplyList();
      _newList = newList;
      _oldList = oldList;
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
          newReplyList: apiNewList,
          oldReplyList: apiOldList,
          :pageStr,
          :hasNextPage,
        ) = await _service.getReplyList(
          currentPageStr: this.pageStr,
        );
        this.pageStr = pageStr;
        this.hasNextPage = hasNextPage;
        // now newList should be empty here, so addAll will add nothing eventually ...?
        if (apiNewList.isNotEmpty) {
          _newList.addAll(apiNewList);
        }
        _oldList.addAll(apiOldList);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
