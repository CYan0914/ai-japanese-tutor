/// App-wide constants.
class AppConstants {
  AppConstants._();

  // ponytail: single source of truth, change here = everywhere
  static const String apiBaseUrl = 'https://sakura-tutor-api.fly.dev/api/v1';

  // Free tier daily limit
  static const int freeDailyLimit = 10;

  // Subscription pricing
  static const double proMonthlyPrice = 9.99;
}
