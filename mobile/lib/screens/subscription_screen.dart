/// Subscription screen — RevenueCat-powered IAP with 3 pricing tiers.
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
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
          const SnackBar(
            content: Text(' Welcome to Sakura Pro! Enjoy unlimited lessons.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase completed but Pro could not be verified. Please contact support.'),
            backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text(' Purchases restored! Welcome back to Pro.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
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
        title: const Text('Upgrade to Pro'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _packages.isEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Unable to load subscription options.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure RevenueCat is configured in App Store Connect.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('🌸', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Unlock Unlimited Learning',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '10 free lessons/day • Upgrade for unlimited access',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // ── 3 pricing tiers ──
          _buildTierCard(
            label: 'Monthly',
            price: '\$${AppConstants.priceMonthly.toStringAsFixed(2)}',
            period: '/month',
            productId: AppConstants.productMonthly,
            package: monthly,
            highlight: false,
            badge: null,
          ),
          const SizedBox(height: 12),

          _buildTierCard(
            label: 'Quarterly',
            price: '\$${AppConstants.priceQuarterly.toStringAsFixed(2)}',
            period: '/quarter',
            productId: AppConstants.productQuarterly,
            package: quarterly,
            highlight: true,
            badge: 'SAVE 33%',
          ),
          const SizedBox(height: 12),

          _buildTierCard(
            label: 'Yearly',
            price: '\$${AppConstants.priceYearly.toStringAsFixed(2)}',
            period: '/year',
            productId: AppConstants.productYearly,
            package: yearly,
            highlight: false,
            badge: 'SAVE 58%',
          ),

          const SizedBox(height: 20),

          // ── Purchase button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_purchasing || _packages.isEmpty)
                  ? null
                  : () {
                      // Default to yearly (best value) if selected; else first available
                      final target = yearly ?? _packages.first;
                      _purchase(target);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Subscribe Now',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Restore link ──
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Restore Purchases',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
          ),

          const SizedBox(height: 4),
          Text(
            'Subscription auto-renews unless cancelled. Manage in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _openUrl('https://cyan0914.github.io/ai-japanese-tutor/terms.html'),
                child: Text(
                  'Terms of Use',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text('  •  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              GestureDetector(
                onTap: () => _openUrl('https://cyan0914.github.io/ai-japanese-tutor/privacy.html'),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String label,
    required String price,
    required String period,
    required String productId,
    required Package? package,
    required bool highlight,
    String? badge,
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
              setState(() => _selectedPackage = package);
              _purchase(package);
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade50
              : highlight
                  ? Colors.pink.shade50
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade400
                : highlight
                    ? Colors.pink.shade300
                    : Colors.grey.shade300,
            width: isSelected ? 2.5 : (highlight ? 2 : 1),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: highlight ? Colors.pink.shade800 : Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (package == null)
                    Text(
                      'Not available',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayPrice,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.pink.shade800 : Colors.black87,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
