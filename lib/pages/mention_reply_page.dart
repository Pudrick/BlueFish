import 'package:bluefish/pages/mention_page.dart';
import 'package:flutter/material.dart';

class MentionReplyPage extends StatelessWidget {
  const MentionReplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentionPage(initialTab: MentionTab.reply);
  }
}
