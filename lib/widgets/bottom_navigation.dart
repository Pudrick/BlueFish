import 'package:flutter/material.dart';
import 'package:bluefish/models/thread_list.dart';
import 'package:provider/provider.dart';
import '../models/internal_settings.dart';

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
