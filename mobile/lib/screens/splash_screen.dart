/// Splash screen — checks auth and navigates.
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final token = await ApiService.ensureToken();

      // Init RevenueCat with the user's ID (extracted from token or use a hash)
      try {
        // Use the first 16 chars of the token as a stable user identifier
        final userId = token.length > 16 ? token.substring(0, 16) : token;
        await SubscriptionService.init(userId);
      } catch (_) {
        // RevenueCat not configured yet — continue without it
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Sakura',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI Japanese Tutor',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
