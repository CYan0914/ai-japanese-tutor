/// Home screen — daily greeting + phoneme snapshot + start lesson.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../services/lesson_state.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../models/tutor_response.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PhonemeProfile? _phonemeProfile;
  bool _loadingProfile = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkPro();
  }

  Future<void> _checkPro() async {
    try {
      final pro = await SubscriptionService.isPro();
      if (mounted) setState(() => _isPro = pro);
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      _phonemeProfile = await ApiService.getPhonemeProfile();
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Signature kanji watermark — 平 (hei, "calm/peace")
          Positioned(
            top: -40,
            right: -60,
            child: Text(
              '平',
              style: SakuraType.display(
                color: SakuraColors.sakuraSoft.withOpacity(0.5),
                size: 320,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SakuraSpace.l, SakuraSpace.s, SakuraSpace.l, 0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Sakura',
                          style: SakuraType.title(size: 18),
                        ),
                        const Spacer(),
                        _CircleIcon(
                          icon: Icons.person_outline,
                          semanticLabel: 'Open profile',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SakuraSpace.l,
                    vertical: SakuraSpace.l,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Greeting
                      Text(
                        '今日(きょう)は',
                        style: SakuraType.japanese(color: SakuraColors.sakura, size: 14),
                      ),
                      const SizedBox(height: SakuraSpace.s),
                      Text(
                        'Good day,',
                        style: SakuraType.caption(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sensei.',
                        style: SakuraType.display(size: 32),
                      ),
                      const SizedBox(height: SakuraSpace.l),

                      // Status row — level + tier
                      _StatusRow(isPro: _isPro),
                      const SizedBox(height: SakuraSpace.l),

                      // Pronunciation card
                      _buildPhonemeCard(),
                      const SizedBox(height: SakuraSpace.l),

                      // Primary CTA
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/lesson'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SakuraColors.sumi,
                            foregroundColor: SakuraColors.washi,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(SakuraRadius.m),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start lesson',
                                style: SakuraType.label(color: SakuraColors.washi, size: 16).copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: SakuraSpace.s),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: SakuraSpace.s),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          )),
                          child: Text(
                            'Upgrade to Pro  →',
                            style: SakuraType.label(color: SakuraColors.sakura, size: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: SakuraSpace.xl),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonemeCard() {
    if (_loadingProfile) {
      return Container(
        padding: const EdgeInsets.all(SakuraSpace.l),
        decoration: BoxDecoration(
          color: SakuraColors.white,
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          border: Border.all(color: SakuraColors.bamboo),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: SakuraColors.sakura,
              ),
            ),
            const SizedBox(width: SakuraSpace.m),
            Text('Reading your pronunciation...', style: SakuraType.body(color: SakuraColors.mist, size: 14)),
          ],
        ),
      );
    }

    final profile = _phonemeProfile;

    if (profile == null || profile.isEmpty) {
      return _emptyCard();
    }

    final weakest3 = profile.phonemes
        .where((p) => profile.weakest.contains(p.phoneme))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: SakuraColors.white,
        borderRadius: const BorderRadius.all(SakuraRadius.m),
        border: Border.all(color: SakuraColors.bamboo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.s,
            ),
            child: Row(
              children: [
                Text('YOUR SOUND', style: SakuraType.caption(size: 11).copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                Text(
                  '${profile.totalAttempts} attempts',
                  style: SakuraType.caption(size: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.l),
            child: Text(
              'Pronunciation map',
              style: SakuraType.title(size: 17),
            ),
          ),
          const SizedBox(height: SakuraSpace.m),

          // Bento grid of weakest sounds
          if (weakest3.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.m),
              child: Row(
                children: weakest3.map((p) {
                  final color = p.avgScore >= 80
                      ? SakuraColors.matcha
                      : p.avgScore >= 50
                          ? SakuraColors.kinari
                          : SakuraColors.momiji;
                  return Expanded(
                    child: Semantics(
                      label: 'Phoneme ${p.phoneme}, average score ${p.avgScore.round()}'
                          '${p.trend == 'improving' ? ', improving' : ''}',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: SakuraSpace.m),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: const BorderRadius.all(SakuraRadius.s),
                          border: Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            Text(p.phoneme, style: SakuraType.kana(color: color, size: 26)),
                            const SizedBox(height: 2),
                            Text(
                              '${p.avgScore.round()}',
                              style: SakuraType.label(color: color, size: 13).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (p.trend == 'improving')
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '↑',
                                  style: SakuraType.caption(color: SakuraColors.matcha, size: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Recommendation strip
          if (profile.needsPractice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SakuraSpace.m, SakuraSpace.m, SakuraSpace.m, 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(SakuraSpace.m),
                decoration: BoxDecoration(
                  color: SakuraColors.washiDeep,
                  borderRadius: const BorderRadius.all(SakuraRadius.s),
                ),
                child: Row(
                  children: [
                    const Text('◉', style: TextStyle(color: SakuraColors.sakura, fontSize: 12)),
                    const SizedBox(width: SakuraSpace.s),
                    Expanded(
                      child: Text(
                        'Practice ${profile.needsPractice} next',
                        style: SakuraType.body(size: 13, color: SakuraColors.sumi),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: SakuraSpace.m),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(SakuraSpace.l),
      decoration: BoxDecoration(
        color: SakuraColors.white,
        borderRadius: const BorderRadius.all(SakuraRadius.m),
        border: Border.all(color: SakuraColors.bamboo),
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: SakuraColors.washiDeep,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_none_rounded,
                color: SakuraColors.mist, size: 22),
          ),
          const SizedBox(height: SakuraSpace.m),
          Text('No pronunciation data yet', style: SakuraType.title(size: 15)),
          const SizedBox(height: SakuraSpace.xs),
          Text(
            'Record your voice in a lesson to start building your sound profile.',
            style: SakuraType.caption(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isPro;
  const _StatusRow({required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonState>(
      builder: (_, state, __) {
        final tier = state.usage?.tier ?? (isPro ? 'pro' : 'free');
        final remaining = state.usage?.lessonsRemaining ??
            (isPro ? 999 : 5);
        return Row(
          children: [
            _Pill(
              label: 'Level ${state.currentLevel}',
              fg: SakuraColors.sumi,
              bg: SakuraColors.washiDeep,
            ),
            const SizedBox(width: SakuraSpace.s),
            _Pill(
              label: tier == 'pro' ? 'Unlimited' : '$remaining left today',
              fg: tier == 'pro' ? SakuraColors.washi : SakuraColors.sumi,
              bg: tier == 'pro' ? SakuraColors.matcha : SakuraColors.washiDeep,
              icon: tier == 'pro' ? Icons.stars_rounded : Icons.menu_book_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;
  const _Pill({required this.label, required this.fg, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SakuraSpace.m, vertical: SakuraSpace.s,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(SakuraRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: SakuraType.label(color: fg, size: 12).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  const _CircleIcon({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'Open',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(SakuraRadius.pill),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: SakuraColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: SakuraColors.bamboo),
          ),
          child: Icon(icon, color: SakuraColors.sumi, size: 18),
        ),
      ),
    );
  }
}
