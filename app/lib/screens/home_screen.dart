import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/briefing.dart';
import '../models/category_briefing.dart';
import '../providers/auth_provider.dart';
import '../providers/briefing_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive.dart';
import '../widgets/briefing_cover.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/subscription_gate.dart';
import 'briefing_detail_screen.dart';
import 'category_briefing_screen.dart';
import 'paywall_screen.dart';

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
    // Settings tab has its own body
    if (_selectedNavIndex == 3) {
      return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: _buildSettingsView(context),
        bottomNavigationBar: _buildFloatingNavBar(context),
      );
    }

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

    // If a category is selected, show category view
    if (_selectedCategory != null) {
      return _buildCategoryContent(context, briefings, _selectedCategory!);
    }

    // Default: show all briefings
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

  Widget _buildCategoryContent(BuildContext context, List<Briefing> briefings, String category) {
    // Fetch category briefings for all dates
    final categoryBriefingsAsync = ref.watch(
      categoryBriefingsForCategoryProvider((briefings: briefings, category: category)),
    );

    return categoryBriefingsAsync.when(
      data: (categoryBriefings) {
        if (categoryBriefings.isEmpty) {
          return _buildCategoryEmptyState(category);
        }

        final featured = categoryBriefings.first;
        final recents = categoryBriefings.skip(1).toList();

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            
            SliverToBoxAdapter(
              child: _buildCategoryFilter(context),
            ),

            // Category Hero Section (like homepage)
            SliverToBoxAdapter(
              child: _buildCategoryHeroSection(context, featured, category),
            ),

            // Past Updates Header
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Past Updates'),
            ),

            // Category Briefing List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = recents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: _CategoryBriefingTile(
                      categoryBriefing: item.categoryBriefing,
                      date: item.date,
                    ).animate(delay: (80 * index).ms)
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut),
                  );
                },
                childCount: recents.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
      loading: () => CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildCategoryFilter(context)),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
        ],
      ),
      error: (error, stack) => CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildCategoryFilter(context)),
          SliverFillRemaining(child: _buildErrorState(error)),
        ],
      ),
    );
  }

  Widget _buildCategoryHeroSection(BuildContext context, CategoryBriefingWithDate featured, String category) {
    final categoryBriefing = featured.categoryBriefing;
    final date = featured.date;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryBriefingScreen(
              categoryBriefing: categoryBriefing,
              date: date,
            ),
          ),
        ),
        child: Container(
          height: Responsive.heroCardHeight(context),
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
              // Gradient Background
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withOpacity(0.8),
                        AppTheme.primaryAlt.withOpacity(0.6),
                      ],
                    ),
                  ),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryAlt],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DAILY',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      categoryBriefing.title!,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Text(
                      DateFormat('MMMM dd, yyyy').format(date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Play Button Row
                    Row(
                      children: [
                        Flexible(
                          child: categoryBriefing.hasAudio
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Iconsax.play, color: Colors.black, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Play Episode',
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${categoryBriefing.formattedDuration}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Iconsax.document_text, color: Colors.black, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Read',
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        _CircleButton(icon: Iconsax.save_add, size: 44),
                        const SizedBox(width: 6),
                        _CircleButton(icon: Iconsax.share, size: 44),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildCategoryEmptyState(String category) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(child: _buildCategoryFilter(context)),
        SliverFillRemaining(
          child: Center(
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
                  'No $category updates yet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back soon for updates in this category',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/ai-briefing.jpeg',
                fit: BoxFit.cover,
              ),
            ),
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
        _buildUserButton(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserButton(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final authService = ref.read(authServiceProvider);

    return userAsync.when(
      data: (user) {
        if (user != null) {
          // User is logged in - show avatar with menu
          final avatarUrl = user.userMetadata?['avatar_url'] as String?;
          final userName = user.userMetadata?['full_name'] ??
              user.userMetadata?['user_name'] ??
              'User';

          return PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppTheme.surfaceElevated,
            onSelected: (value) async {
              if (value == 'logout') {
                await authService.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Iconsax.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          );
        } else {
          // User is not logged in - show sign in button
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () => _showLoginDialog(context, authService),
              icon: const Icon(Iconsax.login, size: 18),
              label: const Text('Sign in'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                backgroundColor: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          );
        }
      },
      loading: () => const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Iconsax.login),
        onPressed: () => _showLoginDialog(context, authService),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.primary.withOpacity(0.2),
      child: Icon(
        Iconsax.user,
        size: 18,
        color: AppTheme.primary,
      ),
    );
  }

  void _showLoginDialog(BuildContext context, AuthService authService) {
    AuthDialog.show(context, authService);
  }

  Widget _buildCategoryFilter(BuildContext context) {
    // "All" + dynamic categories from CategoryBriefing
    final categories = ['all', ...CategoryBriefing.allCategories];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final label = category == 'all' ? 'All' : category;
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

  /// Get selected category (null means "all")
  String? get _selectedCategory {
    if (_selectedCategoryIndex == 0) return null;
    return CategoryBriefing.allCategories[_selectedCategoryIndex - 1];
  }

  // ─── Settings View ────────────────────────────────────────────

  Widget _buildSettingsView(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final userAsync = ref.watch(currentUserProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
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

                // Subscription status card
                subscriptionAsync.when(
                  data: (subscription) {
                    if (subscription != null && subscription.isActive) {
                      // Active subscriber
                      return _SettingsTile(
                        icon: Iconsax.crown_1,
                        iconColor: AppTheme.warning,
                        title: 'Pro Subscription',
                        subtitle: subscription.isCanceled
                            ? 'Cancels ${subscription.currentPeriodEnd != null ? DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd!) : 'soon'}'
                            : 'Active',
                        trailing: const _SettingsChevron(),
                        onTap: () => _openCustomerPortal(context),
                      );
                    } else {
                      // Not subscribed
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
                  loading: () => _SettingsTile(
                    icon: Iconsax.crown_1,
                    iconColor: AppTheme.textTertiary,
                    title: 'Subscription',
                    subtitle: 'Loading...',
                  ),
                  error: (_, __) => _SettingsTile(
                    icon: Iconsax.crown_1,
                    iconColor: AppTheme.textTertiary,
                    title: 'Subscription',
                    subtitle: 'Could not load status',
                  ),
                ),

                if (subscriptionAsync.maybeWhen(
                  data: (s) => s != null && s.isActive,
                  orElse: () => false,
                )) ...[
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.receipt_2,
                    iconColor: AppTheme.accent,
                    title: 'Manage Billing',
                    subtitle: 'View invoices, update payment method',
                    trailing: const _SettingsChevron(),
                    onTap: () => _openCustomerPortal(context),
                  ),
                ],

                const SizedBox(height: 32),

                // ─── Account Section ───
                Text(
                  'ACCOUNT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (isLoggedIn)
                  userAsync.maybeWhen(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      final userName = user.userMetadata?['full_name'] ??
                          user.userMetadata?['user_name'] ??
                          'User';
                      return _SettingsTile(
                        icon: Iconsax.user,
                        iconColor: AppTheme.primary,
                        title: userName,
                        subtitle: user.email ?? 'No email',
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

                if (isLoggedIn) ...[
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.logout,
                    iconColor: AppTheme.error,
                    title: 'Sign Out',
                    subtitle: 'Log out of your account',
                    trailing: const _SettingsChevron(),
                    onTap: () async {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully')),
                        );
                      }
                    },
                  ),
                ] else
                  _SettingsTile(
                    icon: Iconsax.login,
                    iconColor: AppTheme.primary,
                    title: 'Sign In',
                    subtitle: 'Log in to access all features',
                    trailing: const _SettingsChevron(),
                    onTap: () {
                      final authService = ref.read(authServiceProvider);
                      AuthDialog.show(context, authService);
                    },
                  ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCustomerPortal(BuildContext context) async {
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
    final heroHeight = Responsive.heroCardHeight(context);
    
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
          height: heroHeight,
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
                padding: const EdgeInsets.all(24),
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
                        const SizedBox(width: 10),
                        _CircleButton(icon: Iconsax.save_add, size: 48),
                        const SizedBox(width: 8),
                        _CircleButton(icon: Iconsax.share, size: 48),
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
  final double size;

  const _CircleButton({required this.icon, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.4),
    );
  }
}

class _BriefingListTile extends ConsumerWidget {
  final Briefing briefing;

  const _BriefingListTile({required this.briefing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => SubscriptionGate.navigateIfSubscribed(
          context,
          ref,
          BriefingDetailScreen(briefing: briefing),
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

/// List tile for category briefing
class _CategoryBriefingTile extends ConsumerWidget {
  final CategoryBriefing categoryBriefing;
  final DateTime date;

  const _CategoryBriefingTile({
    required this.categoryBriefing,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => SubscriptionGate.navigateIfSubscribed(
          context,
          ref,
          CategoryBriefingScreen(
            categoryBriefing: categoryBriefing,
            date: date,
          ),
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
              // Category Badge as Cover
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.primaryAlt],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(date),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      categoryBriefing.title!,
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
                          DateFormat('MMM dd, yyyy').format(date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (categoryBriefing.hasAudio) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Iconsax.headphone,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            categoryBriefing.formattedDuration,
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
                  categoryBriefing.hasAudio ? Iconsax.play : Iconsax.document_text,
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

    return GestureDetector(
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
    );
  }
}

/// Chevron arrow for settings tiles
class _SettingsChevron extends StatelessWidget {
  const _SettingsChevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Iconsax.arrow_right_3,
      color: AppTheme.textTertiary,
      size: 18,
    );
  }
}
