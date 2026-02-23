import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String? _lastProviderId;

  @override
  void initState() {
    super.initState();
    _loadLastProvider();
  }

  Future<void> _loadLastProvider() async {
    final last = await widget.authService.getLastProvider();
    if (mounted) {
      setState(() => _lastProviderId = last);
    }
  }

  List<OAuthProvider> get _providers => [
        if (AuthService.isAppleSignInAvailable)
          OAuthProvider(
            id: 'apple',
            name: 'Apple',
            icon: const _AppleIcon(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            onPressed: () => widget.authService.signInWithApple(),
          ),
        OAuthProvider(
          id: 'google',
          name: 'Google',
          icon: const _GoogleIcon(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          onPressed: () => widget.authService.signInWithGoogle(),
        ),
        OAuthProvider(
          id: 'github',
          name: 'GitHub',
          icon: const _GitHubIcon(),
          backgroundColor: const Color(0xFF24292e),
          foregroundColor: Colors.white,
          onPressed: () => widget.authService.signInWithGitHub(),
        ),
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
                  isLastUsed: _lastProviderId == provider.id,
                  onPressed: () => _handleSignIn(provider),
                ).animate().fadeIn(delay: (300 + index * 100).ms).slideY(begin: 0.2, end: 0),
              );
            }),

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
  final bool isLastUsed;
  final VoidCallback onPressed;

  const _OAuthButton({
    required this.provider,
    required this.isLoading,
    required this.isDisabled,
    this.isLastUsed = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Subtle glow behind button when last used
        if (isLastUsed)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
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
                  color: isLastUsed
                      ? AppTheme.primary.withOpacity(0.5)
                      : provider.backgroundColor == Colors.white
                          ? AppTheme.border
                          : Colors.transparent,
                  width: isLastUsed ? 1.5 : 1,
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
        ),
        // Floating "Last used" badge
        if (isLastUsed)
          Positioned(
            top: -9,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.9),
                    AppTheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 10,
                    color: Colors.black.withOpacity(0.8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Last used',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Apple icon
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.apple,
      size: 20,
      color: Colors.black87,
    );
  }
}

/// GitHub icon
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.github,
      size: 20,
      color: Colors.white,
    );
  }
}

/// Google icon with official four-color logo
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;

    // Blue
    final bluePath = Path()
      ..moveTo(21.35 * s, 11.1 * s)
      ..cubicTo(21.35 * s, 10.36 * s, 21.28 * s, 9.64 * s, 21.16 * s, 8.95 * s)
      ..lineTo(12 * s, 8.95 * s)
      ..lineTo(12 * s, 13.02 * s)
      ..lineTo(17.24 * s, 13.02 * s)
      ..cubicTo(17.01 * s, 14.26 * s, 16.28 * s, 15.31 * s, 15.22 * s, 16.01 * s)
      ..lineTo(15.22 * s, 18.45 * s)
      ..lineTo(18.41 * s, 18.45 * s)
      ..cubicTo(20.28 * s, 16.73 * s, 21.35 * s, 14.17 * s, 21.35 * s, 11.1 * s)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Green
    final greenPath = Path()
      ..moveTo(12 * s, 21 * s)
      ..cubicTo(14.7 * s, 21 * s, 16.96 * s, 20.1 * s, 18.41 * s, 18.45 * s)
      ..lineTo(15.22 * s, 16.01 * s)
      ..cubicTo(14.35 * s, 16.59 * s, 13.26 * s, 16.93 * s, 12 * s, 16.93 * s)
      ..cubicTo(9.39 * s, 16.93 * s, 7.19 * s, 15.2 * s, 6.44 * s, 12.91 * s)
      ..lineTo(3.15 * s, 12.91 * s)
      ..lineTo(3.15 * s, 15.42 * s)
      ..cubicTo(4.63 * s, 18.38 * s, 8.09 * s, 21 * s, 12 * s, 21 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // Yellow
    final yellowPath = Path()
      ..moveTo(6.44 * s, 12.91 * s)
      ..cubicTo(6.24 * s, 12.33 * s, 6.12 * s, 11.7 * s, 6.12 * s, 11.05 * s)
      ..cubicTo(6.12 * s, 10.4 * s, 6.24 * s, 9.77 * s, 6.44 * s, 9.19 * s)
      ..lineTo(6.44 * s, 6.68 * s)
      ..lineTo(3.15 * s, 6.68 * s)
      ..cubicTo(2.42 * s, 8.12 * s, 2 * s, 9.74 * s, 2 * s, 11.05 * s)
      ..cubicTo(2 * s, 12.36 * s, 2.42 * s, 13.98 * s, 3.15 * s, 15.42 * s)
      ..lineTo(6.44 * s, 12.91 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Red
    final redPath = Path()
      ..moveTo(12 * s, 5.17 * s)
      ..cubicTo(13.4 * s, 5.17 * s, 14.65 * s, 5.66 * s, 15.64 * s, 6.59 * s)
      ..lineTo(18.46 * s, 3.77 * s)
      ..cubicTo(16.95 * s, 2.36 * s, 14.7 * s, 1.1 * s, 12 * s, 1.1 * s)
      ..cubicTo(8.09 * s, 1.1 * s, 4.63 * s, 3.72 * s, 3.15 * s, 6.68 * s)
      ..lineTo(6.44 * s, 9.19 * s)
      ..cubicTo(7.19 * s, 6.9 * s, 9.39 * s, 5.17 * s, 12 * s, 5.17 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

