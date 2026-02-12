import 'package:bluefish/viewModels/user_home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomeDisplaySelectWidget extends StatelessWidget {
  final VoidCallback? onTabChanged;

  const UserHomeDisplaySelectWidget({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserHomeViewModel>();

    return SegmentedButton<DisplayStatus>(
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(
          fontSize: 15
        )
      ),
      segments: const <ButtonSegment<DisplayStatus>>[
        ButtonSegment(
          value: DisplayStatus.threads,
          label: Text("主贴"),
          icon: Icon(Icons.forum_outlined),
        ),
        ButtonSegment(
          value: DisplayStatus.replies,
          label: Text("回复"),
          icon: Icon(Icons.comment_outlined),
        ),
        ButtonSegment(
          value: DisplayStatus.recommends,
          label: Text("推荐"),
          icon: Icon(Icons.recommend_outlined),
        ),
      ],
      selected: {vm.displayStatus},
      // the argument must be Set, but here is a single selection.
      onSelectionChanged: (Set<DisplayStatus> selectionSet) {
        if(vm.displayStatus != selectionSet.first) {
          vm.changeDisplayTo(selectionSet.first);
          onTabChanged?.call();
        }
      }
    );
  }
}
