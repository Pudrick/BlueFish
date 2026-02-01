import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/author_homepage/author_home.dart';
import 'package:bluefish/models/author_homepage/author_home_thread_list.dart';
import 'package:bluefish/models/author_homepage/author_home_thread_title.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

// TODO: change the import to cookie-free version temporarily.
import './http_with_ua_coke.dart';

String getAuthorDataFromScripts(List<Element> scripts) {
  for (final script in scripts) {
    final text = script.text.trim();
    if (!text.startsWith('window.\$\$data')) continue;
    final eqIndex = text.indexOf('=');
    if (eqIndex == -1) continue;

    var value = text.substring(eqIndex + 1).trim();

    // remove ';' in the tail.
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
  if (response.statusCode != 200) {
    throw const HttpException("Failed to get http response.");
  }

  final threadHTML = parse(response.body);
  final scripts = threadHTML.getElementsByTagName('script');
  final authorInfoStr = getAuthorDataFromScripts(scripts);

  // now the threads in authorHome is empty, need implement later.
  final authorHome = AuthorHome.authorHomeFromJson(jsonDecode(authorInfoStr));
  await authorHome.threads.loadNextPageThreads();
  return authorHome;
}
