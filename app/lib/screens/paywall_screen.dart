import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trial_provider.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/trial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_dialog.dart';

/// Paywall screen shown when user tries to access premium content
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  /// Show as a centered dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => const PaywallScreen(),
    );
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    final isLoggedIn = ref.read(isLoggedInProvider);

    // If not logged in, show auth dialog first
    if (!isLoggedIn) {
      final authService = ref.read(authServiceProvider);
      await AuthDialog.show(context, authService);
      // After auth dialog closes, check if now logged in
      if (!mounted) return;
      // Wait a moment for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 500));
      if (!ref.read(isLoggedInProvider)) return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      final checkoutUrl = await service.createCheckout();

      // Open checkout in external browser
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open checkout page');
      }

      // Close paywall after redirecting to checkout
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start checkout: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
                const SizedBox(height: 8),

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

                const SizedBox(height: 4),

                // Title
                Text(
                  'Unlock AI Briefing Pro',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // Subtitle - show trial exhaustion or default message
                Builder(builder: (context) {
                  final remaining = ref.watch(remainingTrialsProvider);
                  final subtitle = remaining <= 0
                      ? 'You\'ve used all ${TrialService.maxFreeTrials} free previews. Subscribe for unlimited access to daily AI briefings, audio summaries, and category deep dives.'
                      : 'Get unlimited access to daily AI briefings, audio summaries, and category deep dives.';
                  return Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  );
                }).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 36),

                // Features list
                ..._buildFeatures(theme),

                const SizedBox(height: 36),

                // Price card
                _buildPriceCard(theme),

                const SizedBox(height: 24),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Subscribe Now',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Footer note
                Text(
                  'Cancel anytime from your account settings.\nSecure payment powered by Creem.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatures(ThemeData theme) {
    final features = [
      (Iconsax.document_text, 'Daily AI Briefings', 'Comprehensive news summaries every day'),
      (Iconsax.music, 'Audio Summaries', 'Listen to briefings on the go'),
      (Iconsax.category, 'Category Deep Dives', 'LLM, Agent, Coding, Infra and more'),
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final (icon, title, subtitle) = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: AppTheme.primary,
              size: 20,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (300 + index * 80).ms)
          .slideX(begin: 0.1, end: 0);
    }).toList();
  }

  Widget _buildPriceCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface,
            AppTheme.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '3',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'per month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
