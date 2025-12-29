/// Daily briefing model
class Briefing {
  final String id;
  final DateTime date;
  final String title;
  final String summary; // Markdown format
  final String? audioUrl;
  final int? audioDuration; // Duration in seconds
  final DateTime createdAt;

  Briefing({
    required this.id,
    required this.date,
    required this.title,
    required this.summary,
    this.audioUrl,
    this.audioDuration,
    required this.createdAt,
  });

  /// Create from Supabase JSON response
  factory Briefing.fromJson(Map<String, dynamic> json) {
    return Briefing(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      audioUrl: json['audio_url'] as String?,
      audioDuration: json['audio_duration'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'title': title,
      'summary': summary,
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'created_at': createdAt.toIso8601String(),
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
}

