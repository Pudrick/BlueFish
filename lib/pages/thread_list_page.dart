import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'thread_list.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class TitleListPageBody extends StatefulWidget {
  final ThreadTitleList titleList;
  const TitleListPageBody(this.titleList, {super.key});

  @override
  State<TitleListPageBody> createState() => _TitleListPageBodyState();
}

class _TitleListPageBodyState extends State<TitleListPageBody> {
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Consumer<ThreadTitleList>(
      builder: (context, titleList, child) {
        if (titleList.isRefreshing == true) {
          return SafeArea(
              child: Stack(
            children: [
              Container(
                color: theme.colorScheme.surface,
              ),
              const Center(
                child: (CircularProgressIndicator()),
              )
            ],
          ));
        } else {
          return SafeArea(
              child: (Stack(
            children: [
              Container(
                color: theme.colorScheme.background,
              ),
              RefreshIndicator(
                onRefresh: () => Future(() {
                  // refreshTitleList();
                  titleList.refresh();
                }),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    for (var title in titleList.threadTitleList)
                      Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.all(5),
                        color: theme.colorScheme.secondaryContainer,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              splashFactory: InkRipple.splashFactory,
                              onTap: () {},
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      Flexible(
                                          child: Wrap(children: [
                                        Text.rich(TextSpan(children: [
                                          if (title.isPinned == true)
                                            const WidgetSpan(
                                                child: Icon(
                                              Icons.push_pin,
                                              size: 18,
                                              color: Colors.red,
                                            )),
                                          TextSpan(
                                            text: title.title,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                          if (title.threadType == "video")
                                            const WidgetSpan(
                                                child: Icon(
                                              Icons.smart_display,
                                              size: 18,
                                            ))
                                          else if (title.threadType == "vote")
                                            const WidgetSpan(
                                                child: Icon(
                                              Icons.bar_chart,
                                              size: 18,
                                            ))
                                        ]))
                                      ])),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Stack(children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 15,
                                        ),
                                        Text(title.time),
                                        Expanded(
                                          child: Container(
                                            height: 10,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 10,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.account_circle_outlined,
                                          size: 15,
                                        ),
                                        Text(title.user_name,
                                            textAlign: TextAlign.end),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                    Center(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.thumb_up_alt_outlined,
                                          size: 15,
                                        ),
                                        Text(title.recommends.toString()),
                                        const Text("/"),
                                        const Icon(
                                          Icons.comment_outlined,
                                          size: 15,
                                        ),
                                        Text(title.replys.toString()),
                                      ],
                                    )),
                                  ]),
                                  const SizedBox(height: 3),
                                ],
                              )),
                        ),
                      )
                  ],
                ),
              ),
            ],
          )));
        }
      },
    );
  }
}

class ThreadListPage extends StatelessWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    ThreadTitleList titleList = ThreadTitleList.defaultList();
    return ChangeNotifierProvider(
      create: (context) => ThreadTitleList.defaultList(),
      child: Scaffold(
        bottomNavigationBar: const BottomNavigation(),
        body: SafeArea(child: TitleListPageBody(titleList)),
        appBar: const TopBar(),
        //TODO: add a drawer
      ),
    );
  }
}

// TODO:
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

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<ThreadTitleList>(
      builder: (context, titleList, child) => NavigationBar(
          onDestinationSelected: (int index) {
            currentIndex = index;
            switch (index) {
              case 0:
                titleList.setZoneID(mainZoneID);
                break;
              case 1:
                titleList.setZoneID(theaterZoneID);
                break;
            }
          },
          backgroundColor: theme.navigationBarTheme.backgroundColor,
          indicatorColor: theme.navigationBarTheme.indicatorColor,
          selectedIndex: currentIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: '主版',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.message),
              icon: Icon(Icons.message_outlined),
              label: 'Message',
            ),
          ]),
    );
  }
}
