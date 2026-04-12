import 'dart:convert';
import 'dart:io';

import 'package:bluefish/network/api_config.dart';
import 'package:http/http.dart' as http;

enum ReplyLightActionStatus { success, alreadyLighted, notLighted, failure }

class ReplyLightActionResult {
  final ReplyLightActionStatus status;
  final String? message;

  const ReplyLightActionResult._({required this.status, this.message});

  const ReplyLightActionResult.success()
    : this._(status: ReplyLightActionStatus.success);

  const ReplyLightActionResult.alreadyLighted(String message)
    : this._(status: ReplyLightActionStatus.alreadyLighted, message: message);

  const ReplyLightActionResult.failure([String? message])
    : this._(status: ReplyLightActionStatus.failure, message: message);

  bool get isSuccess => status == ReplyLightActionStatus.success;

  bool get isAlreadyLighted => status == ReplyLightActionStatus.alreadyLighted;

  bool get isNotLighted => status == ReplyLightActionStatus.notLighted;
}

class ReplyLightActionService {
  static const String _replyLightPath = 'bbslightapi/light/v1/replyLightNew';
  static const String _cancelLightPath = 'bbslightapi/light/v1/cancelLight';
  static const String _fixedFid = '4875';
  static const String _lightFailureMessage = '点亮失败，请稍后重试。';
  static const String _cancelFailureMessage = '取消点亮失败，请稍后重试。';

  final http.Client _client;

  ReplyLightActionService({required http.Client client}) : _client = client;

  Future<ReplyLightActionResult> lightReply({
    required String tid,
    required String pid,
    required String puid,
  }) async {
    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    final normalizedPuid = puid.trim();
    if (normalizedTid.isEmpty ||
        normalizedPid.isEmpty ||
        normalizedPuid.isEmpty) {
      return const ReplyLightActionResult.failure(_lightFailureMessage);
    }

    return _postLightRequest(
      url: Uri.parse(ApiConfig.apiPath(_replyLightPath)),
      headers: const <String, String>{
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      body: <String, String>{
        'tid': normalizedTid,
        'fid': _fixedFid,
        'pid': normalizedPid,
        'puid': normalizedPuid,
      },
      requestFailureMessage: _lightFailureMessage,
      handlePayload: (decoded) {
        final errorText = _errorTextFromPayload(decoded);
        if (errorText.contains('已经点亮过')) {
          return ReplyLightActionResult.alreadyLighted(errorText);
        }

        final status = decoded['status'];
        if (status is num && status.toInt() == HttpStatus.ok) {
          return const ReplyLightActionResult.success();
        }

        if (errorText.isNotEmpty) {
          return ReplyLightActionResult.failure(errorText);
        }

        return const ReplyLightActionResult.failure(_lightFailureMessage);
      },
    );
  }

  Future<ReplyLightActionResult> cancelLight({
    required String tid,
    required String pid,
    required String puid,
  }) async {
    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    final normalizedPuid = puid.trim();
    if (normalizedTid.isEmpty ||
        normalizedPid.isEmpty ||
        normalizedPuid.isEmpty) {
      return const ReplyLightActionResult.failure(_cancelFailureMessage);
    }

    return _postLightRequest(
      url: Uri.parse(ApiConfig.apiPath(_cancelLightPath)),
      headers: const <String, String>{
        'content-type': 'application/json;charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'fid': _fixedFid,
        'pid': normalizedPid,
        'puid': normalizedPuid,
        'tid': normalizedTid,
      }),
      requestFailureMessage: _cancelFailureMessage,
      handlePayload: (decoded) {
        final errorText = _errorTextFromPayload(decoded);
        if (errorText.contains('请先点亮后再操作')) {
          return ReplyLightActionResult._(
            status: ReplyLightActionStatus.notLighted,
            message: errorText,
          );
        }

        final code = decoded['code'];
        final msg = '${decoded['msg'] ?? ''}'.trim();
        if (code is num && code.toInt() == 1 && msg == 'SUCCESS') {
          return const ReplyLightActionResult.success();
        }

        if (errorText.isNotEmpty) {
          return ReplyLightActionResult.failure(errorText);
        }

        return const ReplyLightActionResult.failure(_cancelFailureMessage);
      },
    );
  }

  Future<ReplyLightActionResult> _postLightRequest({
    required Uri url,
    required Map<String, String> headers,
    required Object body,
    required String requestFailureMessage,
    required ReplyLightActionResult Function(Map<String, dynamic> decoded)
    handlePayload,
  }) async {
    try {
      final response = await _client.post(url, headers: headers, body: body);

      if (response.statusCode != HttpStatus.ok) {
        return ReplyLightActionResult.failure(requestFailureMessage);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return ReplyLightActionResult.failure(requestFailureMessage);
      }

      return handlePayload(decoded);
    } on FormatException {
      return ReplyLightActionResult.failure(requestFailureMessage);
    } on http.ClientException {
      return ReplyLightActionResult.failure(requestFailureMessage);
    } on SocketException {
      return ReplyLightActionResult.failure(requestFailureMessage);
    }
  }

  String _errorTextFromPayload(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map) {
      return '${error['text'] ?? ''}'.trim();
    }
    return '';
  }
}
