import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/trial_service.dart';
import 'auth_provider.dart';

/// Provider for trial service
final trialServiceProvider = Provider<TrialService>((ref) {
  return TrialService();
});

/// Provider for the number of free trials used
/// Supports both logged-in (DB) and anonymous (local) users
final trialCountProvider = FutureProvider<int>((ref) async {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.maybeWhen(
    data: (user) async {
      if (user != null) {
        final service = ref.read(trialServiceProvider);
        return service.getTrialCount();
      }
      // Anonymous: read from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('anonymous_trial_ids') ?? [];
      return ids.length;
    },
    orElse: () => 0,
  );
});

/// Remaining free trials (10 - used)
final remainingTrialsProvider = Provider<int>((ref) {
  final countAsync = ref.watch(trialCountProvider);
  return countAsync.maybeWhen(
    data: (count) => (TrialService.maxFreeTrials - count).clamp(0, TrialService.maxFreeTrials),
    orElse: () => TrialService.maxFreeTrials,
  );
});

/// Refresh trial count (call after recording new access)
final refreshTrialProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(trialCountProvider);
  };
});
