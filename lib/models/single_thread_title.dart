import 'package:json_annotation/json_annotation.dart';

part 'single_thread_title.g.dart';

@JsonSerializable()
class SingleThreadTitle {
  final int fid;

  @JsonKey(name: 'is_gif')
  final int isGifInt;
  bool get isGif => isGifInt == 1;

  @JsonKey(name: 'replys')
  final int repliesNum;

  @JsonKey(name: 'user_name')
  final String authorName;

  @JsonKey(name: 'cover_height')
  final int coverHeight;

  final String title;
  final int type;
  final int tid;

  @JsonKey(name: 'light_replys')
  final int lightRepliesNum;

  final int puid;

  @JsonKey(name: 'cover_width')
  final int coverWidth;

  @JsonKey(name: 'image_count')
  final int imageCount;

  // For pinned threads, zoneId is null.
  final int? zoneId;
  final int recommends;
  final String time;
  final String? threadType;
  final int? contentType;
  final bool? isPinned;

  const SingleThreadTitle({
    required this.fid,
    required this.isGifInt,
    required this.repliesNum,
    required this.authorName,
    required this.coverHeight,
    required this.title,
    required this.type,
    required this.tid,
    required this.lightRepliesNum,
    required this.puid,
    required this.coverWidth,
    required this.imageCount,
    this.zoneId,
    required this.recommends,
    required this.time,
    this.threadType,
    this.contentType,
    this.isPinned,
  });

  factory SingleThreadTitle.fromJson(Map<String, dynamic> json) =>
      _$SingleThreadTitleFromJson(json);

  Map<String, dynamic> toJson() => _$SingleThreadTitleToJson(this);
}
