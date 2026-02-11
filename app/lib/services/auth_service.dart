import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _lastProviderKey = 'last_auth_provider';

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

  /// Get user's avatar URL (works for both Google and GitHub)
  String? get avatarUrl =>
      currentUser?.userMetadata?['avatar_url'] ??
      currentUser?.userMetadata?['picture'];

  /// Get user's name (works for both Google and GitHub)
  String? get userName =>
      currentUser?.userMetadata?['full_name'] ??
      currentUser?.userMetadata?['name'] ??
      currentUser?.userMetadata?['user_name'];

  /// Get user's email
  String? get userEmail => currentUser?.email;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get the last used OAuth provider ID (e.g. 'google', 'github')
  Future<String?> getLastProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastProviderKey);
  }

  /// Save the last used OAuth provider ID
  Future<void> _saveLastProvider(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastProviderKey, providerId);
  }

  /// Sign in with GitHub
  Future<void> signInWithGitHub() async {
    await _saveLastProvider('github');
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: _webRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    await _saveLastProvider('google');
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
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

