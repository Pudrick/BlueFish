import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/model_parsing.dart';

enum PostClient {
  android,
  iphone,
  pc,
  unknown;

  static PostClient fromRaw(Object? value) {
    return switch (parseString(value).toUpperCase()) {
      'ANDROID' => PostClient.android,
      'IPHONE' => PostClient.iphone,
      'PC' => PostClient.pc,
      _ => PostClient.unknown,
    };
  }
}

class FloorMeta {
  final Author author;
  // This can be inferred from postTime, but the server also returns a readable label.
  final String postTimeReadable;
  final DateTime postTime;
  final String postLocation;
  final PostClient client;

  const FloorMeta({
    required this.author,
    required this.postTimeReadable,
    required this.postTime,
    required this.postLocation,
    required this.client,
  });

  factory FloorMeta.fromJson(
    Map<String, dynamic> json, {
    required Author author,
  }) {
    return FloorMeta(
      author: author,
      postTimeReadable: parseString(json['createdAtFormat']),
      postTime: parseDateTimeFromMilliseconds(json['createdAt']),
      postLocation: parseString(json['location']),
      client: PostClient.fromRaw(json['client']),
    );
  }
}
