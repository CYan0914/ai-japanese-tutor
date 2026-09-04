/// Subscription screen — RevenueCat-powered IAP with 3 pricing tiers.
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../config/tokens.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Package data from RevenueCat
  List<Package> _packages = [];
  Offering? _offering;
  bool _loading = true;
  String? _error;

  // Purchase state
  bool _purchasing = false;
  bool _restoring = false;

  // Currently selected package (for visual highlight before purchase)
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offering = await SubscriptionService.getCurrentOffering();
      if (!mounted) return;
      if (offering != null && offering.availablePackages.isNotEmpty) {
        setState(() {
          _offering = offering;
          _packages = offering.availablePackages;
          _loading = false;
        });
      } else {
        // Fallback: create synthetic packages from our constant product IDs
        // so the UI is still usable even if RevenueCat offerings aren't set up.
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Find a package by its RevenueCat [PackageType].
  Package? _packageByType(PackageType type) {
    try {
      return _packages.firstWhere((p) => p.packageType == type);
    } catch (_) {
      return null;
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _selectedPackage = package;
      _purchasing = true;
    });
    try {
      final info = await SubscriptionService.purchasePackage(package);
      final isPro =
          info.entitlements.all[AppConstants.entitlementPro]?.isActive == true;

      // Sync subscription status to the backend
      try {
        await ApiService.syncSubscription(
          productId: package.identifier,
          isPro: isPro,
        );
      } catch (_) {
        // Non-critical — purchase succeeded even if sync fails
      }

      if (!mounted) return;

      if (isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome to Sakura Pro. Enjoy unlimited lessons.',
              style: SakuraType.body(color: Colors.white, size: 14),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Purchase completed but Pro could not be verified. Please contact support.',
              style: SakuraType.body(color: Colors.white, size: 14),
            ),
            backgroundColor: SakuraColors.momiji,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // User cancelled or payment failed — show nothing for cancellation
      if (e.toString().contains('UserCancelled')) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final info = await SubscriptionService.restorePurchases();
      final isPro =
          info.entitlements.all[AppConstants.entitlementPro]?.isActive == true;

      // Sync to backend
      try {
        await ApiService.syncSubscription(
          productId: 'restored',
          isPro: isPro,
        );
      } catch (_) {}

      if (!mounted) return;

      if (isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Purchases restored. Welcome back to Pro.',
              style: SakuraType.body(color: Colors.white, size: 14),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No previous purchases found.',
              style: SakuraType.body(color: Colors.white, size: 14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakura Pro'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: SakuraColors.sakura,
                strokeWidth: 2,
              ),
            )
          : _error != null && _packages.isEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SakuraSpace.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: SakuraColors.stone),
            const SizedBox(height: SakuraSpace.m),
            Text(
              'Unable to load subscription options.',
              textAlign: TextAlign.center,
              style: SakuraType.body(color: SakuraColors.mist),
            ),
            const SizedBox(height: SakuraSpace.m),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: const Text('Retry'),
            ),
            const SizedBox(height: SakuraSpace.s),
            Text(
              'Make sure RevenueCat is configured in App Store Connect.',
              textAlign: TextAlign.center,
              style: SakuraType.caption(size: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // RevenueCat packages loaded (matched by PackageType on the offering)
    final monthly = _packageByType(PackageType.monthly);
    final quarterly = _packageByType(PackageType.threeMonth);
    final yearly = _packageByType(PackageType.annual);

    return Stack(
      children: [
        // Watermark — 桜
        Positioned(
          right: -60,
          top: 40,
          child: IgnorePointer(
            child: Text(
              '桜',
              style: TextStyle(
                fontSize: 360,
                fontWeight: FontWeight.w300,
                color: SakuraColors.sakura.withOpacity(0.05),
                height: 1,
              ),
            ),
          ),
        ),

        ListView(
          padding: const EdgeInsets.fromLTRB(
            SakuraSpace.l, SakuraSpace.l, SakuraSpace.l, SakuraSpace.xl,
          ),
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('桜', style: SakuraType.japanese(
                  color: SakuraColors.sakura, size: 16,
                )),
                const SizedBox(height: 4),
                Text('Sakura Pro', style: SakuraType.display(size: 32)),
                const SizedBox(height: SakuraSpace.s),
                Text(
                  '${AppConstants.freeDailyLimit} free lessons a day. '
                  'Pro removes the limit.',
                  style: SakuraType.body(color: SakuraColors.mist, size: 14),
                ),
              ],
            ),
            const SizedBox(height: SakuraSpace.xl),

            // ── 3 pricing tiers ──
            _buildTierCard(
              label: 'Monthly',
              price: '\$${AppConstants.priceMonthly.toStringAsFixed(2)}',
              period: '/ month',
              productId: AppConstants.productMonthly,
              package: monthly,
              badge: null,
            ),
            const SizedBox(height: SakuraSpace.s),

            _buildTierCard(
              label: 'Quarterly',
              price: '\$${AppConstants.priceQuarterly.toStringAsFixed(2)}',
              period: '/ quarter',
              productId: AppConstants.productQuarterly,
              package: quarterly,
              badge: 'SAVE 33%',
            ),
            const SizedBox(height: SakuraSpace.s),

            _buildTierCard(
              label: 'Yearly',
              price: '\$${AppConstants.priceYearly.toStringAsFixed(2)}',
              period: '/ year',
              productId: AppConstants.productYearly,
              package: yearly,
              badge: 'SAVE 58%',
              highlight: true,
            ),

            const SizedBox(height: SakuraSpace.l),

            // ── Purchase button (dark CTA) ──
            // Two-step flow: tap a tier to select (highlights), then tap
            // this CTA to confirm. Prevents accidental purchase of the
            // default tier (e.g. yearly) when the user just wanted to
            // compare prices.
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_purchasing ||
                        _packages.isEmpty ||
                        _selectedPackage == null)
                    ? null
                    : () => _purchase(_selectedPackage!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SakuraColors.sumi,
                  foregroundColor: SakuraColors.washi,
                  disabledBackgroundColor: SakuraColors.bamboo,
                  disabledForegroundColor: SakuraColors.stone,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(SakuraRadius.m),
                  ),
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SakuraColors.washi,
                        ),
                      )
                    : Text(
                        _selectedPackage == null
                            ? 'Choose a plan above'
                            : 'Subscribe to Pro',
                        style: SakuraType.label(
                          size: 15,
                          color: _selectedPackage == null
                              ? SakuraColors.stone
                              : SakuraColors.washi,
                        ).copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3),
                      ),
              ),
            ),

            const SizedBox(height: SakuraSpace.m),

            // ── Restore link ──
            Center(
              child: TextButton(
                onPressed: _restoring ? null : _restore,
                child: _restoring
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: SakuraColors.sakura,
                        ),
                      )
                    : Text(
                        'Restore purchases',
                        style: SakuraType.label(
                          color: SakuraColors.sakura,
                          size: 13,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: SakuraColors.sakura,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: SakuraSpace.l),

            // Fine print
            Text(
              'Subscription auto-renews unless cancelled. Manage in Settings.',
              textAlign: TextAlign.center,
              style: SakuraType.caption(size: 11),
            ),
            const SizedBox(height: SakuraSpace.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _openUrl('https://cyan0914.github.io/ai-japanese-tutor/terms.html'),
                  child: Text(
                    'Terms of Use',
                    style: SakuraType.caption(size: 12, color: SakuraColors.mist)
                        .copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: SakuraColors.mist,
                        ),
                  ),
                ),
                Text('   ·   ', style: SakuraType.caption(size: 12, color: SakuraColors.stone)),
                GestureDetector(
                  onTap: () => _openUrl('https://cyan0914.github.io/ai-japanese-tutor/privacy.html'),
                  child: Text(
                    'Privacy Policy',
                    style: SakuraType.caption(size: 12, color: SakuraColors.mist)
                        .copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: SakuraColors.mist,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SakuraSpace.l),
          ],
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required String label,
    required String price,
    required String period,
    required String productId,
    required Package? package,
    String? badge,
    bool highlight = false,
  }) {
    // RevenueCat pricing display (more accurate than hardcoded constants)
    String displayPrice = price;
    if (package != null) {
      displayPrice = package.storeProduct.priceString;
    }

    final isSelected = package != null && package == _selectedPackage;

    return GestureDetector(
      onTap: (_purchasing || package == null)
          ? null
          : () {
              // Just select — purchase is confirmed by tapping the
              // Subscribe CTA. This avoids buying the first package the
              // user touches.
              setState(() => _selectedPackage = package);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: SakuraSpace.m, vertical: SakuraSpace.m,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? SakuraColors.sakuraSoft
              : (highlight ? SakuraColors.white : SakuraColors.washiDeep),
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          border: Border.all(
            color: isSelected
                ? SakuraColors.sakura
                : (highlight ? SakuraColors.sakura.withOpacity(0.4) : SakuraColors.bamboo),
            width: isSelected ? 2 : (highlight ? 1.5 : 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: SakuraType.title(size: 15),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: SakuraSpace.s),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SakuraColors.kinari.withOpacity(0.25),
                            borderRadius: const BorderRadius.all(SakuraRadius.pill),
                            border: Border.all(
                              color: SakuraColors.kinari.withOpacity(0.6),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: SakuraType.caption(
                              color: SakuraColors.momiji,
                              size: 10,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (package == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Not available',
                        style: SakuraType.caption(size: 11, color: SakuraColors.stone),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayPrice,
                  style: SakuraType.display(size: 20, color: SakuraColors.sumi),
                ),
                Text(
                  period,
                  style: SakuraType.caption(size: 11, color: SakuraColors.mist),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
