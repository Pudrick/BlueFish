import 'package:json_annotation/json_annotation.dart';

part 'single_thread_title.g.dart';

@JsonSerializable()
class SingleThreadTitle {
  late int fid;
  late int is_gif;
  late int replys;
  late String user_name;
  late int cover_height;
  late String title;
  late int type;
  late int tid;
  late int light_replys;
  late int puid;
  late int cover_width;
  late int image_count;
  late int? zoneId; // for pinned, zoneid is null.
  late int recommends;
  late String time;
  late String? threadType;
  late int? contentType;
  bool isPinned = false;

  SingleThreadTitle();

  factory SingleThreadTitle.fromJson(Map<String, dynamic> json) =>
      _$SingleThreadTitleFromJson(json);
}
