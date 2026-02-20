import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription.dart';
import 'revenuecat_service.dart';

/// Service for managing user subscriptions.
/// Routes to Apple IAP (via RevenueCat) on iOS, or Creem on Web.
class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Whether we're on iOS and should use Apple IAP
  bool get _useAppleIAP => RevenueCatService.isAvailable;

  /// Get current user's subscription status from Supabase
  Future<UserSubscription?> getSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('user_subscriptions')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserSubscription.fromJson(response);
  }

  /// Check if current user has an active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getSubscription();
    return subscription?.isActive ?? false;
  }

  // ─── iOS: Apple IAP via RevenueCat ───────────────────────

  /// Get the monthly package from RevenueCat (iOS only)
  Future<Package?> getMonthlyPackage() async {
    if (!_useAppleIAP) return null;
    final rcService = RevenueCatService();
    return rcService.getMonthlyPackage();
  }

  /// Purchase via Apple IAP (iOS only). Returns true if successful.
  Future<bool> purchaseApple(Package package) async {
    final rcService = RevenueCatService();
    return rcService.purchasePackage(package);
  }

  /// Restore Apple IAP purchases (iOS only). Returns true if premium restored.
  Future<bool> restoreApplePurchases() async {
    if (!_useAppleIAP) return false;
    final rcService = RevenueCatService();
    return rcService.restorePurchases();
  }

  // ─── Web: Creem checkout ─────────────────────────────────

  /// Create a Creem checkout session via Edge Function (Web only).
  /// Returns the checkout URL to redirect the user to.
  Future<String> createCheckout({String? discountCode}) async {
    final response = await _client.functions.invoke(
      'create-checkout',
      body: {
        if (discountCode != null) 'discount_code': discountCode,
      },
    );

    if (response.status != 200) {
      final error = response.data;
      throw Exception(
          error?['error'] ?? 'Failed to create checkout session');
    }

    final data = response.data as Map<String, dynamic>;
    final checkoutUrl = data['checkout_url'] as String?;

    if (checkoutUrl == null) {
      throw Exception('No checkout URL returned');
    }

    return checkoutUrl;
  }

  /// Get customer portal URL via Edge Function (Web only).
  /// Returns the portal URL to redirect the user to.
  Future<String> getPortalUrl() async {
    final response = await _client.functions.invoke(
      'customer-portal',
      body: {},
    );

    if (response.status != 200) {
      final error = response.data;
      throw Exception(
          error?['error'] ?? 'Failed to get portal URL');
    }

    final data = response.data as Map<String, dynamic>;
    final portalUrl = data['portal_url'] as String?;

    if (portalUrl == null) {
      throw Exception('No portal URL returned');
    }

    return portalUrl;
  }
}
