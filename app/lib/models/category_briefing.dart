/// Category briefing model - represents AI-generated summary for a specific category
class CategoryBriefing {
  final String id;
  final String briefingId;
  final String category;
  final String summary;
  final String? audioUrl;
  final int? audioDuration;
  final int? articleCount;

  CategoryBriefing({
    required this.id,
    required this.briefingId,
    required this.category,
    required this.summary,
    this.audioUrl,
    this.audioDuration,
    this.articleCount,
  });

  /// Create from Supabase JSON response
  factory CategoryBriefing.fromJson(Map<String, dynamic> json) {
    return CategoryBriefing(
      id: json['id'] as String,
      briefingId: json['briefing_id'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      audioUrl: json['audio_url'] as String?,
      audioDuration: json['audio_duration'] as int?,
      articleCount: json['article_count'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'briefing_id': briefingId,
      'category': category,
      'summary': summary,
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'article_count': articleCount,
    };
  }

  /// Check if audio is available
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  /// Get formatted duration string (e.g., "5:30")
  String get formattedDuration {
    if (audioDuration == null) return '--:--';
    final minutes = audioDuration! ~/ 60;
    final seconds = audioDuration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get display name for category (uppercase)
  String get categoryDisplayName => category.toUpperCase();

  /// All available categories in order
  static const List<String> allCategories = [
    'llm',
    'agent',
    'multimodal',
    'coding',
    'infra',
    'robotics',
    'research',
    'apps',
    'industry',
    'cloud_native',
  ];
}

