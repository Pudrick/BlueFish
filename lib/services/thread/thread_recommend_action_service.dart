import 'dart:convert';
import 'dart:io';

import 'package:bluefish/network/api_config.dart';
import 'package:http/http.dart' as http;

enum ThreadRecommendActionStatus { success, duplicate, failure }

class ThreadRecommendActionResult {
  final ThreadRecommendActionStatus status;
  final String? message;

  const ThreadRecommendActionResult._({required this.status, this.message});

  const ThreadRecommendActionResult.success([String? message])
    : this._(status: ThreadRecommendActionStatus.success, message: message);

  const ThreadRecommendActionResult.duplicate(String message)
    : this._(status: ThreadRecommendActionStatus.duplicate, message: message);

  const ThreadRecommendActionResult.failure([String? message])
    : this._(status: ThreadRecommendActionStatus.failure, message: message);

  bool get isSuccess => status == ThreadRecommendActionStatus.success;

  bool get isDuplicate => status == ThreadRecommendActionStatus.duplicate;
}

class ThreadRecommendActionService {
  static const String _recommendPath = 'bbsintapi/recommend/v1/recommend';
  static const String _fixedFid = '4875';
  static const String _successReturnCode = '00000000';
  static const String _duplicateReturnCode = 'OI022203';

  final http.Client _client;

  ThreadRecommendActionService({required http.Client client})
    : _client = client;

  Future<ThreadRecommendActionResult> recommend({required String tid}) {
    return _submitAction(
      tid: tid,
      recommendStatus: '1',
      failureMessage: '推荐失败，请稍后重试。',
    );
  }

  Future<ThreadRecommendActionResult> cancelRecommend({required String tid}) {
    return _submitAction(
      tid: tid,
      recommendStatus: '0',
      failureMessage: '取消推荐失败，请稍后重试。',
    );
  }

  Future<ThreadRecommendActionResult> downvote({required String tid}) {
    return _submitAction(
      tid: tid,
      recommendStatus: '-1',
      failureMessage: '点踩失败，请稍后重试。',
    );
  }

  Future<ThreadRecommendActionResult> _submitAction({
    required String tid,
    required String recommendStatus,
    required String failureMessage,
  }) async {
    final normalizedTid = tid.trim();
    if (normalizedTid.isEmpty) {
      return ThreadRecommendActionResult.failure(failureMessage);
    }

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.apiPath(_recommendPath)),
        headers: const <String, String>{
          'content-type': 'application/json;charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'fid': _fixedFid,
          'recommendStatus': recommendStatus,
          'tid': normalizedTid,
        }),
      );

      if (response.statusCode != HttpStatus.ok) {
        return ThreadRecommendActionResult.failure(failureMessage);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return ThreadRecommendActionResult.failure(failureMessage);
      }

      final returnCode = '${decoded['returnCode'] ?? ''}'.trim();
      final code = decoded['code'];
      final msg = '${decoded['msg'] ?? ''}'.trim();

      if (returnCode == _successReturnCode &&
          code is num &&
          code.toInt() == HttpStatus.ok &&
          msg == 'success') {
        return ThreadRecommendActionResult.success(msg);
      }

      if (returnCode == _duplicateReturnCode) {
        return ThreadRecommendActionResult.duplicate(
          msg.isEmpty ? '你已推荐过该贴' : msg,
        );
      }

      if (msg.isNotEmpty) {
        return ThreadRecommendActionResult.failure(msg);
      }
      return ThreadRecommendActionResult.failure(failureMessage);
    } on FormatException {
      return ThreadRecommendActionResult.failure(failureMessage);
    } on http.ClientException {
      return ThreadRecommendActionResult.failure(failureMessage);
    } on SocketException {
      return ThreadRecommendActionResult.failure(failureMessage);
    }
  }
}
