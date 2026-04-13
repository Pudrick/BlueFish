import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/utils/result.dart';
import 'package:http/http.dart' as http;

class ThreadReportService {
  static const String _requestFailureMessage = '举报失败，请稍后重试。';
  static const String _invalidParamsMessage = '举报参数异常，请稍后重试。';

  final http.Client _client;

  ThreadReportService({required http.Client client}) : _client = client;

  Future<Result<String>> reportThread({
    required String tid,
    required String topicId,
    required String typeId,
    required String content,
  }) {
    return _report(
      tid: tid,
      topicId: topicId,
      typeId: typeId,
      pid: '',
      content: content,
      requirePid: false,
    );
  }

  Future<Result<String>> reportReply({
    required String tid,
    required String topicId,
    required String pid,
    required String typeId,
    required String content,
  }) {
    return _report(
      tid: tid,
      topicId: topicId,
      typeId: typeId,
      pid: pid,
      content: content,
      requirePid: true,
    );
  }

  Future<Result<String>> _report({
    required String tid,
    required String topicId,
    required String typeId,
    required String pid,
    required String content,
    required bool requirePid,
  }) async {
    final normalizedTid = tid.trim();
    final normalizedTopicId = topicId.trim();
    final normalizedTypeId = typeId.trim();
    final normalizedPid = pid.trim();
    final normalizedContent = content.trim();

    if (normalizedTid.isEmpty ||
        normalizedTopicId.isEmpty ||
        normalizedTypeId.isEmpty ||
        (requirePid && normalizedPid.isEmpty) ||
        normalizedContent.isEmpty) {
      return const Failure<String>(_invalidParamsMessage);
    }

    final uri = Uri.https(
      'bbs.hupu.com',
      '/api/v2/threads/$normalizedTid/report',
    );

    try {
      final response = await _client.post(
        uri,
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, String>{
          'tid': normalizedTid,
          'topicId': normalizedTopicId,
          'type': normalizedTypeId,
          'pid': normalizedPid,
          'content': normalizedContent,
        }),
      );

      if (response.statusCode != HttpStatus.ok) {
        return const Failure<String>(_requestFailureMessage);
      }

      final payload = parseMap(jsonDecode(response.body));
      final code = parseInt(payload['code']);
      final message = parseString(payload['message']).trim();

      if (code == HttpStatus.ok) {
        return Success<String>(message);
      }

      return Failure<String>(
        message.isNotEmpty ? message : _requestFailureMessage,
      );
    } on FormatException {
      return const Failure<String>(_requestFailureMessage);
    } on ArgumentError {
      return const Failure<String>(_requestFailureMessage);
    } on http.ClientException {
      return const Failure<String>(_requestFailureMessage);
    } on SocketException {
      return const Failure<String>(_requestFailureMessage);
    }
  }
}
