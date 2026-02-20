import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat entitlement identifier (must match RevenueCat dashboard)
const _entitlementId = 'AI Briefing Pro';

/// Service for managing Apple IAP subscriptions via RevenueCat.
/// Only used on iOS. Web uses Creem via SubscriptionService.
class RevenueCatService {
  static bool _initialized = false;

  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Initialize RevenueCat SDK. Must be called after Supabase auth is ready.
  /// [userId] should be the Supabase user ID for cross-platform identity.
  static Future<void> init({required String userId}) async {
    if (!isAvailable) return;
    if (_initialized) {
      await Purchases.logIn(userId);
      return;
    }

    final apiKey = dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('RevenueCat: REVENUECAT_APPLE_API_KEY not set, skipping init');
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    _initialized = true;
    debugPrint('RevenueCat: initialized for user $userId');
  }

  /// Get available subscription offerings from App Store
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// Get the default monthly package, if available
  Future<Package?> getMonthlyPackage() async {
    final offerings = await getOfferings();
    return offerings.current?.monthly;
  }

  /// Purchase a package (triggers Apple IAP payment sheet).
  /// Returns true if purchase was successful.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Show RevenueCat's built-in paywall UI.
  /// Returns true if the user now has an active entitlement.
  Future<bool> showPaywall(BuildContext context) async {
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
      _entitlementId,
    );
    return paywallResult == PaywallResult.purchased ||
        paywallResult == PaywallResult.restored;
  }

  /// Show RevenueCat's Customer Center (manage subscription, cancel, etc.)
  Future<void> showCustomerCenter(BuildContext context) async {
    await RevenueCatUI.presentCustomerCenter();
  }

  /// Restore previous purchases (e.g. after reinstall)
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat: restore failed: $e');
      return false;
    }
  }

  /// Check if user currently has active entitlement (local cache)
  Future<bool> hasActiveEntitlement() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get customer info for debugging/display
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// Log out the current RevenueCat user (call on app logout)
  static Future<void> logOut() async {
    if (!isAvailable || !_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat: logout failed: $e');
    }
  }
}
