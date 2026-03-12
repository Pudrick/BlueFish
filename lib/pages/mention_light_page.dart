import 'package:bluefish/pages/mention_page.dart';
import 'package:flutter/material.dart';

class MentionLightPage extends StatelessWidget {
  const MentionLightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentionPage(initialTab: MentionTab.light);
  }
}
