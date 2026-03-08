import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trial_provider.dart';
import '../screens/paywall_screen.dart';
import '../services/auth_service.dart';
import '../services/revenuecat_service.dart';
import 'auth_dialog.dart';

/// Utility to gate navigation behind subscription check.
/// Anonymous users get 10 free content accesses (tracked locally).
/// Logged-in non-subscribed users also get 10 free accesses (tracked in DB).
/// Beyond that, subscription is required.
class SubscriptionGate {
  static const int _maxAnonymousTrials = 10;
  static const String _anonymousTrialKey = 'anonymous_trial_ids';

  static Future<bool> navigateIfSubscribed(
    BuildContext context,
    WidgetRef ref,
    Widget destination, {
    required String contentType,
    required String contentId,
  }) async {
    // 1. Check subscription (if logged in)
    try {
      final subscription = await ref.read(subscriptionProvider.future);
      if (subscription?.isActive ?? false) {
        if (context.mounted) _navigate(context, destination);
        return true;
      }
    } catch (_) {}

    final isLoggedIn = ref.read(isLoggedInProvider);

    // 2. If logged in, use DB-based trial
    if (isLoggedIn) {
      final trialService = ref.read(trialServiceProvider);
      final granted = await trialService.tryAccessContent(contentType, contentId);

      if (granted) {
        final refreshTrial = ref.read(refreshTrialProvider);
        await refreshTrial();
        if (context.mounted) _navigate(context, destination);
        return true;
      }

      // Trial exhausted, show paywall
      if (!context.mounted) return false;
      final result = await PaywallScreen.show(context, ref: ref);
      if (result == true) {
        final isActive = await _waitForActiveSubscription(ref);
        if (isActive && context.mounted) {
          _navigate(context, destination);
          return true;
        }
      }
      return false;
    }

    // 3. Not logged in — use local anonymous trial
    final uniqueId = '$contentType:$contentId';
    final prefs = await SharedPreferences.getInstance();
    final accessedIds = prefs.getStringList(_anonymousTrialKey) ?? [];

    if (accessedIds.contains(uniqueId)) {
      if (context.mounted) _navigate(context, destination);
      return true;
    }

    if (accessedIds.length < _maxAnonymousTrials) {
      accessedIds.add(uniqueId);
      await prefs.setStringList(_anonymousTrialKey, accessedIds);
      if (context.mounted) _navigate(context, destination);
      return true;
    }

    // Anonymous trial exhausted — prompt login, then paywall
    if (!context.mounted) return false;
    final authService = ref.read(authServiceProvider);
    await AuthDialog.show(context, authService);
    if (!context.mounted) return false;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!ref.read(isLoggedInProvider)) return false;

    if (RevenueCatService.isAvailable) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        await RevenueCatService.init(userId: user.id);
      }
    }

    // After login, check subscription
    try {
      ref.invalidate(subscriptionProvider);
      final subscription = await ref.read(subscriptionProvider.future);
      if (subscription?.isActive ?? false) {
        if (context.mounted) _navigate(context, destination);
        return true;
      }
    } catch (_) {}

    // Logged in but not subscribed — check DB trial
    final trialService = ref.read(trialServiceProvider);
    final granted = await trialService.tryAccessContent(contentType, contentId);

    if (granted) {
      final refreshTrial = ref.read(refreshTrialProvider);
      await refreshTrial();
      if (context.mounted) _navigate(context, destination);
      return true;
    }

    // Show paywall
    if (!context.mounted) return false;
    final result = await PaywallScreen.show(context, ref: ref);
    if (result == true) {
      final isActive = await _waitForActiveSubscription(ref);
      if (isActive && context.mounted) {
        _navigate(context, destination);
        return true;
      }
    }

    return false;
  }

  static Future<bool> _waitForActiveSubscription(WidgetRef ref) async {
    const maxAttempts = 5;
    const delay = Duration(seconds: 2);

    for (var i = 0; i < maxAttempts; i++) {
      ref.invalidate(subscriptionProvider);
      try {
        final subscription = await ref.read(subscriptionProvider.future);
        if (subscription?.isActive ?? false) return true;
      } catch (_) {}

      if (i < maxAttempts - 1) await Future.delayed(delay);
    }

    return false;
  }

  static void _navigate(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
