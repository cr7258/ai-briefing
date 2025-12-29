import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/briefing.dart';
import '../services/briefing_service.dart';

/// Provider for briefing service
final briefingServiceProvider = Provider<BriefingService>((ref) {
  return BriefingService();
});

/// Provider for briefing list
final briefingListProvider = FutureProvider<List<Briefing>>((ref) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getLatestBriefings();
});

/// Provider for today's briefing
final todayBriefingProvider = FutureProvider<Briefing?>((ref) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getTodayBriefing();
});

/// Provider for a specific briefing by ID
final briefingByIdProvider =
    FutureProvider.family<Briefing?, String>((ref, id) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getBriefingById(id);
});

/// Provider to refresh briefing list
final briefingListRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(briefingListProvider);
    ref.invalidate(todayBriefingProvider);
  };
});

