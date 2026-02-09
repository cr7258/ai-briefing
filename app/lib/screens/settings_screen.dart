import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

/// Settings screen accessed from user avatar dropdown
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            expandedHeight: 70,
            backgroundColor: AppTheme.background.withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ─── Subscription Section ───
                  Text(
                    'SUBSCRIPTION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  subscriptionAsync.when(
                    data: (subscription) {
                      if (subscription != null && subscription.isActive) {
                        return _SettingsTile(
                          icon: Iconsax.crown_1,
                          iconColor: AppTheme.warning,
                          title: 'Pro Subscription',
                          subtitle: subscription.isCanceled
                              ? 'Expires ${subscription.currentPeriodEnd != null ? DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd!) : 'soon'}'
                              : 'Active',
                          trailing: const _SettingsChevron(),
                          onTap: () => _openCustomerPortal(context, ref),
                        );
                      } else {
                        return _SettingsTile(
                          icon: Iconsax.crown_1,
                          iconColor: AppTheme.textTertiary,
                          title: 'Upgrade to Pro',
                          subtitle: 'Unlock unlimited access',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryAlt],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          onTap: () => PaywallScreen.show(context),
                        );
                      }
                    },
                    loading: () => const _SettingsTile(
                      icon: Iconsax.crown_1,
                      iconColor: AppTheme.textTertiary,
                      title: 'Subscription',
                      subtitle: 'Loading...',
                    ),
                    error: (_, __) => const _SettingsTile(
                      icon: Iconsax.crown_1,
                      iconColor: AppTheme.textTertiary,
                      title: 'Subscription',
                      subtitle: 'Could not load status',
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomerPortal(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final portalUrl = await service.getPortalUrl();
      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open billing portal: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

/// Settings list tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
      ),
    );
  }
}

/// Chevron arrow for settings tiles
class _SettingsChevron extends StatelessWidget {
  const _SettingsChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Iconsax.arrow_right_3,
      color: AppTheme.textTertiary,
      size: 18,
    );
  }
}
