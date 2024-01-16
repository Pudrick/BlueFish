import 'thread_list.dart';

Future<void> main() async {
  ThreadTitleList testlist = ThreadTitleList.defaultList();
  print("start refresh.");
  await testlist.refresh();
  print("refresh finished.");
  for (var threads in testlist.threadTitleList) {
    print(threads.title);
  }
}
