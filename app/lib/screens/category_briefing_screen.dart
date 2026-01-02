import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/category_briefing.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_player.dart';

/// Screen to display a category-specific briefing
class CategoryBriefingScreen extends StatelessWidget {
  final CategoryBriefing categoryBriefing;
  final DateTime date;

  const CategoryBriefingScreen({
    super.key,
    required this.categoryBriefing,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context, theme),

            // Content Section
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Audio Player
                    if (categoryBriefing.hasAudio) ...[
                      BriefingAudioPlayer(
                        audioUrl: categoryBriefing.audioUrl!,
                        duration: categoryBriefing.audioDuration,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Section Divider
                    _buildSectionDivider(
                        context, '${categoryBriefing.categoryDisplayName} NEWS'),

                    const SizedBox(height: 20),

                    // Markdown Content
                    MarkdownBody(
                      data: categoryBriefing.summary,
                      selectable: true,
                      styleSheet: _buildMarkdownStyleSheet(theme),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const Icon(Iconsax.arrow_left_2, size: 20),
              ),
            ),
          ),
        ),
      ),
      actions: [
        _AppBarButton(icon: Iconsax.share, onTap: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            children: [
              // Category Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryAlt],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  categoryBriefing.categoryDisplayName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                categoryBriefing.title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // Meta Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (categoryBriefing.articleCount != null) ...[
                    Icon(Iconsax.document_text,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '${categoryBriefing.articleCount} articles',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (categoryBriefing.hasAudio) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Iconsax.headphone,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      categoryBriefing.formattedDuration,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context, String title) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.border,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.border,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.8,
        fontSize: 16,
        color: AppTheme.textPrimary.withOpacity(0.9),
      ),
      listBullet: theme.textTheme.bodyLarge?.copyWith(
        color: AppTheme.primary,
      ),
      listIndent: 24,
      blockSpacing: 16,
      h1Padding: const EdgeInsets.only(top: 32, bottom: 16),
      h2Padding: const EdgeInsets.only(top: 28, bottom: 12),
      h3Padding: const EdgeInsets.only(top: 24, bottom: 8),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.accent,
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.accent, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(20),
      code: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceVariant,
      ),
      codeblockPadding: const EdgeInsets.all(20),
      codeblockDecoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      a: const TextStyle(
        color: AppTheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: AppTheme.primary,
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

