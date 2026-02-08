import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';
import '../screens/paywall_screen.dart';

/// Utility to gate navigation behind subscription check.
/// The latest/featured briefing is always free.
/// Past briefings require an active subscription.
class SubscriptionGate {
  /// Check subscription and navigate. Shows paywall if not subscribed.
  /// Returns true if navigation happened, false if blocked.
  static Future<bool> navigateIfSubscribed(
    BuildContext context,
    WidgetRef ref,
    Widget destination,
  ) async {
    final hasSubscription = ref.read(hasActiveSubscriptionProvider);

    if (hasSubscription) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      );
      return true;
    }

    // Show paywall
    final result = await PaywallScreen.show(context);

    // If user completed checkout flow, refresh subscription and try again
    if (result == true) {
      final refresh = ref.read(refreshSubscriptionProvider);
      await refresh();

      // Wait for subscription data to refresh
      await Future.delayed(const Duration(seconds: 2));

      final nowSubscribed = ref.read(hasActiveSubscriptionProvider);
      if (nowSubscribed && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => destination),
        );
        return true;
      }
    }

    return false;
  }
}
