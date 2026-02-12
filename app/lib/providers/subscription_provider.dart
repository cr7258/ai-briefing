import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for current user's subscription
/// Automatically refreshes when auth state changes.
/// Uses .future to properly wait for auth state to resolve before querying,
/// preventing false-negative subscription checks on initial page load.
final subscriptionProvider = FutureProvider<UserSubscription?>((ref) async {
  // Await auth state - ensures we wait for session restore before checking
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final service = ref.read(subscriptionServiceProvider);
  return service.getSubscription();
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
