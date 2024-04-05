import 'package:bluefish/models/thread_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Consumer<ThreadTitleList>(
        builder: (context, titleList, child) => DropdownMenu(
          onSelected: (sortType) {
            if (sortType != null) {
              titleList.setSortType(sortType);
            } else {
              //need to be improve.
              assert(sortType != null);
            }
          },
          label: const Text("排序方式"),
          dropdownMenuEntries: const [
            // same as tab_type, 2 for newest reply, 1 for newest publish, 4 for 24h rank, 3 for essenses
            DropdownMenuEntry(value: SortType.newestPublish, label: "最新发布"),
            DropdownMenuEntry(value: SortType.newestReply, label: "最新回复"),
          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
