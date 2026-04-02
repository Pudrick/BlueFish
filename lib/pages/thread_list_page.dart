import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/viewModels/thread_list_view_model.dart';

import 'package:bluefish/widgets/thread/thread_list_body.dart';
import 'package:bluefish/widgets/thread/top_bar.dart';

class ThreadListPage extends StatelessWidget {
  final ThreadListViewModel? viewModel;

  const ThreadListPage({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      body: const SafeArea(child: TitleListPageBody()),
      appBar: const TopBar(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          key: const ValueKey('thread_list_create_thread_fab'),
          onPressed: () {
            context.pushCreateThread();
          },
          tooltip: '发表新主贴',
          elevation: 0,
          child: const Icon(Icons.edit_outlined, size: 20),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      //TODO: add a drawer
    );

    final currentViewModel = viewModel;
    if (currentViewModel != null) {
      return ChangeNotifierProvider<ThreadListViewModel>.value(
        value: currentViewModel,
        child: child,
      );
    }

    return ChangeNotifierProvider<ThreadListViewModel>(
      create: (context) => ThreadListViewModel.defaultList(),
      child: child,
    );
  }
}
