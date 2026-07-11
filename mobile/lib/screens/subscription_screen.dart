/// Subscription screen — feature comparison + buy button.
import 'package:flutter/material.dart';
import '../config/constants.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text('🌸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Unlock Unlimited Learning',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
            ),
            const SizedBox(height: 32),

            // Feature comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _featureRow('Daily lessons', '5 / day', 'Unlimited', true),
                    const Divider(),
                    _featureRow('AI conversation', '✓', '✓', true),
                    const Divider(),
                    _featureRow('Pronunciation scoring', '✓', '✓', true),
                    const Divider(),
                    _featureRow('Grammar corrections', '✓', '✓', true),
                    const Divider(),
                    _featureRow('TTS audio playback', '✓', '✓', true),
                    const Divider(),
                    _featureRow('Progress tracking', 'Basic', 'Advanced', false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Price
            Text(
              '\$${AppConstants.proMonthlyPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
            const Text('/month', style: TextStyle(color: Colors.grey)),

            const Spacer(),

            // Buy button (MVP: direct, RevenueCat integration later)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('RevenueCat integration coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Subscribe Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String label, String free, String pro, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: included ? null : Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
