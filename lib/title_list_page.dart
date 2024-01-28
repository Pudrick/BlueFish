import 'package:flutter/material.dart';
import 'thread_list.dart';
import 'dart:isolate';

class TitleListPageBody extends StatefulWidget {
  ThreadTitleList titleList;
  TitleListPageBody(this.titleList, {super.key});

  @override
  State<TitleListPageBody> createState() => _TitleListPageBodyState();
}

class _TitleListPageBodyState extends State<TitleListPageBody> {
  bool loading = true;
  late ThreadTitleList titleList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ReceivePort refreshPort = ReceivePort();
    Isolate.spawn(getTitleList, [refreshPort.sendPort, widget.titleList]);
    refreshPort.listen((message) {
      setState(() {
        titleList = message;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    if (loading == true) {
      return GestureDetector(
        onVerticalDragDown: (details) {
          initState();
        },
        child: SafeArea(
            child: Stack(
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
              ),
            ),
            const Center(
              child: (CircularProgressIndicator()),
            )
          ],
        )),
      );
    } else {
      return SafeArea(
          child: (Stack(
        children: [
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
            ),
          ),
          ListView(
            children: [
              for (var title in titleList.threadTitleList)
                Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.all(5),
                  color: theme.colorScheme.secondaryContainer,
                  child: InkWell(
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
                                style: const TextStyle(fontSize: 18),
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
                          )),
                          const Icon(
                            Icons.account_circle_outlined,
                            size: 15,
                          ),
                          Text(title.user_name, textAlign: TextAlign.end),
                          const SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                  )),
                )
            ],
          ),
        ],
      )));
    }
  }
}

class ThreadListPage extends StatelessWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    ThreadTitleList titleList = ThreadTitleList.defaultList();
    return Scaffold(
        bottomNavigationBar: const BottomNavigation(),
        body: SafeArea(child: TitleListPageBody(titleList)));
  }
}

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        backgroundColor: theme.navigationBarTheme.backgroundColor,
        indicatorColor: theme.navigationBarTheme.indicatorColor,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.message),
            icon: Icon(Icons.message_outlined),
            label: 'Message',
          ),
        ]);
  }
}

void getTitleList(List<dynamic> portandList) async {
  var refreshPort = portandList[0];
  var titleList = portandList[1];
  await titleList.refresh();
  refreshPort.send(titleList);
}
