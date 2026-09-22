import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/ios_tab_bar.dart';
import 'home_screen.dart';
import 'scores_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  /// Global key so screens deep in the navigation stack (e.g. ScoringScreen)
  /// can jump back to a specific tab instead of just popping to whatever
  /// pushed them.
  static final GlobalKey<HomeShellState> shellKey = GlobalKey<HomeShellState>();

  HomeShell() : super(key: shellKey);

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ScoresScreenState> _scoresKey =
      GlobalKey<ScoresScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    ScoresScreen(key: _scoresKey),
    const ProfileScreen(),
  ];

  // Each tab screen stays mounted (IndexedStack), so nothing refetches on
  // its own when the user switches back to it — force that here instead.
  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
      case 1:
        _scoresKey.currentState?.refreshCurrent();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _refreshTab(index);
  }

  /// Switches to the given tab and refreshes it, used when returning from a
  /// pushed screen (e.g. after scoring a round).
  void showTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _refreshTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: IosTabBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          IosTabDestination(
            icon: CupertinoIcons.house,
            selectedIcon: CupertinoIcons.house_fill,
            label: 'Home',
          ),
          IosTabDestination(icon: CupertinoIcons.scope, label: 'Scores'),
          IosTabDestination(
            icon: CupertinoIcons.person,
            selectedIcon: CupertinoIcons.person_fill,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
