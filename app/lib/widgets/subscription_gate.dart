import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trial_provider.dart';
import '../screens/paywall_screen.dart';
import '../services/auth_service.dart';
import 'auth_dialog.dart';

/// Utility to gate navigation behind subscription check.
/// Non-subscribed logged-in users get 3 free trial accesses.
/// Briefings beyond the trial require an active subscription.
class SubscriptionGate {
  /// Check subscription / trial and navigate. Shows paywall if not allowed.
  /// Returns true if navigation happened, false if blocked.
  ///
  /// [contentType] and [contentId] are required for trial tracking.
  /// contentType should be 'daily_briefing' or 'category_briefing'.
  static Future<bool> navigateIfSubscribed(
    BuildContext context,
    WidgetRef ref,
    Widget destination, {
    required String contentType,
    required String contentId,
  }) async {
    // 1. Wait for subscription data to fully load, then check.
    // This prevents false negatives when auth/subscription is still loading
    // on initial page load (e.g. session restoring from localStorage).
    try {
      final subscription = await ref.read(subscriptionProvider.future);
      if (subscription?.isActive ?? false) {
        if (context.mounted) _navigate(context, destination);
        return true;
      }
    } catch (_) {
      // If subscription check fails, continue to other checks
    }

    // 2. If not logged in, prompt login first
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      final authService = ref.read(authServiceProvider);
      await AuthDialog.show(context, authService);
      if (!context.mounted) return false;

      // Wait for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 500));
      if (!ref.read(isLoggedInProvider)) return false;

      // After login, check subscription again (user might already be subscribed)
      try {
        // Invalidate to force re-fetch with the now-logged-in user
        ref.invalidate(subscriptionProvider);
        final subscription = await ref.read(subscriptionProvider.future);
        if (subscription?.isActive ?? false) {
          if (context.mounted) _navigate(context, destination);
          return true;
        }
      } catch (_) {
        // Continue to trial check
      }
    }

    // 3. Logged in but not subscribed - try free trial
    final trialService = ref.read(trialServiceProvider);
    final granted = await trialService.tryAccessContent(contentType, contentId);

    if (granted) {
      // Refresh trial count in providers
      final refreshTrial = ref.read(refreshTrialProvider);
      await refreshTrial();

      if (context.mounted) {
        _navigate(context, destination);
      }
      return true;
    }

    // 4. Trial exhausted - show paywall
    if (!context.mounted) return false;
    final result = await PaywallScreen.show(context);

    // If user completed checkout flow, refresh subscription and try again
    if (result == true) {
      ref.invalidate(subscriptionProvider);
      final subscription = await ref.read(subscriptionProvider.future);

      if ((subscription?.isActive ?? false) && context.mounted) {
        _navigate(context, destination);
        return true;
      }
    }

    return false;
  }

  static void _navigate(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
