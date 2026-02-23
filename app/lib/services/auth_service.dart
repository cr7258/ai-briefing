import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
    );
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    await _saveLastProvider('google');
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _webRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
    );
  }

  /// Whether Apple Sign-In is available (iOS only)
  static bool get isAppleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Sign in with Apple (native iOS only)
  Future<void> signInWithApple() async {
    assert(isAppleSignInAvailable, 'Apple Sign-In is only available on iOS');
    await _saveLastProvider('apple');

    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Could not find ID Token from generated credential.',
      );
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

