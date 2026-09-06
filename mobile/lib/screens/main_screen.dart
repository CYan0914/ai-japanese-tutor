/// Main scaffold with bottom navigation.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'lesson_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    LearnScreen(),
    LessonScreen(),
    AccountScreen(),
  ];

  void _setTab(int idx) {
    setState(() => _tabIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _LazyIndexedStack(
        index: _tabIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SakuraColors.white,
          border: Border(
            top: BorderSide(color: SakuraColors.bamboo, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: _setTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: SakuraColors.white,
              selectedItemColor: SakuraColors.sakura,
              unselectedItemColor: SakuraColors.stone,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.cottage_outlined),
                  activeIcon: Icon(Icons.cottage_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book_rounded),
                  label: 'Learn',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Tutor',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LazyIndexedStack — only inserts a tab into the tree the first time it
/// becomes the active tab. Off-screen tabs are kept in memory once shown
/// so state (scroll position, in-flight requests) is preserved across
/// tab switches, but their initState only runs when they're first shown.
///
/// This is the same pattern Flutter 3.32+ provides as `LazyIndexedStack`
/// in the framework, but we hand-roll it here because the project is on
/// Flutter 3.29.2. Once we upgrade past 3.32, replace this with the
/// built-in.
class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({required this.index, required this.children});

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _shown = List<bool>.filled(
    widget.children.length,
    false,
    growable: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.index < _shown.length) {
      _shown[widget.index] = true;
    }
  }

  @override
  void didUpdateWidget(covariant _LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index && widget.index < _shown.length) {
      _shown[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: _shown[i] ? widget.children[i] : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
