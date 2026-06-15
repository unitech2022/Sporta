import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_text_styles.dart';
import '../core/state/app_scope.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../features/auth/presentation/state/auth_scope.dart';
import '../features/coaches/presentation/pages/coaches_page.dart';
import '../features/courts/presentation/pages/courts_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/level/presentation/pages/level_assessment_page.dart';
import '../features/matches/presentation/pages/matches_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

/// Root shell with the bottom navigation bar (tab order matches App.tsx:
/// home, profile, matches, courts, coaches).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    ProfilePage(onLogout: widget.onLogout),
    const MatchesPage(),
    const CourtsPage(),
    const CoachesPage(),
  ];

  void _openLevelAssessment() {
    final sport = context.auth.user?.favoriteSport ?? 'padel';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelAssessmentPage(
          sport: sport,
          onComplete: () => Navigator.of(context).pop(),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      AppBottomNavItem(icon: Icons.home_outlined, label: context.tr('home')),
      AppBottomNavItem(icon: Icons.person_outline, label: context.tr('profile')),
      AppBottomNavItem(
          icon: Icons.emoji_events_outlined, label: context.tr('matches')),
      AppBottomNavItem(
          icon: Icons.calendar_today_outlined, label: context.tr('courts')),
      AppBottomNavItem(
          icon: Icons.menu_book_outlined, label: context.tr('coaches')),
    ];

    final user = context.auth.user;
    final showLevelReminder =
        user != null && user.isPlayer && !user.levelAssessed;

    return Scaffold(
      body: Column(
        children: [
          if (showLevelReminder)
            _LevelReminderBanner(onTap: _openLevelAssessment),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Persistent top banner shown across all tabs while a player hasn't completed
/// their level self-assessment. Tapping it opens the assessment.
class _LevelReminderBanner extends StatelessWidget {
  const _LevelReminderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    context.tr('completeLevelBanner'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                const Icon(Icons.chevron_left,
                    color: Colors.white, size: AppSizes.iconMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
