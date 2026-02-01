import 'dart:convert';
import 'dart:io' show HttpException;

import 'package:bluefish/models/author_homepage/author_home_thread_title.dart' show AuthorHomeThreadTitle;
import 'package:bluefish/utils/http_with_ua.dart';


class AuthorHomeThreadList {
  final String authorEuid;
  final List<AuthorHomeThreadTitle> threads = [];
  int currentThreadListPage = 1;
  bool isLastPage = false;
  static const threadPageSize = 30;
  bool isLoadingThreads = false;

  AuthorHomeThreadList({required this.authorEuid});

  Future<void> loadNextPageThreads() async {
  if (isLastPage || isLoadingThreads) return;
  isLoadingThreads = true;

  try {
    final Uri threadAPI = Uri.parse(
      "https://bbs.hupu.com/pcmapi/pc/space/v1/getThreadList?euid=$authorEuid&page=$currentThreadListPage&pageSize=$threadPageSize",
    );

    final response = await HttpwithUA().get(threadAPI);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load threads.');
    }

    // strong type constraints, emit problems as early as possible.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> threadsData = json['data'] as List<dynamic>? ?? [];
    final newThreadsList = threadsData
        .map((e) => AuthorHomeThreadTitle.fromJson(e as Map<String, dynamic>))
        .toList();

    threads.addAll(newThreadsList);

    if (newThreadsList.length < AuthorHomeThreadList.threadPageSize) {
      isLastPage = true;
    } else {
      currentThreadListPage++;
    }
  } finally {
    isLoadingThreads = false;
  }
}
}