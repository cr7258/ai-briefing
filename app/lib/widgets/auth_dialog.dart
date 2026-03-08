import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

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

enum _AuthMode { oauth, signIn, signUp }

/// Auth dialog with OAuth providers and email sign-in/sign-up
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

  _AuthMode _authMode = _AuthMode.oauth;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadLastProvider();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadLastProvider() async {
    final last = await widget.authService.getLastProvider();
    if (mounted) {
      setState(() {
        _lastProviderId = last;
        if (last == 'email') _authMode = _AuthMode.signIn;
      });
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
        _showError('Sign in failed: $e');
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

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_authMode == _AuthMode.signUp) {
        final response =
            await widget.authService.signUpWithEmail(email, password);
        if (mounted) {
          // If email confirmation is enabled, user won't be signed in yet
          if (response.user?.emailConfirmedAt == null) {
            _showSuccess('Check your email for a verification link');
            setState(() => _authMode = _AuthMode.signIn);
          } else {
            Navigator.of(context).pop();
          }
        }
      } else {
        await widget.authService.signInWithEmail(email, password);
        if (mounted) Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (_authMode == _AuthMode.signIn &&
            e.message.toLowerCase().contains('invalid login credentials')) {
          _showError('No account found with this email. Switching to sign up…');
          setState(() => _authMode = _AuthMode.signUp);
        } else {
          _showError(e.message);
        }
      }
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email address first');
      return;
    }

    setState(() => _isEmailLoading = true);
    try {
      await widget.authService.resetPassword(email);
      if (mounted) _showSuccess('Password reset link sent to $email');
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
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
            Text(
              'Welcome to AI Briefing',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              _authMode == _AuthMode.signUp
                  ? 'Create your account'
                  : 'Sign in to access personalized features',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _authMode == _AuthMode.oauth
                  ? _buildOAuthView()
                  : _buildEmailView(),
            ),
            const SizedBox(height: 24),
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

  Widget _buildOAuthView() {
    return Column(
      key: const ValueKey('oauth'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._providers.asMap().entries.map((entry) {
          final index = entry.key;
          final provider = entry.value;
          return Padding(
            padding: EdgeInsets.only(
                bottom: index < _providers.length - 1 ? 12 : 0),
            child: _OAuthButton(
              provider: provider,
              isLoading: _loadingProviderId == provider.id,
              isDisabled: _isLoading,
              isLastUsed:
                  _lastProviderId == provider.id && _lastProviderId != 'email',
              onPressed: () => _handleSignIn(provider),
            ).animate().fadeIn(delay: (300 + index * 100).ms).slideY(
                  begin: 0.2,
                  end: 0,
                ),
          );
        }),
        const SizedBox(height: 20),
        _OrDivider(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _authMode = _AuthMode.signIn),
            icon: const Icon(Icons.email_outlined, size: 20),
            label: Text(
              'Continue with email',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: BorderSide(
                color: _lastProviderId == 'email'
                    ? AppTheme.primary.withOpacity(0.5)
                    : AppTheme.border,
                width: _lastProviderId == 'email' ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailView() {
    final isSignUp = _authMode == _AuthMode.signUp;

    return KeyedSubtree(
      key: const ValueKey('email'),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StyledTextField(
              controller: _emailController,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _StyledTextField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: _obscurePassword,
              autofillHints: [
                isSignUp
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction:
                  isSignUp ? TextInputAction.next : TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              onFieldSubmitted: isSignUp ? null : (_) => _handleEmailSubmit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'At least 6 characters';
                }
                return null;
              },
            ),
            if (isSignUp) ...[
              const SizedBox(height: 12),
              _StyledTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm password',
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                onFieldSubmitted: (_) => _handleEmailSubmit(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            if (!isSignUp) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isEmailLoading ? null : _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isEmailLoading ? null : _handleEmailSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isEmailLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        isSignUp ? 'Create account' : 'Sign in',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignUp
                      ? 'Already have an account?'
                      : "Don't have an account?",
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _authMode =
                        isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isSignUp ? 'Sign in' : 'Sign up',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _OrDivider(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _authMode = _AuthMode.oauth),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Back to social login',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        color: AppTheme.textPrimary,
      ),
      cursorColor: AppTheme.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppTheme.textMuted,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppTheme.textTertiary)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.error),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.border, height: 1)),
      ],
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
              disabledBackgroundColor:
                  provider.backgroundColor.withOpacity(0.5),
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

    final bluePath = Path()
      ..moveTo(21.35 * s, 11.1 * s)
      ..cubicTo(
          21.35 * s, 10.36 * s, 21.28 * s, 9.64 * s, 21.16 * s, 8.95 * s)
      ..lineTo(12 * s, 8.95 * s)
      ..lineTo(12 * s, 13.02 * s)
      ..lineTo(17.24 * s, 13.02 * s)
      ..cubicTo(
          17.01 * s, 14.26 * s, 16.28 * s, 15.31 * s, 15.22 * s, 16.01 * s)
      ..lineTo(15.22 * s, 18.45 * s)
      ..lineTo(18.41 * s, 18.45 * s)
      ..cubicTo(
          20.28 * s, 16.73 * s, 21.35 * s, 14.17 * s, 21.35 * s, 11.1 * s)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    final greenPath = Path()
      ..moveTo(12 * s, 21 * s)
      ..cubicTo(
          14.7 * s, 21 * s, 16.96 * s, 20.1 * s, 18.41 * s, 18.45 * s)
      ..lineTo(15.22 * s, 16.01 * s)
      ..cubicTo(
          14.35 * s, 16.59 * s, 13.26 * s, 16.93 * s, 12 * s, 16.93 * s)
      ..cubicTo(
          9.39 * s, 16.93 * s, 7.19 * s, 15.2 * s, 6.44 * s, 12.91 * s)
      ..lineTo(3.15 * s, 12.91 * s)
      ..lineTo(3.15 * s, 15.42 * s)
      ..cubicTo(4.63 * s, 18.38 * s, 8.09 * s, 21 * s, 12 * s, 21 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    final yellowPath = Path()
      ..moveTo(6.44 * s, 12.91 * s)
      ..cubicTo(
          6.24 * s, 12.33 * s, 6.12 * s, 11.7 * s, 6.12 * s, 11.05 * s)
      ..cubicTo(
          6.12 * s, 10.4 * s, 6.24 * s, 9.77 * s, 6.44 * s, 9.19 * s)
      ..lineTo(6.44 * s, 6.68 * s)
      ..lineTo(3.15 * s, 6.68 * s)
      ..cubicTo(2.42 * s, 8.12 * s, 2 * s, 9.74 * s, 2 * s, 11.05 * s)
      ..cubicTo(2 * s, 12.36 * s, 2.42 * s, 13.98 * s, 3.15 * s, 15.42 * s)
      ..lineTo(6.44 * s, 12.91 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    final redPath = Path()
      ..moveTo(12 * s, 5.17 * s)
      ..cubicTo(
          13.4 * s, 5.17 * s, 14.65 * s, 5.66 * s, 15.64 * s, 6.59 * s)
      ..lineTo(18.46 * s, 3.77 * s)
      ..cubicTo(
          16.95 * s, 2.36 * s, 14.7 * s, 1.1 * s, 12 * s, 1.1 * s)
      ..cubicTo(
          8.09 * s, 1.1 * s, 4.63 * s, 3.72 * s, 3.15 * s, 6.68 * s)
      ..lineTo(6.44 * s, 9.19 * s)
      ..cubicTo(
          7.19 * s, 6.9 * s, 9.39 * s, 5.17 * s, 12 * s, 5.17 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
