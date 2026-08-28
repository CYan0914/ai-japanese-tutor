/// Profile screen — level picker, subscription, sign out.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/tokens.dart';
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
      body: SafeArea(
        child: Stack(
          children: [
            // Kanji watermark — 己 (self / oneself)
            Positioned(
              right: -40,
              bottom: -20,
              child: IgnorePointer(
                child: Text(
                  '己',
                  style: TextStyle(
                    fontSize: 320,
                    fontWeight: FontWeight.w300,
                    color: SakuraColors.bamboo.withOpacity(0.35),
                    height: 1,
                  ),
                ),
              ),
            ),

            ListView(
              padding: const EdgeInsets.fromLTRB(
                SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.xxxl,
              ),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: SakuraSpace.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('自分', style: SakuraType.japanese(
                        color: SakuraColors.sakura, size: 14,
                      )),
                      const SizedBox(height: 4),
                      Text('Profile', style: SakuraType.display(size: 32)),
                    ],
                  ),
                ),

                // JLPT Level
                _SectionCard(
                  title: 'JLPT Level',
                  subtitle: 'Choose your study level',
                  child: DropdownButtonFormField<String>(
                    value: state.currentLevel,
                    items: ['N5', 'N4', 'N3', 'N2', 'N1']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        state.setLevel(v);
                      }
                    },
                  ),
                ),
                const SizedBox(height: SakuraSpace.m),

                // Subscription
                _SectionCard(
                  title: 'Subscription',
                  subtitle: _checkingStatus
                      ? 'Checking...'
                      : _isPro
                          ? 'Pro · Unlimited lessons'
                          : 'Free · ${AppConstants.freeDailyLimit} lessons / day',
                  trailing: _isPro
                      ? Icon(Icons.star_rounded, color: SakuraColors.kinari, size: 22)
                      : Icon(Icons.star_outline_rounded, color: SakuraColors.stone, size: 22),
                  child: !_isPro
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: SakuraSpace.s),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/subscribe'),
                                child: Text(
                                  'Upgrade to Pro',
                                  style: SakuraType.label(size: 14, color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: SakuraSpace.s),
                            Text(
                              'From \$${AppConstants.priceMonthly.toStringAsFixed(0)} / mo · '
                              '\$${AppConstants.priceQuarterly.toStringAsFixed(0)} / quarter · '
                              '\$${AppConstants.priceYearly.toStringAsFixed(0)} / year',
                              style: SakuraType.caption(size: 11),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: SakuraSpace.m),

                // About
                _SectionCard(
                  title: 'About',
                  child: Text(
                    'Sakura AI Tutor helps you learn Japanese pronunciation '
                    'through natural conversation with an AI teacher.',
                    style: SakuraType.body(color: SakuraColors.mist, size: 14),
                  ),
                ),
                const SizedBox(height: SakuraSpace.xl),

                // Sign out
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ApiService.clearToken();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                      }
                    },
                    child: Text(
                      'Sign Out',
                      style: SakuraType.label(
                        color: SakuraColors.sakura,
                        size: 14,
                      ).copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SakuraSpace.l),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered section card — consistent profile layout.
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SakuraSpace.m),
      decoration: BoxDecoration(
        color: SakuraColors.white,
        borderRadius: const BorderRadius.all(SakuraRadius.m),
        border: Border.all(color: SakuraColors.bamboo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: SakuraType.title(size: 15)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: SakuraType.caption(size: 12)),
          ],
          if (child != null) child!,
        ],
      ),
    );
  }
}
