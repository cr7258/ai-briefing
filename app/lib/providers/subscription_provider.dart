import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for current user's subscription
/// Automatically refreshes when auth state changes
final subscriptionProvider = FutureProvider<UserSubscription?>((ref) async {
  // Watch auth state - when user logs in/out, this re-evaluates
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.maybeWhen(
    data: (user) async {
      if (user == null) return null;
      final service = ref.read(subscriptionServiceProvider);
      return service.getSubscription();
    },
    orElse: () => null,
  );
});

/// Simple boolean provider for gating content
final hasActiveSubscriptionProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  return subscriptionAsync.maybeWhen(
    data: (subscription) => subscription?.isActive ?? false,
    orElse: () => false,
  );
});

/// Provider to check if subscription data is still loading
final isSubscriptionLoadingProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  return subscriptionAsync.isLoading;
});

/// Refresh subscription status (call after checkout or returning from portal)
final refreshSubscriptionProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(subscriptionProvider);
  };
});
