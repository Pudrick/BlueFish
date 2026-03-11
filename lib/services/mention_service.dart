import 'dart:convert';
import 'dart:io';

import 'package:bluefish/utils/http_with_ua_coke.dart';

class MentionService<T> {
  final String apiPath;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, String> defaultQueryParameters;

  MentionService({
    required this.apiPath,
    required this.fromJson,
    this.defaultQueryParameters = const {},
  });

  String get _baseUrl => "https://bbs.hupu.com/pcmapi/pc/space/v1/$apiPath";

  Future<
    ({
      List<T> newList,
      List<T> oldList,
      String pageStr,
      bool hasNextPage,
    })
  >
  getList({String? currentPageStr}) async {
    final baseUri = Uri.parse(_baseUrl);
    final url = baseUri.replace(
      queryParameters: {
        ...defaultQueryParameters,
        if (currentPageStr != null) 'pageStr': currentPageStr,
      },
    );
    var response = await HttpwithUA().get(url);
    if (response.statusCode != 200) {
      throw const HttpException("Failed to get http response.");
    }
    final rawJson = jsonDecode(response.body);

    List<T> parseList(dynamic list) {
      return (list as List?)
              ?.map((json) => fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
    }

    final String pageStr = rawJson['data']['pageStr'];
    final bool hasNextPage = rawJson['data']['hasNextPage'];
    return (
      newList: parseList(rawJson['data']['newList']),
      oldList: parseList(rawJson['data']['hisList']),
      pageStr: pageStr,
      hasNextPage: hasNextPage,
    );
  }
}
