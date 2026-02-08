import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// OAuth provider configuration
class OAuthProvider {
  final String id;
  final String name;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Future<void> Function() onPressed;

  const OAuthProvider({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });
}

/// Beautiful auth dialog with OAuth providers
class AuthDialog extends StatefulWidget {
  final AuthService authService;

  const AuthDialog({
    super.key,
    required this.authService,
  });

  static Future<void> show(BuildContext context, AuthService authService) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AuthDialog(authService: authService),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isLoading = false;
  String? _loadingProviderId;

  List<OAuthProvider> get _providers => [
        OAuthProvider(
          id: 'github',
          name: 'GitHub',
          icon: const _GitHubIcon(),
          backgroundColor: const Color(0xFF24292e),
          foregroundColor: Colors.white,
          onPressed: () => widget.authService.signInWithGitHub(),
        ),
        // Add more providers here in the future
        // OAuthProvider(
        //   id: 'google',
        //   name: 'Google',
        //   icon: const _GoogleIcon(),
        //   backgroundColor: Colors.white,
        //   foregroundColor: Colors.black87,
        //   onPressed: () => widget.authService.signInWithGoogle(),
        // ),
      ];

  Future<void> _handleSignIn(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _loadingProviderId = provider.id;
    });

    try {
      await provider.onPressed();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProviderId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.border.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/ai-briefing.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().scale(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Welcome to AI Briefing',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sign in to access personalized features',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // OAuth Buttons
            ..._providers.asMap().entries.map((entry) {
              final index = entry.key;
              final provider = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < _providers.length - 1 ? 12 : 0),
                child: _OAuthButton(
                  provider: provider,
                  isLoading: _loadingProviderId == provider.id,
                  isDisabled: _isLoading,
                  onPressed: () => _handleSignIn(provider),
                ).animate().fadeIn(delay: (300 + index * 100).ms).slideY(begin: 0.2, end: 0),
              );
            }),

            const SizedBox(height: 24),

            // Divider with text
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.border,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'More options coming soon',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.border,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Footer text
            Text(
              'By signing in, you agree to our Terms of Service and Privacy Policy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

/// OAuth sign-in button
class _OAuthButton extends StatelessWidget {
  final OAuthProvider provider;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _OAuthButton({
    required this.provider,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.backgroundColor,
          foregroundColor: provider.foregroundColor,
          disabledBackgroundColor: provider.backgroundColor.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: provider.backgroundColor == Colors.white
                  ? AppTheme.border
                  : Colors.transparent,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: provider.foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  provider.icon,
                  const SizedBox(width: 12),
                  Text(
                    'Continue with ${provider.name}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: provider.foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// GitHub icon
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Iconsax.code,
      size: 20,
      color: Colors.white,
    );
  }
}

/// Google icon (for future use)
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Image.network(
        'https://www.google.com/favicon.ico',
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
      ),
    );
  }
}

