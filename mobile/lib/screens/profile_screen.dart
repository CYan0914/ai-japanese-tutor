/// Profile screen — level picker, subscription, sign out.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lesson_state.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LessonState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // JLPT Level
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JLPT Level',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: state.currentLevel,
                    items: _levels
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        state.setLevel(v);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subscription
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        state.usage?.isPro == true
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.usage?.isPro == true ? 'Pro' : 'Free',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  if (state.usage?.isPro != true) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/subscribe'),
                      child: const Text('Upgrade to Pro - \$9.99/mo'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // About
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sakura AI Tutor helps you learn Japanese pronunciation '
                    'through natural conversation with an AI teacher.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Sign out
          TextButton(
            onPressed: () async {
              await ApiService.clearToken();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
