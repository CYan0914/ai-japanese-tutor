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
            // 展开态限宽：整屏宽约 1000pt 时四个 tab 会被摊到相隔 250pt 的
            // 位置上，看着像四个孤立按钮而不是一条导航栏。560 是控件宽度上限，
            // 多出来的宽度两侧留白；白底与上边框留在外面的 Container 上，
            // 仍是整屏宽。折叠态可用宽本就不到 560，逐像素不变。
            // heightFactor 1.0：高度收缩包裹导航栏本身，宽度仍占满整屏。
            // 这里不能用 Center —— bottomNavigationBar 槽给的是松高度约束
            // （maxHeight 为整屏高），Center 会把导航栏撑满整个屏幕。
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
