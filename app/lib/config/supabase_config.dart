import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration
/// Values are loaded from .env file
class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get anonKey => dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  // Storage bucket name for audio files
  static const String audioBucket = 'briefing-audio';
}

