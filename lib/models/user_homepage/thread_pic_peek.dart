import 'package:json_annotation/json_annotation.dart';

part 'thread_pic_peek.g.dart';

@JsonSerializable()
class ThreadPicPeek {
  final String url;

  @JsonKey(name: 'is_gif', fromJson: _intToBool, toJson: _boolToInt)
  final bool isGif;

  final int width;
  final int height;

  const ThreadPicPeek({
    required this.url,
    required this.isGif,
    required this.width,
    required this.height,
  });

  factory ThreadPicPeek.fromJson(Map<String, dynamic> json)
      => _$ThreadPicPeekFromJson(json);

  Map<String, dynamic> toJson()
      => _$ThreadPicPeekToJson(this);

  static bool _intToBool(dynamic value) => value == 1;
  static int _boolToInt(bool value) => value ? 1 : 0;
}
