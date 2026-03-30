import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bluefish/models/thread_list.dart';

import 'package:bluefish/widgets/thread/thread_list_body.dart';
import 'package:bluefish/widgets/thread/top_bar.dart';

class ThreadListPage extends StatelessWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ThreadTitleList titleList = ThreadTitleList.defaultList();
    return ChangeNotifierProvider(
      create: (context) => ThreadTitleList.defaultList(),
      child: const Scaffold(
        body: SafeArea(child: TitleListPageBody()),
        appBar: TopBar(),
        //TODO: add a drawer
      ),
    );
  }
}
