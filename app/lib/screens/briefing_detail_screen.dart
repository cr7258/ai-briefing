import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/briefing.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive.dart';
import '../widgets/audio_player.dart';
import '../widgets/briefing_cover.dart';

class BriefingDetailScreen extends StatelessWidget {
  final Briefing briefing;

  const BriefingDetailScreen({
    super.key,
    required this.briefing,
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
            // Hero Section with Cover
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
                    if (briefing.hasAudio) ...[
                      BriefingAudioPlayer(
                        audioUrl: briefing.audioUrl!,
                        duration: briefing.audioDuration,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Episode Notes Header
                    _buildSectionDivider(context, 'EPISODE NOTES'),
                    
                    const SizedBox(height: 20),

                    // Markdown Content
                    MarkdownBody(
                      data: briefing.summary,
                      selectable: true,
                      styleSheet: _buildMarkdownStyleSheet(theme),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
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
        _AppBarButton(icon: Iconsax.heart, onTap: () {}),
        _AppBarButton(icon: Iconsax.share, onTap: () {}),
        _AppBarButton(icon: Iconsax.more, onTap: () {}),
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
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
          child: Column(
            children: [
              // Cover Art with glow effect
              Hero(
                tag: 'cover_${briefing.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: -10,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: BriefingCover(
                    date: briefing.date,
                    size: Responsive.detailCoverSize(context),
                    showWaveform: true,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                briefing.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Meta Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryAlt],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.cpu, size: 14, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Briefing',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(briefing.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (briefing.hasAudio) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Iconsax.headphone, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      briefing.formattedDuration,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Quick Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickActionButton(
                    icon: Iconsax.document_download,
                    label: 'Save',
                    onTap: () {},
                  ),
                  const SizedBox(width: 32),
                  _QuickActionButton(
                    icon: Iconsax.link_1,
                    label: 'Share',
                    onTap: () {},
                  ),
                  const SizedBox(width: 32),
                  _QuickActionButton(
                    icon: Iconsax.message_text_1,
                    label: 'Notes',
                    onTap: () {},
                  ),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
