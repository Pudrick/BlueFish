import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:bluefish/viewModels/author_home_view_model.dart';
import 'package:bluefish/widgets/user_home_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomePage extends StatelessWidget {
  final int euid;
  const UserHomePage({super.key, required this.euid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthorHomeViewModel>(
      create: (_) => AuthorHomeViewModel(euid: euid)..init(),
      child: const UserHomePageView(),);
  }
}

class UserHomePageView extends StatelessWidget {
  const UserHomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthorHomeViewModel>();

    if(viewModel.data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    UserHome data = viewModel.data!;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(2),
            sliver: SliverToBoxAdapter(
              child: UserHomeInfoWidget(userHome: data),
            ),
            )
        ],
      ));
  }
}