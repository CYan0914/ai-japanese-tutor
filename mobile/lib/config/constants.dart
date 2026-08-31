/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://sakura.taomindapp.com/api/v1';

  // ── Google Sign-In (iOS OAuth client) ──
  /// Must match backend GOOGLE_IOS_CLIENT_ID (the backend verifies the
  /// ID token's aud claim against this value).
  static const String googleIosClientId =
      '46270774255-dpqpl7i64e2k3nmjd633l97rem553938.apps.googleusercontent.com';
  /// Reversed client ID — registered as a URL scheme in Info.plist.
  static const String googleIosReversedClientId =
      'com.googleusercontent.apps.46270774255-dpqpl7i64e2k3nmjd633l97rem553938';

  // Free tier daily limit
  static const int freeDailyLimit = 5;

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
