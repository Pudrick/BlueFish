import 'dart:async';
import 'dart:convert';

import 'package:bluefish/models/author_homepage/author_home.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import './http_with_ua_coke.dart';

String getAuthorDataFromScripts(List<Element> scripts) {
  for (final script in scripts) {
    final text = script.text.trim();
    if (!text.startsWith('window.\$\$data')) continue;
    final eqIndex = text.indexOf('=');
    if (eqIndex == -1) continue;

    var value = text.substring(eqIndex + 1).trim();

    // 去掉结尾的 ;
    if (value.endsWith(';')) {
      value = value.substring(0, value.length - 1);
    }

    return value;
  }
  throw const FormatException('window.\$\$data not found in <script>');
}

Future<AuthorHome> getAuthorHomeByEuid(dynamic euid) async {
  if (euid is int) euid = euid.toString();
  Uri homepageUrl = Uri.parse("https://my.hupu.com/$euid");
  var response = await HttpwithUA().get(homepageUrl);
  if (response.statusCode == 200) {
    final threadHTML = parse(response.body);
    final scripts = threadHTML.getElementsByTagName('script');
    final authorInfoStr = getAuthorDataFromScripts(scripts);
    final authorHome = AuthorHome.authorHomeFromJson(jsonDecode(authorInfoStr));
    return authorHome;
  } else {
    throw TimeoutException("Failed to get http response.");
  }
}
