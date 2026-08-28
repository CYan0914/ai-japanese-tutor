/// Login screen — quiet landing, just an entry.
import 'package:flutter/material.dart';
import '../config/tokens.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Kanji watermark — 春 (haru, spring)
          Positioned(
            top: -60,
            right: -80,
            child: Text(
              '春',
              style: SakuraType.display(
                color: SakuraColors.sakuraSoft.withOpacity(0.6),
                size: 380,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  // Eyebrow — Japanese tagline
                  Text(
                    '日本語を話す',
                    style: SakuraType.japanese(color: SakuraColors.sakura, size: 16),
                  ),
                  const SizedBox(height: SakuraSpace.m),
                  // Display
                  Text(
                    'Sakura',
                    style: SakuraType.display(size: 48),
                  ),
                  const SizedBox(height: SakuraSpace.s),
                  Text(
                    'Your AI pronunciation tutor.\nLearn to speak Japanese with confidence.',
                    style: SakuraType.body(color: SakuraColors.mist, size: 16),
                  ),
                  const Spacer(flex: 3),
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                      child: const Text(
                        'Begin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: SakuraSpace.m),
                  Center(
                    child: Text(
                      'No account needed',
                      style: SakuraType.caption(),
                    ),
                  ),
                  const SizedBox(height: SakuraSpace.l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
