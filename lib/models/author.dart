import 'package:bluefish/models/model_parsing.dart';

class Author {
  final String name;
  final String puid;
  final String euid;
  final Uri avatarURL;
  final Uri profileURL;

  final bool isBlacked;
  final bool isAdmin;
  final String? adminsInfo;

  Author._({
    required this.name,
    required this.puid,
    required this.euid,
    required this.avatarURL,
    required this.profileURL,
    this.isBlacked = false,
    this.isAdmin = false,
    this.adminsInfo,
  });

  factory Author.forReply(
    Map<String, dynamic> json, {
    bool isBlacked = false,
    bool isAdmin = false,
  }) {
    return Author._(
      puid: parseString(json['puid']),
      name: parseString(json['puname']),
      euid: parseString(json['euid']),
      profileURL: Uri.parse(parseString(json['url'])),
      avatarURL: Uri.parse(parseString(json['header'])),
      adminsInfo: json['adminsInfo'],
      isBlacked: isBlacked,
      isAdmin: isAdmin,
    );
  }

  factory Author.forThread(Map<String, dynamic> json) {
    return Author._(
      puid: parseString(json['puid']),
      name: parseString(json['puname']),
      euid: parseString(json['euid']),
      profileURL: Uri.parse(parseString(json['url'])),
      avatarURL: Uri.parse(parseString(json['header'])),
      adminsInfo: json['adminsInfo'],
      isBlacked: parseBool(json['isBlacked']),
      isAdmin: parseBool(json['isAdmin']),
    );
  }
}
