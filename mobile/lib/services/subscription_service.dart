/// RevenueCat subscription service.
///
/// Wraps the purchases_flutter SDK for:
///   - Initialising RevenueCat with the user ID
///   - Fetching available product offerings
///   - Making purchases
///   - Checking entitlement (Pro) status
///   - Restoring purchases
library;

import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/constants.dart';

class SubscriptionService {
  /// Initialise RevenueCat with the user's ID.
  /// Call this right after the user authenticates (splash screen).
  static Future<void> init(String userId) async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration(AppConstants.revenueCatApiKey)
        ..appUserID = userId,
    );
  }

  /// Fetch the current offering (set of available packages).
  /// Returns null if no offerings are configured in RevenueCat dashboard.
  static Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (_) {
      return null;
    }
  }

  /// Purchase a package and return the updated [CustomerInfo].
  static Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  /// Check whether the current user has an active Pro entitlement.
  static Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[AppConstants.entitlementPro]?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  /// Restore previous purchases.
  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  /// Sync subscription status to the backend so the server knows the tier.
  /// Call this after every purchase / restore.
  static Future<void> syncToBackend() async {
    // The sync is handled by the user endpoint; the caller
    // (subscription screen) calls ApiService.syncSubscription().
  }
}
