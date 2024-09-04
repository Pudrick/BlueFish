import 'package:bluefish/models/single_floor.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import '../models/thread_detail.dart';

class HttpwithUA extends http.BaseClient {
  final String userAgent = '''
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36
''';
  final http.Client _inner;

  HttpwithUA(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = userAgent;
    return _inner.send(request);
  }
}

Future<Document> getHTMLFromTid(String tid) async {
  Uri threadURL = Uri.parse("https://bbs.hupu.com/$tid.html");
  var wholeThreadHTML = await HttpwithUA(http.Client()).get(threadURL);
  var threadHTML = parse(wholeThreadHTML.body);
  return threadHTML;
}

// TODO： need to rewrite
Uri getOPAvatarUri(Document threadHTML) {}

Map getOPotherInfoMap(Document threadHTML) {}

String getMainContentHTML(Document threadHTML) {}

SingleFloor getMainFloor(Document threadHTML) {
  Author OP = Author();
  OP.avatarURL = getOPAvatarUri(threadHTML);
  var infoMap = getOPotherInfoMap(threadHTML);
  OP.authorName = infoMap["ID"];
  OP.isOP = true;
  OP.profileURL = Uri.parse(infoMap["userProfileStr"]);
  SingleFloor mainFloor = SingleFloor();
  mainFloor.author = OP;
  mainFloor.postDateTime = infoMap["datetime"];
  mainFloor.postLocation = infoMap["location"];
  mainFloor.contentHTML = getMainContentHTML(threadHTML);
  return mainFloor;
}

List<SingleFloor> getLightReplyFloorList(Document threadHTML) {}

Author getReplyAuthor(Document replyHTML) {}

Uri getReplyAuthorAvatar(Element replyListContainerHTML) {}
