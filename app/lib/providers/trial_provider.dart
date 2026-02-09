import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/trial_service.dart';
import 'auth_provider.dart';

/// Provider for trial service
final trialServiceProvider = Provider<TrialService>((ref) {
  return TrialService();
});

/// Provider for the number of free trials used
/// Automatically refreshes when auth state changes
final trialCountProvider = FutureProvider<int>((ref) async {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.maybeWhen(
    data: (user) async {
      if (user == null) return 0;
      final service = ref.read(trialServiceProvider);
      return service.getTrialCount();
    },
    orElse: () => 0,
  );
});

/// Remaining free trials (3 - used)
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
