import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/article.dart';
import '../models/briefing.dart';
import '../models/category_briefing.dart';

/// Service for fetching briefings from Supabase
class BriefingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get latest briefings
  Future<List<Briefing>> getLatestBriefings({int limit = 30}) async {
    final response = await _client
        .from('daily_briefings')
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Briefing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get briefing by date
  Future<Briefing?> getBriefingByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _client
        .from('daily_briefings')
        .select()
        .eq('date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return Briefing.fromJson(response);
  }

  /// Get today's briefing
  Future<Briefing?> getTodayBriefing() async {
    return getBriefingByDate(DateTime.now());
  }

  /// Get briefing by ID
  Future<Briefing?> getBriefingById(String id) async {
    final response = await _client
        .from('daily_briefings')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Briefing.fromJson(response);
  }

  /// Get category briefings for a daily briefing
  Future<List<CategoryBriefing>> getCategoryBriefings(String briefingId) async {
    final response = await _client
        .from('category_briefings')
        .select()
        .eq('briefing_id', briefingId)
        .order('category');

    return (response as List)
        .map((json) => CategoryBriefing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get category briefing by briefing ID and category
  Future<CategoryBriefing?> getCategoryBriefing(
      String briefingId, String category) async {
    final response = await _client
        .from('category_briefings')
        .select()
        .eq('briefing_id', briefingId)
        .eq('category', category)
        .maybeSingle();

    if (response == null) return null;
    return CategoryBriefing.fromJson(response);
  }

  /// Get articles for a briefing
  Future<List<Article>> getArticles(String briefingId,
      {String? category}) async {
    var query = _client
        .from('articles')
        .select()
        .eq('briefing_id', briefingId);

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('published_at', ascending: false);

    return (response as List)
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

