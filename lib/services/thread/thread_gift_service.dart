import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread/thread_gift.dart';
import 'package:bluefish/models/thread/thread_gift_detail_page.dart';
import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/utils/result.dart';
import 'package:http/http.dart' as http;

class ThreadGiftService {
  static const String _threadGiftsPath = 'bbsallapi/hcoin/v1/getThreadGifts';
  static const String _hCoinPath = 'bbsallapi/hcoin/v1/getHcoin';
  static const String _giveGiftPath = 'bbsallapi/gift/v1/giveGift';
  static const String _giftDetailListPath =
      'bbsallapi/gift/v1/getThreadGiftDetailList';
  static const String _requestFailureMessage = '礼物列表加载失败，请稍后重试。';
  static const String _emptyGiftMessage = '礼物列表暂时为空。';
  static const String _hCoinRequestFailureMessage = '当前币数加载失败，请稍后重试。';
  static const String _giveGiftFailureMessage = '送礼失败，请稍后重试。';
  static const String _invalidGiftIdMessage = '礼物信息无效，请刷新后重试。';
  static const String _giftDetailRequestFailureMessage = '收到礼物列表加载失败，请稍后重试。';
  static const String _giftDetailInvalidParamsMessage = '参数异常，暂时无法加载收到的礼物。';

  final http.Client _client;

  List<ThreadGift>? _cachedGifts;
  Future<Result<List<ThreadGift>>>? _inflightRequest;
  int? _cachedHCoin;
  Future<Result<int>>? _inflightHCoinRequest;

  ThreadGiftService({required http.Client client}) : _client = client;

  Future<Result<List<ThreadGift>>> getThreadGifts({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedGifts != null) {
      return Future<Result<List<ThreadGift>>>.value(
        Success<List<ThreadGift>>(List<ThreadGift>.unmodifiable(_cachedGifts!)),
      );
    }

    if (!forceRefresh && _inflightRequest != null) {
      return _inflightRequest!;
    }

    final request = _fetchThreadGifts();
    _inflightRequest = request;
    request.whenComplete(() {
      if (identical(_inflightRequest, request)) {
        _inflightRequest = null;
      }
    });
    return request;
  }

  Future<Result<int>> getHcoin({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedHCoin != null) {
      return Future<Result<int>>.value(Success<int>(_cachedHCoin!));
    }

    if (!forceRefresh && _inflightHCoinRequest != null) {
      return _inflightHCoinRequest!;
    }

    final request = _fetchHcoin();
    _inflightHCoinRequest = request;
    request.whenComplete(() {
      if (identical(_inflightHCoinRequest, request)) {
        _inflightHCoinRequest = null;
      }
    });
    return request;
  }

  Future<Result<String>> giveGift({
    required String giftId,
    required String givePuid,
    required String pid,
    required String receivePuid,
    required String tid,
  }) async {
    final normalizedGiftId = giftId.trim();
    final normalizedGivePuid = givePuid.trim();
    final normalizedPid = pid.trim();
    final normalizedReceivePuid = receivePuid.trim();
    final normalizedTid = tid.trim();
    final parsedGiftId = int.tryParse(normalizedGiftId);

    if (parsedGiftId == null ||
        normalizedGivePuid.isEmpty ||
        normalizedPid.isEmpty ||
        normalizedReceivePuid.isEmpty ||
        normalizedTid.isEmpty) {
      return const Failure<String>(_invalidGiftIdMessage);
    }

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.apiPath(_giveGiftPath)),
        headers: const <String, String>{
          'content-type': 'application/json;charset=UTF-8',
        },
        body: jsonEncode(<String, Object>{
          'giftId': parsedGiftId,
          'giftNum': 1,
          'givePuid': normalizedGivePuid,
          'pid': normalizedPid,
          'receivePuid': normalizedReceivePuid,
          'tid': normalizedTid,
        }),
      );

      if (response.statusCode != HttpStatus.ok) {
        return const Failure<String>(_giveGiftFailureMessage);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure<String>(_giveGiftFailureMessage);
      }

      final success = parseBool(decoded['success']);
      final message = parseString(decoded['msg']).trim();
      if (!success) {
        return Failure<String>(
          message.isNotEmpty ? message : _giveGiftFailureMessage,
        );
      }

      _cachedHCoin = null;
      return Success<String>(message.isNotEmpty ? message : '投币成功');
    } on FormatException {
      return const Failure<String>(_giveGiftFailureMessage);
    } on http.ClientException {
      return const Failure<String>(_giveGiftFailureMessage);
    } on SocketException {
      return const Failure<String>(_giveGiftFailureMessage);
    }
  }

  Future<Result<ThreadGiftDetailPage>> getThreadGiftDetailList({
    required String tid,
    required String pid,
    int page = 1,
    int pageSize = 20,
  }) async {
    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    final resolvedPage = page < 1 ? 1 : page;
    final resolvedPageSize = pageSize < 1 ? 20 : pageSize;

    if (normalizedTid.isEmpty || normalizedPid.isEmpty) {
      return const Failure<ThreadGiftDetailPage>(
        _giftDetailInvalidParamsMessage,
      );
    }

    final uri = Uri.parse(ApiConfig.apiPath(_giftDetailListPath)).replace(
      queryParameters: <String, String>{
        'tid': normalizedTid,
        'pid': normalizedPid,
        'page': '$resolvedPage',
        'pageSize': '$resolvedPageSize',
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != HttpStatus.ok) {
        return const Failure<ThreadGiftDetailPage>(
          _giftDetailRequestFailureMessage,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure<ThreadGiftDetailPage>(
          _giftDetailRequestFailureMessage,
        );
      }

      final success = parseBool(decoded['success']);
      final message = parseString(decoded['msg']).trim();
      if (!success) {
        return Failure<ThreadGiftDetailPage>(
          message.isNotEmpty ? message : _giftDetailRequestFailureMessage,
        );
      }

      return Success<ThreadGiftDetailPage>(
        ThreadGiftDetailPage.fromJson(decoded),
      );
    } on FormatException {
      return const Failure<ThreadGiftDetailPage>(
        _giftDetailRequestFailureMessage,
      );
    } on ArgumentError {
      return const Failure<ThreadGiftDetailPage>(
        _giftDetailRequestFailureMessage,
      );
    } on http.ClientException {
      return const Failure<ThreadGiftDetailPage>(
        _giftDetailRequestFailureMessage,
      );
    } on SocketException {
      return const Failure<ThreadGiftDetailPage>(
        _giftDetailRequestFailureMessage,
      );
    }
  }

  Future<Result<List<ThreadGift>>> _fetchThreadGifts() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.apiPath(_threadGiftsPath)),
      );

      if (response.statusCode != HttpStatus.ok) {
        return const Failure<List<ThreadGift>>(_requestFailureMessage);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure<List<ThreadGift>>(_requestFailureMessage);
      }

      final success = parseBool(decoded['success']);
      final message = parseString(decoded['msg']).trim();
      if (!success) {
        return Failure<List<ThreadGift>>(
          message.isNotEmpty ? message : _requestFailureMessage,
        );
      }

      final gifts = _parseGiftList(decoded['data']);
      if (gifts.isEmpty) {
        return const Failure<List<ThreadGift>>(_emptyGiftMessage);
      }

      _cachedGifts = List<ThreadGift>.unmodifiable(gifts);
      return Success<List<ThreadGift>>(_cachedGifts!);
    } on FormatException {
      return const Failure<List<ThreadGift>>(_requestFailureMessage);
    } on http.ClientException {
      return const Failure<List<ThreadGift>>(_requestFailureMessage);
    } on SocketException {
      return const Failure<List<ThreadGift>>(_requestFailureMessage);
    }
  }

  Future<Result<int>> _fetchHcoin() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.apiPath(_hCoinPath)),
      );

      if (response.statusCode != HttpStatus.ok) {
        return const Failure<int>(_hCoinRequestFailureMessage);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure<int>(_hCoinRequestFailureMessage);
      }

      final success = parseBool(decoded['success']);
      final message = parseString(decoded['msg']).trim();
      if (!success) {
        return Failure<int>(
          message.isNotEmpty ? message : _hCoinRequestFailureMessage,
        );
      }

      final rawData = decoded['data'];
      if (rawData is! num) {
        return const Failure<int>(_hCoinRequestFailureMessage);
      }

      _cachedHCoin = rawData.toInt();
      return Success<int>(_cachedHCoin!);
    } on FormatException {
      return const Failure<int>(_hCoinRequestFailureMessage);
    } on http.ClientException {
      return const Failure<int>(_hCoinRequestFailureMessage);
    } on SocketException {
      return const Failure<int>(_hCoinRequestFailureMessage);
    }
  }

  List<ThreadGift> _parseGiftList(Object? rawData) {
    if (rawData is! List) {
      return const <ThreadGift>[];
    }

    final gifts = <ThreadGift>[];
    for (final item in rawData) {
      if (item is! Map) {
        continue;
      }

      final gift = ThreadGift.tryFromJson(Map<String, dynamic>.from(item));
      if (gift != null) {
        gifts.add(gift);
      }
    }
    return gifts;
  }
}
