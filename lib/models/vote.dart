import 'dart:convert';

import '../utils/http_with_ua.dart';
import '../userdata/user_settings.dart';

enum VoteType { dualImage, noImage }

class UserVoteRecord {
  late int sort;
  late int voteCount;
}

//TODO: add initializer
class VoteItem {
  late int sort;
  late String content;
  late int optionVoteCount;
  late Uri attachment; // usually image url.
  late double percentage;
}

//TODO: add initializer
class Vote {
  late dynamic voteID;
  late String title;
  late int userOptionLimit;
  late int userCount;
  late int voteCount;
  late bool canVote;
  late int puid;
  late List<VoteItem> voteDetailList;
  late List<int> userVoteRecordList;
  late int?
      votingType; //current known usage: 1 for image vote, 0 or null for text vote
  int? deadline; // days remaining
  late String endTimeStr;
  late List<UserVoteRecord> userVoteRecordMap;
  late int voteNum; //maybe always 0?
  String? votingForm; // maybe always null?
  late bool end;
  late VoteType voteType;

  // req example: https://bbs.mobileapi.hupu.com/3/8.0.80/bbsintapi/vote/v1/getVoteInfo?voteId=11124697
  Future<void> refresh() async {
    var voteUrl = Uri.parse(
        "https://bbs.mobileapi.hupu.com/3/$appVersionNumber/bbsintapi/vote/v1/getVoteInfo?voteId=$voteID");

    // for testing
    final headers = {"Cookie": ""};

    // var voteJsonStr = await HttpwithUA().get(voteUrl, headers: headers);
    var voteJsonStr = await HttpwithUA().get(voteUrl);

    var voteJson = jsonDecode(voteJsonStr.body);
    if (voteJson["code"] != 200) {
      throw Exception("Failed to get vote info: ${voteJson["msg"]}");
      // TODO: handle exception.
    }
    var voteData = voteJson["data"];
    title = voteData["title"];
    userOptionLimit = voteData["userOptionLimit"];
    userCount = voteData["userCount"];
    voteCount = voteData["voteCount"];
    canVote = voteData["canVote"];
    puid = voteData["puid"];

    votingType = voteData["votingType"];
    if (votingType == 1) {
      voteType = VoteType.dualImage;
    } else {
      voteType = VoteType.noImage;
    }

    voteDetailList = [];
    userVoteRecordList = [];
    userVoteRecordMap = [];
    for (var item in voteData["voteDetailList"]) {
      VoteItem voteItem = VoteItem();
      voteItem.sort = item["sort"];
      voteItem.content = item["content"];
      voteItem.optionVoteCount = item["optionVoteCount"];
      voteItem.percentage = voteItem.optionVoteCount / voteCount;

      // abandon check in every option, using voteType check instead.
      // if (item["attachment"] != null && item["attachment"] != "null")
      if (voteType == VoteType.dualImage) {
        voteItem.attachment = Uri.parse(item["attachment"]);
      }
      voteDetailList.add(voteItem);
    }
    if (voteData["userVoteRecordList"] != null) {
      for (var item in voteData["userVoteRecordList"]) {
        userVoteRecordList.add(item);
      }
    }
    deadline = voteData["deadline"];
    endTimeStr = voteData["endTimeStr"];

    // if didn't vote, userVoteRecordMap will be [] instead of null.
    for (var item in voteData["userVoteRecordMap"]) {
      UserVoteRecord userVoteRecordItem = UserVoteRecord();
      userVoteRecordItem.sort = item["sort"];
      userVoteRecordItem.voteCount = item["voteCount"];
      userVoteRecordMap.add(userVoteRecordItem);
    }
    voteNum = voteData["voteNum"];
    votingForm = voteData["votingForm"];
    end = voteData["end"];
  }

  // req example: https://bbs.mobileapi.hupu.com/3/8.0.80/bbsintapi/vote/v1/vote?voteId=11124697&option=1
  // copilot generated url, don't know if it's correct.

  // TODO
  Future<void> voteFor() async {}
}
