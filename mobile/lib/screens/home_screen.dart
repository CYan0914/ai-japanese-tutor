/// Home screen — dashboard with start lesson button + phoneme profile.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lesson_state.dart';
import '../services/api_service.dart';
import '../models/tutor_response.dart';
import '../config/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PhonemeProfile? _phonemeProfile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      _phonemeProfile = await ApiService.getPhonemeProfile();
    } catch (_) {
      // Profile not available yet — show empty state
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to Sakura!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your AI Japanese pronunciation teacher',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Level + Usage row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<LessonState>(
                    builder: (_, state, __) => Chip(
                      avatar: const Icon(Icons.school, size: 16),
                      label: Text('Level: ${state.currentLevel}'),
                      backgroundColor: Colors.purple.shade50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<LessonState>(
                    builder: (_, state, __) {
                      final tier = state.usage?.tier ?? 'free';
                      final remaining =
                          state.usage?.lessonsRemaining ?? AppConstants.freeDailyLimit;
                      return Chip(
                        avatar: Icon(
                          tier == 'pro' ? Icons.star : Icons.menu_book,
                          size: 16,
                        ),
                        label: Text(
                          tier == 'pro' ? 'Unlimited' : '$remaining left',
                        ),
                        backgroundColor:
                            tier == 'pro' ? Colors.amber.shade50 : Colors.grey.shade100,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Pronunciation Profile Card ──
              _buildPhonemeCard(),
              const SizedBox(height: 16),

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
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/subscribe'),
                child: const Text('Upgrade to Pro →', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhonemeCard() {
    // Not loaded yet
    if (_loadingProfile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Loading your pronunciation profile...'),
            ],
          ),
        ),
      );
    }

    final profile = _phonemeProfile;

    // No data yet — first-time user
    if (profile == null || profile.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.mic, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No pronunciation data yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record your voice in a lesson to start building your pronunciation profile!',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Has data — show the profile
    final weakest3 = profile.phonemes.where((p) => profile.weakest.contains(p.phoneme)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, size: 18, color: Colors.pink.shade400),
                const SizedBox(width: 6),
                Text(
                  'Your Pronunciation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.pink.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profile.totalAttempts} attempts',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weakest sounds
            if (weakest3.isNotEmpty) ...[
              Text(
                'Sounds to work on:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: weakest3.map((p) {
                  final color = p.avgScore >= 80
                      ? Colors.green
                      : p.avgScore >= 50
                          ? Colors.orange
                          : Colors.red;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.phoneme,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.avgScore.round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          if (p.trend == 'improving')
                            Text('↑', style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Encouragement
            if (profile.needsPractice.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sakura recommends: practice 「${profile.needsPractice}」 next!',
                        style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tap to refresh
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _loadProfile,
                child: Icon(Icons.refresh, size: 16, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
