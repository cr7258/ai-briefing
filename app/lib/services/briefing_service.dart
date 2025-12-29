import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/briefing.dart';

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
}

