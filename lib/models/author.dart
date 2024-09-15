class Author {
  late Uri avatarURL;
  late String authorName;
  late bool isOP;
  late String puid;
  late String euid;
  late Uri profileURL; // can be formed from euid.
  late bool isBlacked;
  late bool isAdmin;

  Author(Map threadAuthorJsonMap) {
    puid = threadAuthorJsonMap["puid"];
    authorName = threadAuthorJsonMap["puname"];
    euid = threadAuthorJsonMap["euid"];
    avatarURL = Uri.parse(threadAuthorJsonMap["header"]);
    profileURL = Uri.parse(threadAuthorJsonMap["url"]);
    isBlacked = threadAuthorJsonMap["isBlacked"];
    isAdmin = threadAuthorJsonMap["isAdmin"];
  }
}
