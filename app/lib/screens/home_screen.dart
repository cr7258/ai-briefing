import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../models/briefing.dart';
import '../providers/briefing_provider.dart';
import '../widgets/briefing_cover.dart';
import 'briefing_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingsAsync = ref.watch(briefingListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // For transparency behind navbar if we want
      body: briefingsAsync.when(
        data: (briefings) => _buildContent(context, briefings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          color: theme.scaffoldBackgroundColor.withOpacity(0.95), // Slight transparency
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Iconsax.home_1)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Iconsax.home_1, fill: 1.0)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Iconsax.discover_1)),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Iconsax.music_library_2)),
              label: 'Library',
            ),
             BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Iconsax.profile_circle)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Briefing> briefings) {
    if (briefings.isEmpty) {
      return const Center(child: Text("No briefings available"));
    }

    final featured = briefings.first;
    final recents = briefings.skip(1).toList();

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent, // Disable Material 3 tint
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.radar_2, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Briefing',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Category Filter (Mock)
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _CategoryChip(label: 'All Updates', isSelected: true),
                _CategoryChip(label: 'Generative AI'),
                _CategoryChip(label: 'Robotics'),
                _CategoryChip(label: 'Policy'),
                _CategoryChip(label: 'Research'),
              ],
            ),
          ),
        ),

        // Hero Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LATEST EPISODE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Iconsax.timer_1, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      featured.hasAudio ? featured.formattedDuration : '3 min',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HeroCard(briefing: featured)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),

        // Recent Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Past Updates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('View Archive'),
                ),
              ],
            ),
          ),
        ),

        // Recent List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final briefing = recents[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _BriefingListTile(briefing: briefing)
                    .animate(delay: (100 * index).ms)
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0),
              );
            },
            childCount: recents.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Briefing briefing;

  const _HeroCard({required this.briefing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BriefingDetailScreen(briefing: briefing)),
      ),
      child: Container(
        height: 420, // Taller for more impact
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Art Background
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BriefingCover(
                date: briefing.date,
                size: double.infinity,
                showTitle: false,
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.4),
                    const Color(0xFF121212).withOpacity(0.95), // Match bg color
                  ],
                  stops: const [0.2, 0.5, 0.95],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'DAILY DIGEST',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Text(
                          'AI NEWS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    briefing.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      height: 1.1,
                      fontSize: 26,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    DateFormat('MMMM dd, yyyy').format(briefing.date),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Row
                  Row(
                    children: [
                      // Play Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.play, color: Colors.black, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Play Episode',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (briefing.hasAudio) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${briefing.formattedDuration}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save Button
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Iconsax.save_add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingListTile extends StatelessWidget {
  final Briefing briefing;

  const _BriefingListTile({required this.briefing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BriefingDetailScreen(briefing: briefing)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.3), // More transparent
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'cover_list_${briefing.id}',
              child: BriefingCover(
                date: briefing.date,
                size: 72,
                showTitle: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    briefing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Iconsax.calendar_1, size: 14, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd').format(briefing.date),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(width: 12),
                      if (briefing.hasAudio) ...[
                        Icon(Iconsax.clock, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          briefing.formattedDuration,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Iconsax.play_circle, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
