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

  factory Author.forReply(Map<String, dynamic> json) {
    return Author._(
      puid: json['puid'].toString(),
      name: json['puname'].toString(),
      euid: json['euid'].toString(),
      profileURL: Uri.parse(json['url']),
      avatarURL: Uri.parse(json['header']),
      adminsInfo: json['adminsInfo'],
    );
  }


  factory Author.forThread(Map<String, dynamic> json) {
    return Author._(
      puid: json['puid'].toString(),
      name: json['puname'].toString(),
      euid: json['euid'].toString(),
      profileURL: Uri.parse(json['url']),
      avatarURL: Uri.parse(json['header']),
      adminsInfo: json['adminsInfo'],
      isBlacked: json['isBlacked'] == true, 
      isAdmin: json['isAdmin'] == true,
    );
  }
}