// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_pic_peek.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadPicPeek _$ThreadPicPeekFromJson(Map<String, dynamic> json) =>
    ThreadPicPeek(
      url: json['url'] as String,
      isGif: ThreadPicPeek._intToBool(json['is_gif']),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$ThreadPicPeekToJson(ThreadPicPeek instance) =>
    <String, dynamic>{
      'url': instance.url,
      'is_gif': ThreadPicPeek._boolToInt(instance.isGif),
      'width': instance.width,
      'height': instance.height,
    };
