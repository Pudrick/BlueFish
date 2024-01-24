import 'package:flutter/material.dart';
import 'thread_list.dart';
import 'single_thread_title.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class SingleTitle extends StatelessWidget {
  final SingleThreadTitle threadTitle;

  const SingleTitle(this.threadTitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(threadTitle.title),
        Row(
          children: [
            Text(threadTitle.time),
            const SizedBox(width: 10),
            Text(threadTitle.user_name),
          ],
        )
      ],
    );
  }
}

class FirstPage extends StatelessWidget {
  final ThreadTitleList titleList;

  FirstPage(this.titleList, {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
        bottomNavigationBar: const BottomNavigation(),
        body: SafeArea(
          child: Stack(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                Flexible(
                                    child: Wrap(children: [
                                  // Text(
                                  //   title.title,

                                  // )
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
                                      style: GoogleFonts.notoSansSc(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 17,
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                      ),
                                    ),
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
                                  size: 17,
                                ),
                                Text(title.time),
                                Expanded(
                                    child: Container(
                                  height: 10,
                                )),
                                const Icon(
                                  Icons.account_circle_outlined,
                                  size: 17,
                                ),
                                Text(title.user_name,
                                    style: GoogleFonts.notoSansSc(),
                                    textAlign: TextAlign.end),
                                const SizedBox(width: 10),
                              ],
                            ),
                            const SizedBox(height: 3),
                          ],
                        ))
                ],
              ),
            ],
          ),
        ));
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

Future<void> main() async {
  ThreadTitleList titleList = ThreadTitleList.defaultList();
  await titleList.refresh();
  runApp(
    MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('zh'),
        Locale('en'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.notoSansSc().fontFamily,
        textTheme: GoogleFonts.notoSansScTextTheme(),
      ),
      home: FirstPage(titleList),
    ),
  );
}
