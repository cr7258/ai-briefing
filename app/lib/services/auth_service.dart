import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the current web origin for OAuth redirect
  /// In debug mode (localhost), returns the localhost URL
  /// In release mode, returns null to use Supabase's default Site URL
  String? get _webRedirectUrl {
    if (!kIsWeb) return 'io.supabase.aibriefing://login-callback';
    if (kDebugMode) return Uri.base.origin;
    return null; // Uses Supabase Site URL in production
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get user's avatar URL from GitHub
  String? get avatarUrl => currentUser?.userMetadata?['avatar_url'];

  /// Get user's name from GitHub
  String? get userName =>
      currentUser?.userMetadata?['full_name'] ??
      currentUser?.userMetadata?['user_name'];

  /// Get user's email
  String? get userEmail => currentUser?.email;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with GitHub
  Future<void> signInWithGitHub() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: _webRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

