import 'dart:convert';

import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/vote.dart';
import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:http/http.dart' as http;

class VoteService {
  final http.Client _client;

  VoteService({http.Client? client}) : _client = client ?? httpClient;

  // Request example:
  // https://bbs.mobileapi.hupu.com/3/8.0.80/bbsintapi/vote/v1/getVoteInfo?voteId=11124697
  Future<Vote> getVote(int voteId) async {
    final voteUrl = Uri.parse(
      ApiConfig.apiPath('bbsintapi/vote/v1/getVoteInfo', gatewayVersion: '3'),
    ).replace(queryParameters: <String, String>{'voteId': '$voteId'});
    final response = await _client.get(voteUrl);

    if (response.statusCode != 200) {
      throw Exception('Failed to get vote info: HTTP ${response.statusCode}.');
    }

    final voteJson = parseMap(jsonDecode(response.body));
    if (parseInt(voteJson['code']) != 200) {
      throw Exception(
        'Failed to get vote info: ${parseString(voteJson['msg'])}',
      );
      // TODO: handle exception with a typed error.
    }

    return Vote.fromJson(parseMap(voteJson['data']), voteId: voteId);
  }

  // Request example:
  // https://bbs.mobileapi.hupu.com/3/8.0.80/bbsintapi/vote/v1/vote?voteId=11124697&option=1
  // Copilot generated URL; it still needs validation before implementation.
  Future<void> voteFor(int voteId, List<int> optionSorts) async {
    throw UnimplementedError('Vote submission is not implemented yet.');
  }
}
