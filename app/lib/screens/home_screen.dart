import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../models/briefing.dart';
import '../providers/briefing_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/briefing_cover.dart';
import 'briefing_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final briefingsAsync = ref.watch(briefingListProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: briefingsAsync.when(
        data: (briefings) => _buildContent(context, briefings),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
      bottomNavigationBar: _buildFloatingNavBar(context),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading briefings...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                color: AppTheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(briefingListProvider),
              icon: const Icon(Iconsax.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Iconsax.home_2,
                  activeIcon: Iconsax.home,
                  label: 'Home',
                  isSelected: _selectedNavIndex == 0,
                  onTap: () => setState(() => _selectedNavIndex = 0),
                ),
                _NavItem(
                  icon: Iconsax.discover_1,
                  activeIcon: Iconsax.discover,
                  label: 'Discover',
                  isSelected: _selectedNavIndex == 1,
                  onTap: () => setState(() => _selectedNavIndex = 1),
                ),
                _NavItem(
                  icon: Iconsax.archive_1,
                  activeIcon: Iconsax.archive,
                  label: 'Archive',
                  isSelected: _selectedNavIndex == 2,
                  onTap: () => setState(() => _selectedNavIndex = 2),
                ),
                _NavItem(
                  icon: Iconsax.setting_2,
                  activeIcon: Iconsax.setting,
                  label: 'Settings',
                  isSelected: _selectedNavIndex == 3,
                  onTap: () => setState(() => _selectedNavIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Briefing> briefings) {
    if (briefings.isEmpty) {
      return _buildEmptyState();
    }

    final featured = briefings.first;
    final recents = briefings.skip(1).toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        _buildAppBar(context),

        // Category Filter
        SliverToBoxAdapter(
          child: _buildCategoryFilter(context),
        ),

        // Hero Section
        SliverToBoxAdapter(
          child: _buildHeroSection(context, featured),
        ),

        // Recent Section Header
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Past Updates'),
        ),

        // Recent List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final briefing = recents[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: _BriefingListTile(briefing: briefing)
                    .animate(delay: (80 * index).ms)
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideX(begin: 0.05, end: 0, curve: Curves.easeOut),
              );
            },
            childCount: recents.length,
          ),
        ),
        
        // Bottom padding for nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.document,
              color: AppTheme.textTertiary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No briefings yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for your daily AI updates',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      expandedHeight: 70,
      backgroundColor: AppTheme.background.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Iconsax.cpu, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Briefing',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Daily AI News',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.search_normal_1),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Iconsax.notification),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final categories = ['All', 'LLMs', 'Agents', 'Research', 'Industry', 'Open Source'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedCategoryIndex == index;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryAlt],
                        )
                      : null,
                  color: isSelected ? null : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Briefing featured) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.flash_1, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'LATEST',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (featured.hasAudio)
                Row(
                  children: [
                    Icon(Iconsax.headphone, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      featured.formattedDuration,
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _HeroCard(briefing: featured)
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('View All'),
                const SizedBox(width: 4),
                Icon(Iconsax.arrow_right_3, size: 16, color: AppTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                BriefingDetailScreen(briefing: briefing),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Art Background
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BriefingCover(
                  date: briefing.date,
                  size: double.infinity,
                  showTitle: false,
                  showWaveform: true,
                ),
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tags Row
                    Row(
                      children: [
                        _Tag(
                          label: 'DAILY DIGEST',
                          isPrimary: true,
                        ),
                        const SizedBox(width: 8),
                        _Tag(label: 'AI NEWS'),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      briefing.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      DateFormat('MMMM dd, yyyy').format(briefing.date),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Row
                    Row(
                      children: [
                        Expanded(
                          child: _PlayButton(
                            duration: briefing.hasAudio ? briefing.formattedDuration : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CircleButton(icon: Iconsax.save_add),
                        const SizedBox(width: 8),
                        _CircleButton(icon: Iconsax.share),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _Tag({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryAlt])
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? Colors.black : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final String? duration;

  const _PlayButton({this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.play, color: Colors.black, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Play Episode',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (duration != null) ...[
            const SizedBox(width: 8),
            Text(
              '• $duration',
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;

  const _CircleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _BriefingListTile extends StatelessWidget {
  final Briefing briefing;

  const _BriefingListTile({required this.briefing});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BriefingDetailScreen(briefing: briefing)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'cover_${briefing.id}',
                child: BriefingCover(
                  date: briefing.date,
                  size: 68,
                  showTitle: true,
                  showWaveform: false,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd').format(briefing.date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (briefing.hasAudio) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Iconsax.headphone,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 6),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceVariant,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Icon(
                  Iconsax.play,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
