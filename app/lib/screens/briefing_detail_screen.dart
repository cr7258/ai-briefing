import 'package:flutter/material.dart' hide ThemeData, ThemeMode, Theme, Scaffold, AppBar, Card, IconButton, CircularProgressIndicator, Divider, Colors;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
    final dateFormat = DateFormat('yyyy 年 MM 月 dd 日 EEEE', 'zh_CN');

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          title: Text(
            briefing.title,
            style: theme.typography.small.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeader(context, theme, dateFormat),
            const SizedBox(height: 24),

            // Audio player
            if (briefing.hasAudio) ...[
              BriefingAudioPlayer(
                audioUrl: briefing.audioUrl!,
                duration: briefing.audioDuration,
              ),
              const SizedBox(height: 32),
            ],

            // Divider
            const Divider(),
            const SizedBox(height: 24),

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
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DateFormat dateFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date badge
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(briefing.date),
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          briefing.title,
          style: theme.typography.h2,
        ),
      ],
    );
  }

  /// Build custom markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      h1: theme.typography.h1,
      h2: theme.typography.h2.copyWith(
        height: 1.4,
      ),
      h3: theme.typography.h3.copyWith(
        height: 1.4,
      ),
      h4: theme.typography.h4,
      p: theme.typography.base.copyWith(
        height: 1.8,
        color: theme.colorScheme.foreground,
      ),
      a: theme.typography.base.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary,
      ),
      blockSpacing: 20,
      h2Padding: const EdgeInsets.only(top: 32, bottom: 12),
      h3Padding: const EdgeInsets.only(top: 24, bottom: 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(16),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      code: TextStyle(
        fontFamily: 'monospace',
        color: theme.colorScheme.foreground,
        backgroundColor: const Color(0x00000000), // transparent
      ),
      listBullet: theme.typography.base.copyWith(
        color: theme.colorScheme.primary,
      ),
      listIndent: 24,
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
