import 'package:bluefish/pages/mention_list_page_base.dart';
import 'package:bluefish/viewModels/mention_reply_view_model.dart';
import 'package:bluefish/widgets/mention_reply_widget.dart';
import 'package:flutter/material.dart';

class MentionReplyPage extends StatelessWidget {
  const MentionReplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MentionListPage(
      createViewModel: MentionReplyViewModel.new,
      titleIcon: Icons.alternate_email,
      title: "@我的",
      buildListSliver: (context, viewModel) => MentionReplyListWidget(
        newReplies: viewModel.newList,
        oldReplies: viewModel.oldList,
        hasNextPage: viewModel.hasNextPage,
      ),
    );
  }
}
