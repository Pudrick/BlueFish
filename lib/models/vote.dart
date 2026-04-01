import 'package:bluefish/models/model_parsing.dart';

enum VoteType {
  dualImage,
  noImage;

  // Current known usage: 1 for image vote, 0 or null for text vote.
  static VoteType fromVotingType(int? votingType) {
    return votingType == 1 ? VoteType.dualImage : VoteType.noImage;
  }
}

class UserVoteRecord {
  final int sort;
  final int voteCount;

  const UserVoteRecord({required this.sort, required this.voteCount});

  factory UserVoteRecord.fromJson(Map<String, dynamic> json) {
    return UserVoteRecord(
      sort: parseInt(json['sort']),
      voteCount: parseInt(json['voteCount']),
    );
  }
}

class VoteOption {
  final int sort;
  final String content;
  final int optionVoteCount;
  final Uri? attachment;
  // Usually an image URL.
  final double percentage;

  const VoteOption({
    required this.sort,
    required this.content,
    required this.optionVoteCount,
    required this.attachment,
    required this.percentage,
  });

  factory VoteOption.fromJson(
    Map<String, dynamic> json, {
    required VoteType voteType,
    required int totalVoteCount,
  }) {
    final optionVoteCount = parseInt(json['optionVoteCount']);
    final attachmentStr = parseNullableString(json['attachment']);

    return VoteOption(
      sort: parseInt(json['sort']),
      content: parseString(json['content']),
      optionVoteCount: optionVoteCount,
      // We do not inspect each option separately; the overall vote type is the source of truth.
      attachment:
          voteType == VoteType.dualImage &&
              attachmentStr != null &&
              attachmentStr != 'null'
          ? Uri.tryParse(attachmentStr)
          : null,
      percentage: totalVoteCount > 0 ? optionVoteCount / totalVoteCount : 0,
    );
  }
}

class Vote {
  final int voteId;
  final String title;
  final int userOptionLimit;
  final int userCount;
  final int voteCount;
  final bool canVote;
  final int puid;
  final List<VoteOption> options;
  final List<int>? userSelectedOptionSorts;
  // Current known usage: 1 for image vote, 0 or null for text vote.
  final int? votingType;
  // Days remaining.
  final int? deadline;
  final String endTimeStr;
  final List<UserVoteRecord> userVoteRecords;
  // Maybe always 0?
  final int voteNum;
  // Maybe always null?
  final String? votingForm;
  // Whether the vote has expired.
  final bool end;
  final VoteType type;

  const Vote({
    required this.voteId,
    required this.title,
    required this.userOptionLimit,
    required this.userCount,
    required this.voteCount,
    required this.canVote,
    required this.puid,
    required this.options,
    required this.userSelectedOptionSorts,
    required this.votingType,
    required this.deadline,
    required this.endTimeStr,
    required this.userVoteRecords,
    required this.voteNum,
    required this.votingForm,
    required this.end,
    required this.type,
  });

  bool get hasUserSelection => userSelectedOptionSorts?.isNotEmpty == true;

  bool get canCancelVote => hasUserSelection && !end;

  bool get isDualImageLayout =>
      type == VoteType.dualImage &&
      options.length == 2 &&
      options.every((option) => option.attachment != null);

  bool isOptionSelected(int sort) {
    return userSelectedOptionSorts?.contains(sort) ?? false;
  }

  factory Vote.fromJson(Map<String, dynamic> json, {required int voteId}) {
    final votingType = parseNullableInt(json['votingType']);
    final type = VoteType.fromVotingType(votingType);
    final voteCount = parseInt(json['voteCount']);
    final optionsJson = _asJsonList(json['voteDetailList']);

    return Vote(
      voteId: voteId,
      title: parseString(json['title']),
      userOptionLimit: parseInt(json['userOptionLimit']),
      userCount: parseInt(json['userCount']),
      voteCount: voteCount,
      canVote: parseBool(json['canVote']),
      puid: parseInt(json['puid']),
      options: List.unmodifiable(
        optionsJson.map(
          (item) => VoteOption.fromJson(
            item,
            voteType: type,
            totalVoteCount: voteCount,
          ),
        ),
      ),
      userSelectedOptionSorts: _parseSelectedOptions(
        json['userVoteRecordList'],
      ),
      votingType: votingType,
      deadline: parseNullableInt(json['deadline']),
      endTimeStr: parseString(json['endTimeStr']),
      // If the user has not voted, the server returns [] instead of null.
      userVoteRecords: List.unmodifiable(
        _asJsonList(json['userVoteRecordMap']).map(UserVoteRecord.fromJson),
      ),
      voteNum: parseInt(json['voteNum']),
      votingForm: parseNullableString(json['votingForm']),
      end: parseBool(json['end']),
      type: type,
    );
  }
}

List<int>? _parseSelectedOptions(Object? value) {
  if (value is! List) {
    return null;
  }

  return List.unmodifiable(value.map(parseInt));
}

List<Map<String, dynamic>> _asJsonList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map(parseMap).toList(growable: false);
}
