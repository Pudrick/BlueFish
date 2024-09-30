import 'package:html/parser.dart';

class Video {
  late Uri source;
  late String sourceStr;
  late Uri cover;
  late String coverStr;
  late int height;
  late int width;
  late int duration;

  List<Video> getVideoListFromContent(String htmlStr) {
    // need attributes: src, data-img data-height data-width
    // maybe not useful : data-time
    List<Video> res = List.empty(growable: true);
    var htmlDoc = parse(htmlStr);
    var rawList = htmlDoc.getElementsByTagName("video");
    for (var rawVideo in rawList) {
      var newvid = Video();
      newvid.cover = Uri.parse(rawVideo.attributes["data-img"]!);
      newvid.coverStr = cover.toString();
      newvid.duration = int.tryParse(rawVideo.attributes["data-time"]!)!;
      newvid.height = int.tryParse(rawVideo.attributes["data-height"]!)!;
      newvid.width = int.tryParse(rawVideo.attributes["data-width"]!)!;
      newvid.source = Uri.parse(rawVideo.attributes["src"]!);
      newvid.sourceStr = source.toString();
      res.add(newvid);
    }
    return res;
  }

  String createVidTag() {
    return "<video src=$sourceStr></video>";
  }
}
