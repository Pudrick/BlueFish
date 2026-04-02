import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bluefish/viewModels/thread_list_view_model.dart';

import 'package:bluefish/widgets/thread/thread_list_body.dart';
import 'package:bluefish/widgets/thread/top_bar.dart';

class ThreadListPage extends StatelessWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThreadListViewModel>(
      create: (context) => ThreadListViewModel.defaultList(),
      child: Scaffold(
        body: const SafeArea(child: TitleListPageBody()),
        appBar: const TopBar(),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Implement create-thread flow.
            },
            tooltip: '发表新主贴',
            elevation: 0,
            child: const Icon(Icons.edit_outlined, size: 20),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        //TODO: add a drawer
      ),
    );
  }
}
