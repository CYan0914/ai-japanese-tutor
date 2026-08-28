/// App router and theme configuration.
import 'package:flutter/material.dart';
import 'config/tokens.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/lesson_screen.dart';

class SakuraApp extends StatelessWidget {
  const SakuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakura — AI Japanese Tutor',
      debugShowCheckedModeBanner: false,
      theme: buildSakuraTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _page(const SplashScreen());
          case '/login':
            return _page(const LoginScreen());
          case '/home':
            return _page(const MainScreen());
          case '/profile':
            return _page(const ProfileScreen());
          case '/lesson':
            return _page(const LessonScreen());
          case '/subscribe':
            return _page(const SubscriptionScreen());
          default:
            return _page(const MainScreen());
        }
      },
    );
  }

  MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
