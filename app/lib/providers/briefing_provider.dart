import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/briefing.dart';
import '../models/category_briefing.dart';
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

/// Provider for category briefings by briefing ID
final categoryBriefingsProvider =
    FutureProvider.family<List<CategoryBriefing>, String>((ref, briefingId) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getCategoryBriefings(briefingId);
});

/// Provider for a specific category briefing
final categoryBriefingProvider =
    FutureProvider.family<CategoryBriefing?, ({String briefingId, String category})>(
        (ref, params) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getCategoryBriefing(params.briefingId, params.category);
});

/// Provider for articles by briefing ID and optional category
final articlesProvider =
    FutureProvider.family<List<Article>, ({String briefingId, String? category})>(
        (ref, params) async {
  final service = ref.watch(briefingServiceProvider);
  return service.getArticles(params.briefingId, category: params.category);
});

/// Data class for category briefing with date
class CategoryBriefingWithDate {
  final CategoryBriefing categoryBriefing;
  final DateTime date;

  CategoryBriefingWithDate({required this.categoryBriefing, required this.date});
}

/// Provider to fetch category briefings for a specific category across all briefings
final categoryBriefingsForCategoryProvider = FutureProvider.family<
    List<CategoryBriefingWithDate>,
    ({List<Briefing> briefings, String category})>((ref, params) async {
  final service = ref.watch(briefingServiceProvider);
  final results = <CategoryBriefingWithDate>[];

  for (final briefing in params.briefings) {
    final categoryBriefing =
        await service.getCategoryBriefing(briefing.id, params.category);
    if (categoryBriefing != null) {
      results.add(CategoryBriefingWithDate(
        categoryBriefing: categoryBriefing,
        date: briefing.date,
      ));
    }
  }

  return results;
});

