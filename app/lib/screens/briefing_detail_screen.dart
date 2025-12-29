import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/briefing.dart';
import '../widgets/audio_player.dart';

/// Screen showing full briefing content
class BriefingDetailScreen extends StatelessWidget {
  final Briefing briefing;

  const BriefingDetailScreen({
    super.key,
    required this.briefing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                briefing.title,
                style: const TextStyle(fontSize: 14),
              ),
              titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 16),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    dateFormat.format(briefing.date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Audio player
                  if (briefing.hasAudio) ...[
                    BriefingAudioPlayer(
                      audioUrl: briefing.audioUrl!,
                      duration: briefing.audioDuration,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Markdown content
                  MarkdownBody(
                    data: briefing.summary,
                    selectable: true,
                    styleSheet: _buildMarkdownStyleSheet(theme),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        _launchUrl(href);
                      }
                    },
                  ),

                  // Bottom padding
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build custom markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge,
      h2: theme.textTheme.headlineMedium?.copyWith(
        height: 1.4,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        height: 1.4,
      ),
      p: theme.textTheme.bodyLarge,
      a: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      blockSpacing: 16,
      h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 20, bottom: 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      code: TextStyle(
        fontFamily: 'monospace',
        color: theme.colorScheme.onSurface,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  /// Launch URL in browser
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

