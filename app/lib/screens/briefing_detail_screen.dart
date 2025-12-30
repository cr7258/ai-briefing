import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/briefing.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.heart),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Iconsax.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Iconsax.more),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Big Cover Art
            Hero(
              tag: 'cover_${briefing.id}', // Match home screen tag if passed, or just unique
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: -10,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: BriefingCover(
                  date: briefing.date,
                  size: 280,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              briefing.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                height: 1.2,
                fontSize: 26,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Host/Meta Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.primaryColor,
                  child: const Icon(Iconsax.microphone_2, size: 14, color: Colors.black),
                 ),
                 const SizedBox(width: 8),
                 Text(
                   'AI Briefing Host',
                   style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
                 ),
                 Container(
                   margin: const EdgeInsets.symmetric(horizontal: 12),
                   width: 4,
                   height: 4,
                   decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                 ),
                 Text(
                   DateFormat('MMM dd, yyyy').format(briefing.date),
                   style: theme.textTheme.bodyMedium,
                 ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons Row (Save, Download, etc)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(icon: Iconsax.document_download, label: 'Save'),
                const SizedBox(width: 24),
                _ActionButton(icon: Iconsax.link_1, label: 'Copy Link'),
                const SizedBox(width: 24),
                _ActionButton(icon: Iconsax.message_text, label: 'Discuss'),
              ],
            ),

            const SizedBox(height: 40),
            
            // Audio Player Section
            if (briefing.hasAudio) ...[
              BriefingAudioPlayer(
                audioUrl: briefing.audioUrl!,
                duration: briefing.audioDuration,
              ),
              const SizedBox(height: 48),
            ],

            // Divider before text
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "EPISODE NOTES",
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              ],
            ),
            
            const SizedBox(height: 24),

            // Markdown Content
            MarkdownBody(
              data: briefing.summary,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                h3: theme.textTheme.titleMedium?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
                p: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontSize: 17, // Slightly larger for readability
                  color: Colors.white.withOpacity(0.9),
                ),
                listBullet: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor),
                // Styled blockquote
                blockquote: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: theme.colorScheme.secondary, width: 4),
                  ),
                ),
                blockquotePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                code: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: Colors.white.withOpacity(0.1),
                  fontSize: 14,
                ),
                codeblockPadding: const EdgeInsets.all(16),
                codeblockDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                a: TextStyle(
                  color: theme.primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.primaryColor.withOpacity(0.5),
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                }
              },
            ),
            
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
