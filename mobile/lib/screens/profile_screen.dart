/// Profile screen — level picker, subscription, sign out.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../services/lesson_state.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPro = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPro();
  }

  Future<void> _checkPro() async {
    try {
      final pro = await SubscriptionService.isPro();
      if (mounted) setState(() { _isPro = pro; _checkingStatus = false; });
    } catch (_) {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LessonState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                    items: ['N5', 'N4', 'N3', 'N2', 'N1']
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
                        _isPro ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _checkingStatus
                            ? 'Checking...'
                            : _isPro
                                ? 'Pro  Unlimited lessons'
                                : 'Free  ${AppConstants.freeDailyLimit} lessons/day',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  if (!_isPro) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/subscribe'),
                      child: const Text('Upgrade to Pro'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From \$${AppConstants.priceMonthly.toStringAsFixed(0)}/mo · '
                      '\$${AppConstants.priceQuarterly.toStringAsFixed(0)}/quarter · '
                      '\$${AppConstants.priceYearly.toStringAsFixed(0)}/year',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
