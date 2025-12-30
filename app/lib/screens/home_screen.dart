import 'package:flutter/material.dart' hide ThemeData, ThemeMode, Theme, Scaffold, AppBar, Card, IconButton, CircularProgressIndicator, Divider, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/briefing.dart';
import '../providers/briefing_provider.dart';
import 'briefing_detail_screen.dart';

/// Home screen showing list of daily briefings
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingsAsync = ref.watch(briefingListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, size: 24),
              SizedBox(width: 12),
              Text('AI Briefing'),
            ],
          ),
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(briefingListProvider),
            ),
          ],
        ),
      ],
      child: briefingsAsync.when(
        data: (briefings) => _buildBriefingList(context, ref, briefings),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorView(context, ref, error),
      ),
    );
  }

  Widget _buildBriefingList(
    BuildContext context,
    WidgetRef ref,
    List<Briefing> briefings,
  ) {
    if (briefings.isEmpty) {
      return _buildEmptyView(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: briefings.length,
      itemBuilder: (context, index) {
        final briefing = briefings[index];
        final isToday = _isToday(briefing.date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BriefingCard(
            briefing: briefing,
            isToday: isToday,
            onTap: () => _navigateToDetail(context, briefing),
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 24),
          Text(
            '暂无简报',
            style: theme.typography.h3,
          ),
          const SizedBox(height: 8),
          Text(
            '稍后再来查看每日 AI 新闻简报',
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(height: 24),
            Text(
              '加载失败',
              style: theme.typography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              leading: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(briefingListProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _navigateToDetail(BuildContext context, Briefing briefing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BriefingDetailScreen(briefing: briefing),
      ),
    );
  }
}

/// Card widget for displaying a briefing item
class _BriefingCard extends StatelessWidget {
  final Briefing briefing;
  final bool isToday;
  final VoidCallback onTap;

  const _BriefingCard({
    required this.briefing,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM月dd日 EEEE', 'zh_CN');

    return Card(
      child: Clickable(
        onPressed: onTap,
        child: Container(
          decoration: isToday
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row with badges
                Row(
                  children: [
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '今日',
                            style: theme.typography.small.copyWith(
                              color: theme.colorScheme.primaryForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      dateFormat.format(briefing.date),
                      style: theme.typography.small.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (briefing.hasAudio)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.headphones,
                            size: 16,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            briefing.formattedDuration,
                            style: theme.typography.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  briefing.title,
                  style: theme.typography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Preview
                Text(
                  _getPreview(briefing.summary),
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Read more hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '阅读全文',
                      style: theme.typography.small.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get plain text preview from markdown
  String _getPreview(String markdown) {
    var text = markdown
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'---+'), '')
        .replaceAll('\n\n', '\n')
        .trim();

    return text;
  }
}
