import 'package:bluefish/models/thread_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TitleListPageBody extends StatelessWidget {
  const TitleListPageBody({super.key});

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
