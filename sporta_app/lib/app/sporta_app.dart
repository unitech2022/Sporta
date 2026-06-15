import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/state/app_scope.dart';
import '../core/state/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/pages/auth_flow_page.dart';
import '../features/auth/presentation/pages/sports_selection_page.dart';
import '../features/auth/presentation/state/auth_notifier.dart';
import '../features/auth/presentation/state/auth_scope.dart';
import '../features/level/presentation/pages/level_assessment_page.dart';
import 'main_shell.dart';

class SportaApp extends StatefulWidget {
  const SportaApp({super.key});

  @override
  State<SportaApp> createState() => _SportaAppState();
}

class _SportaAppState extends State<SportaApp> {
  final _settings = AppSettings();
  late final _auth = AuthNotifier(_settings);

  @override
  void initState() {
    super.initState();
    _auth.checkSavedSession();
  }

  @override
  void dispose() {
    _auth.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      child: AuthScope(
        auth: _auth,
        child: ListenableBuilder(
          listenable: Listenable.merge([_settings, _auth]),
          builder: (context, _) => MaterialApp(
            title: 'Sporta',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: Locale(_settings.language.name),
            builder: (context, child) => Directionality(
              textDirection: _settings.language.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            ),
            home: const _AppEntry(),
          ),
        ),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _loggedIn = false;

  /// Set when a player chooses to postpone the level assessment; lets them into
  /// the app for this session (an in-app reminder prompts them to finish it).
  bool _levelAssessmentSkipped = false;

  Future<void> _logout() async {
    await context.auth.logout();
    if (mounted) {
      setState(() {
        _loggedIn = false;
        _levelAssessmentSkipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;

    // Show splash while checking saved session.
    if (auth.isCheckingSession) {
      return const _SplashScreen();
    }

    if (auth.isAuthenticated || _loggedIn) {
      final user = auth.user;

      // Players first pick their favorite sport (required to know which
      // assessment to run), then determine their level. Both run after
      // registration and after any login/session restore.
      if (user != null && user.isPlayer && user.favoriteSport == null) {
        return SportsSelectionPage(onContinue: () => setState(() {}));
      }

      // Level assessment. Tapping back postpones it: the player enters the app
      // and a persistent in-app reminder is shown until they finish it.
      if (user != null &&
          user.isPlayer &&
          !user.levelAssessed &&
          !_levelAssessmentSkipped) {
        return LevelAssessmentPage(
          sport: user.favoriteSport ?? 'padel',
          onComplete: () => setState(() {}),
          onBack: () => setState(() => _levelAssessmentSkipped = true),
        );
      }
      return MainShell(onLogout: _logout);
    }

    return AuthFlowPage(
      onLoginSuccess: () => setState(() => _loggedIn = true),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Image.asset(
          'assets/images/sporta_logo_white.png',
          width: 120,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }
}
