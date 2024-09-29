class Author {
  late Uri avatarURL;
  late String name;
  bool isOP = false;
  late String puid;
  late String euid;
  late Uri profileURL; // can be formed from euid.
  late bool isBlacked;
  late bool isAdmin; // maybe always false for anyone? mods is false either.
  String? adminsInfo;

  factory Author.createThreadAuthor(Map threadAuthorJsonMap) {
    var simplyAuthor = Author.createReplyAuthor(threadAuthorJsonMap);
    simplyAuthor.isBlacked = threadAuthorJsonMap["isBlacked"];
    simplyAuthor.isAdmin = threadAuthorJsonMap["isAdmin"];
    return simplyAuthor;
  }

  factory Author.createReplyAuthor(Map threadAuthorJsonMap) {
    var simplyAuthor = Author.createQuoteAuthor(threadAuthorJsonMap);
    simplyAuthor.avatarURL = Uri.parse(threadAuthorJsonMap["header"]);
    if (threadAuthorJsonMap.containsKey("adminsInfo")) {
      simplyAuthor.adminsInfo = threadAuthorJsonMap["adminsInfo"];
    }
    return simplyAuthor;
  }

  Author.createQuoteAuthor(Map threadAuthorJsonMap) {
    puid = threadAuthorJsonMap["puid"];
    name = threadAuthorJsonMap["puname"];
    euid = threadAuthorJsonMap["euid"];
    profileURL = Uri.parse(threadAuthorJsonMap["url"]);
  }
}
