import 'package:bluefish/pages/message/messages_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:flutter/material.dart';

class MentionPage extends StatelessWidget {
  final MentionTab initialTab;

  const MentionPage({super.key, this.initialTab = MentionTab.reply});

  @override
  Widget build(BuildContext context) {
    return MessagesPage(initialTab: initialTab);
  }
}
