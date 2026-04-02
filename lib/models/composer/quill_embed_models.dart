import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

const String bluefishDetailsEmbedType = 'bluefish-details';
const String bluefishImagePlaceholderEmbedType = 'bluefish-image-placeholder';

@immutable
class BluefishDetailsEmbedData {
  final String summary;
  final String body;
  final bool initiallyExpanded;

  const BluefishDetailsEmbedData({
    required this.summary,
    required this.body,
    this.initiallyExpanded = false,
  });

  factory BluefishDetailsEmbedData.initial() {
    return const BluefishDetailsEmbedData(
      summary: '补充说明',
      body: '这里可以填写需要折叠展示的补充内容。',
    );
  }

  factory BluefishDetailsEmbedData.fromJson(Map<String, dynamic> json) {
    return BluefishDetailsEmbedData(
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      initiallyExpanded: json['initiallyExpanded'] as bool? ?? false,
    );
  }

  factory BluefishDetailsEmbedData.fromJsonString(String jsonString) {
    return BluefishDetailsEmbedData.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
    );
  }

  bool get hasContent => summary.trim().isNotEmpty || body.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary,
      'body': body,
      'initiallyExpanded': initiallyExpanded,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  BluefishDetailsEmbedData copyWith({
    String? summary,
    String? body,
    bool? initiallyExpanded,
  }) {
    return BluefishDetailsEmbedData(
      summary: summary ?? this.summary,
      body: body ?? this.body,
      initiallyExpanded: initiallyExpanded ?? this.initiallyExpanded,
    );
  }
}

class BluefishDetailsEmbed extends quill.Embeddable {
  BluefishDetailsEmbed(BluefishDetailsEmbedData data)
    : super(bluefishDetailsEmbedType, data.toJsonString());

  BluefishDetailsEmbedData get embedData =>
      BluefishDetailsEmbedData.fromJsonString(data as String);
}

@immutable
class BluefishImagePlaceholderEmbedData {
  final String attachmentId;
  final String label;
  final String? caption;
  final String? sourceUrl;

  const BluefishImagePlaceholderEmbedData({
    required this.attachmentId,
    required this.label,
    this.caption,
    this.sourceUrl,
  });

  factory BluefishImagePlaceholderEmbedData.fromJson(
    Map<String, dynamic> json,
  ) {
    return BluefishImagePlaceholderEmbedData(
      attachmentId: json['attachmentId']?.toString() ?? '',
      label: json['label']?.toString() ?? '图片占位',
      caption: json['caption']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }

  factory BluefishImagePlaceholderEmbedData.fromJsonString(String jsonString) {
    return BluefishImagePlaceholderEmbedData.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'attachmentId': attachmentId,
      'label': label,
      'caption': caption,
      'sourceUrl': sourceUrl,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  BluefishImagePlaceholderEmbedData copyWith({
    String? label,
    String? caption,
    String? sourceUrl,
  }) {
    return BluefishImagePlaceholderEmbedData(
      attachmentId: attachmentId,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }
}

class BluefishImagePlaceholderEmbed extends quill.Embeddable {
  BluefishImagePlaceholderEmbed(BluefishImagePlaceholderEmbedData data)
    : super(bluefishImagePlaceholderEmbedType, data.toJsonString());

  BluefishImagePlaceholderEmbedData get embedData =>
      BluefishImagePlaceholderEmbedData.fromJsonString(data as String);
}
