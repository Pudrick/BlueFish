import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'single_thread.dart';

const bbsUrl = 'https://bbs.hupu.com';
const topicIDHI3 = 788;

class ThreadList {
  List<SingleThread> threadList = List.empty(growable: true);

  var page = 1;
  var sort = "";

  void refresh() async {
    var elementList = listRequest();
    parseList(await elementList);
  }

  Future<List<Element>> listRequest() async {
    var fullUrl = '$bbsUrl/$topicIDHI3-$page';
    var url = Uri.parse(fullUrl);
    var response = await http.get(url);
    var dom = html.parse(response.body);
    var divList = dom.querySelectorAll('.bbs-sl-web-post-layout');
    return divList;
  }

  void parseList(List<Element> divList) {
    if (divList[0].className != "bbs-sl-web-post-layout") divList.removeAt(0);
    //remove the first node contains no threads
    for (var element in divList) {
      parseThreadElement(element);
    }
  }

  void parseThreadElement(Element threadElement)
  // div title
  //    a link
  //    svg light
  //    pagelist
  // div reply/skim
  // div author
  //    a link to author
  // div time
  {
    SingleThread newThread = SingleThread();
    threadList.add(newThread);
    parseTitleDiv(threadElement.getElementsByClassName('post-title'));
    parseReplyReadDiv(threadElement.getElementsByClassName("post-datum"));
    parseAuthorDiv(threadElement.getElementsByClassName("post-auth"));
    parsePosttimeDiv(threadElement.getElementsByClassName("post-time"));
  }

  void parseTitleDiv(List<Element> parentTitleDivList) {
    // the length of titleDivList is 1
    assert(parentTitleDivList.length == 1);
    var titleDivList = parentTitleDivList[0].children;
    for (var element in titleDivList) {
      if (element.className == 'light-icon') {
        threadList.last.isLighted = true;
        continue;
      }
      if (element.className == 'page-icon') {
        threadList.last.hasPageList = true;
        continue;
      }
      threadList.last.title = element.text;
      var threadID = element.attributes["href"];
      threadList.last.titleLink = Uri.parse("$bbsUrl$threadID");
    }
  }

  void parseReplyReadDiv(List<Element> parentRRDivList) {
    // the length of List is always 1
    assert(parentRRDivList.length == 1);
    var replyRead = parentRRDivList.first.text.split('/');
    var reply = replyRead[0];
    var read = replyRead[1];
    threadList.last.reply = int.parse(reply);
    threadList.last.read = int.parse(read);
  }

  void parseAuthorDiv(List<Element> parentAuthorList) {
    assert(parentAuthorList.length == 1);
    var authorDiv = parentAuthorList.first.firstChild;
    threadList.last.author = authorDiv!.text!;
    threadList.last.authorLink = Uri.parse(authorDiv.attributes["href"]!);
  }

  void parsePosttimeDiv(List<Element> parentPosttimeList) {
    assert(parentPosttimeList.length == 1);
    threadList.last.postTime = parentPosttimeList.first.text;
  }
}
