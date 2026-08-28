/// Main scaffold with bottom navigation.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
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
  ];

  void _setTab(int idx) {
    setState(() => _tabIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
