import 'thread_list.dart';

Future<void> main() async {
  ThreadTitleList testlist = ThreadTitleList.defaultList();
  for (var threads in testlist.threadTitleList) {
    print(threads.title);
  }
}
