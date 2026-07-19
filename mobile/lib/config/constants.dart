/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://sakura-tutor-api.fly.dev/api/v1';

  // Free tier daily limit
  static const int freeDailyLimit = 10;

  // ── RevenueCat ──
  /// Replace with your RevenueCat SDK public key (rc_...).
  /// Sign up at https://app.revenuecat.com → Project → API Keys.
  static const String revenueCatApiKey = 'appl_ibuNRxgDAqSdvjvwFxPFmOBNeQA';

  /// Product identifiers — must match RevenueCat dashboard + App Store Connect IAP.
  static const String productMonthly = 'sakura_pro_monthly';
  static const String productQuarterly = 'sakura_pro_quarterly';
  static const String productYearly = 'sakura_pro_yearly';

  /// Entitlement ID (set in RevenueCat dashboard → Entitlements).
  static const String entitlementPro = 'Sakura Tutor Pro';

  // ── Pricing (for display only — actual prices set in RevenueCat dashboard) ──
  static const double priceMonthly = 9.99;
  static const double priceQuarterly = 19.99;
  static const double priceYearly = 49.99;
}
