import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for tracking free trial access (max 10 unique briefings)
class TrialService {
  final SupabaseClient _client = Supabase.instance.client;

  static const int maxFreeTrials = 10;

  /// Get the number of unique briefings the user has accessed for free
  Future<int> getTrialCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('user_trial_access')
        .select('id')
        .eq('user_id', user.id);

    return (response as List).length;
  }

  /// Check if a specific content was already accessed (doesn't consume quota)
  Future<bool> hasAccessedContent(String contentType, String contentId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('user_trial_access')
        .select('id')
        .eq('user_id', user.id)
        .eq('content_type', contentType)
        .eq('content_id', contentId)
        .maybeSingle();

    return response != null;
  }

  /// Try to access content for free. Returns true if access is granted.
  /// - If already accessed this content before: grants access (no extra cost)
  /// - If trial count < maxFreeTrials: records access and grants
  /// - Otherwise: denies access
  Future<bool> tryAccessContent(String contentType, String contentId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    // Check if already accessed
    final alreadyAccessed = await hasAccessedContent(contentType, contentId);
    if (alreadyAccessed) return true;

    // Check quota
    final count = await getTrialCount();
    if (count >= maxFreeTrials) return false;

    // Record access
    await _client.from('user_trial_access').insert({
      'user_id': user.id,
      'content_type': contentType,
      'content_id': contentId,
    });

    return true;
  }

  /// Get remaining free trials
  Future<int> getRemainingTrials() async {
    final count = await getTrialCount();
    return (maxFreeTrials - count).clamp(0, maxFreeTrials);
  }
}
