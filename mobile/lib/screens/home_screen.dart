/// Home screen — dashboard with start lesson button.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lesson_state.dart';
import '../config/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakura'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Sakura!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI Japanese pronunciation teacher',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Level badge
              Consumer<LessonState>(
                builder: (_, state, __) => Chip(
                  avatar: const Icon(Icons.school, size: 18),
                  label: Text('Level: ${state.currentLevel}'),
                  backgroundColor: Colors.purple.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Lesson counter
              Consumer<LessonState>(
                builder: (_, state, __) {
                  final tier = state.usage?.tier ?? 'free';
                  final remaining = state.usage?.lessonsRemaining ?? AppConstants.freeDailyLimit;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            tier == 'pro' ? Icons.star : Icons.menu_book,
                            color: tier == 'pro' ? Colors.amber : Colors.pink,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tier == 'pro'
                                ? 'Unlimited lessons'
                                : '$remaining of ${AppConstants.freeDailyLimit} lessons today',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (tier == 'free')
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/subscribe'),
                              child: const Text('Upgrade to Pro →'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Start Lesson',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
