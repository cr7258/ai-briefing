/// Article model - represents a classified news article
class Article {
  final String id;
  final String briefingId;
  final String title;
  final String url;
  final String? summary;
  final String category;
  final String? sourceName;
  final DateTime? publishedAt;

  Article({
    required this.id,
    required this.briefingId,
    required this.title,
    required this.url,
    this.summary,
    required this.category,
    this.sourceName,
    this.publishedAt,
  });

  /// Create from Supabase JSON response
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      briefingId: json['briefing_id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      summary: json['summary'] as String?,
      category: json['category'] as String,
      sourceName: json['source_name'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'briefing_id': briefingId,
      'title': title,
      'url': url,
      'summary': summary,
      'category': category,
      'source_name': sourceName,
      'published_at': publishedAt?.toIso8601String(),
    };
  }
}

