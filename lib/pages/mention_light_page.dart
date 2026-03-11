import 'package:bluefish/pages/mention_list_page_base.dart';
import 'package:bluefish/viewModels/mention_light_view_model.dart';
import 'package:bluefish/widgets/mention_light_widget.dart';
import 'package:flutter/material.dart';

class MentionLightPage extends StatelessWidget {
  const MentionLightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MentionListPage(
      createViewModel: MentionLightViewModel.new,
      titleIcon: Icons.thumb_up_outlined,
      title: "点亮我的",
      buildListSliver: (context, viewModel) => MentionLightListWidget(
        newLights: viewModel.newList,
        oldLights: viewModel.oldList,
        hasNextPage: viewModel.hasNextPage,
      ),
    );
  }
}
