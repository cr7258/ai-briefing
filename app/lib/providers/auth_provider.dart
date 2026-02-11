import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user provider - rebuilds when auth state changes.
/// Uses asyncMap to ensure full user metadata (including avatar_url)
/// is available even after session restoration from localStorage.
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);

  return authService.authStateChanges.asyncMap((state) async {
    final user = state.session?.user;
    if (user == null) return null;

    // If user metadata has avatar_url, use the stream user directly
    final hasAvatar = user.userMetadata?['avatar_url'] != null ||
        user.userMetadata?['picture'] != null;
    if (hasAvatar) return user;

    // Metadata might be incomplete (e.g. after session restore from JWT).
    // Try the in-memory currentUser first (cheaper than network call).
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null &&
        (currentUser.userMetadata?['avatar_url'] != null ||
            currentUser.userMetadata?['picture'] != null)) {
      return currentUser;
    }

    // Last resort: fetch full user from server to get complete metadata.
    try {
      final response = await Supabase.instance.client.auth.getUser();
      return response.user ?? user;
    } catch (e) {
      debugPrint('Failed to fetch full user data: $e');
      return user;
    }
  });
});

/// Simple bool provider to check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

