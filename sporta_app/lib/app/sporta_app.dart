import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_colors.dart';
import '../core/di/service_locator.dart';
import '../core/push/push_service.dart';
import '../core/state/app_scope.dart';
import '../core/state/app_settings.dart';
import '../core/storage/secure_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/updates/app_update_checker.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/pages/account_suspended_page.dart';
import '../features/auth/presentation/pages/auth_flow_page.dart';
import '../features/auth/presentation/pages/device_enroll_page.dart';
import '../features/auth/presentation/pages/registration_success_page.dart';
import '../features/auth/presentation/pages/sports_selection_page.dart';
import '../features/auth/presentation/state/auth_scope.dart';
import '../features/level/presentation/pages/level_assessment_page.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/setting_entity.dart';
import '../features/settings/presentation/pages/maintenance_page.dart';
import '../features/settings/presentation/pages/update_required_page.dart';
import 'guest_shell.dart';
import 'main_shell.dart';

class SportaApp extends StatefulWidget {
  const SportaApp({super.key});

  @override
  State<SportaApp> createState() => _SportaAppState();
}

class _SportaAppState extends State<SportaApp> {
  // App-wide singletons (owned by the service locator, not disposed here).
  final AppSettings _settings = getIt<AppSettings>();
  final AuthCubit _auth = getIt<AuthCubit>();

  @override
  void initState() {
    super.initState();
    _auth.checkSavedSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: _auth,
      child: AppScope(
        settings: _settings,
        // Rebuild the app when the language (settings) or auth session changes.
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => BlocBuilder<AuthCubit, AuthState>(
            builder: (context, _) => MaterialApp(
              // Changing the generation (restartApp) recreates the whole tree —
              // navigator stack included — so the app reopens from the splash.
              key: ValueKey('app-${_settings.appGeneration}'),
              title: 'Sporta',
              navigatorKey: PushService.navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: Locale(_settings.language.name),
              builder: (context, child) => Directionality(
                textDirection: _settings.language.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
              home: const _MaintenanceGate(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blocks the whole app behind [MaintenancePage] when the admin has enabled
/// `in_maintenance`, or behind [UpdateRequiredPage] when the admin has raised
/// `version_android` / `version_ios` above the installed version. Fails open
/// (shows the app) if the check errors out, so a flaky settings request never
/// locks users out.
class _MaintenanceGate extends StatefulWidget {
  const _MaintenanceGate();

  @override
  State<_MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<_MaintenanceGate> {
  bool _maintenance = false;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    var settings = const <String, SettingEntity>{};
    try {
      settings = await getIt<SettingsRepository>().fetchPublicSettings();
      final flag = settings['in_maintenance']?.boolValue ?? false;
      if (mounted && flag) {
        setState(() => _maintenance = true);
        return;
      }
    } catch (_) {
      // Fail open — don't block the app if settings can't be fetched.
    }

    // Admin-controlled forced update (dashboard raises the min version).
    if (await AppUpdateChecker.isUpdateRequired(settings)) {
      if (mounted) setState(() => _updateRequired = true);
      return;
    }

    // Fire-and-forget: courtesy flexible update from Google Play when a newer
    // build is published (downloads in the background, installs when done).
    AppUpdateChecker.check(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_maintenance) return const MaintenancePage();
    if (_updateRequired) return const UpdateRequiredPage();
    return const _AppEntry();
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

  /// هل هذا الهاتف مسجَّل جهازاً موثوقاً لصاحب الجلسة؟ `null` = لم يُفحص بعد.
  /// الفحص هنا لا في [AuthFlowPage]: بمجرد أن تبدأ الجلسة يستبدل هذا الودجت
  /// شاشات الدخول كلها، فشاشة تسجيل البصمة داخلها لا تُعرض أصلاً.
  bool? _deviceEnrolled;
  bool _checkingDevice = false;

  Future<void> _checkDeviceEnrollment(String phone) async {
    if (_checkingDevice) return;
    _checkingDevice = true;
    final cred = await SecureStorage.getDeviceCredential();
    if (!mounted) return;
    setState(() {
      _deviceEnrolled = cred != null && cred.phone == phone;
      _checkingDevice = false;
    });
  }

  /// The server rejected the session mid-use: close any pages opened on top of
  /// the shell, drop the local "logged in" flags (else `_loggedIn` keeps the
  /// shell up with no user) and say why the user is back on login.
  bool _handlingExpiry = false;

  void _handleSessionExpired() {
    if (!mounted || _handlingExpiry) return;
    _handlingExpiry = true;
    PushService.navigatorKey.currentState?.popUntil((r) => r.isFirst);
    setState(() {
      _loggedIn = false;
      _levelAssessmentSkipped = false;
      _deviceEnrolled = null;
    });
    final message = context.tr('انتهت جلستك، سجّل الدخول من جديد');
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
    context.read<AuthCubit>().acknowledgeSessionExpired();
    _handlingExpiry = false;
  }

  Future<void> _logout() async {
    await context.auth.logout();
    if (mounted) {
      setState(() {
        _loggedIn = false;
        _levelAssessmentSkipped = false;
        _deviceEnrolled = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch (not read) so this entry rebuilds when the auth session changes —
    // e.g. when checkSavedSession finishes and clears the splash.
    final auth = context.watch<AuthCubit>();

    if (auth.state.sessionExpired) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _handleSessionExpired());
    }

    // Account suspended by an admin — block the whole app with the support screen.
    if (auth.accountDisabled) {
      return const AccountSuspendedPage();
    }

    // Show splash while checking saved session.
    if (auth.isCheckingSession) {
      return const _SplashScreen();
    }

    // وضع الزائر: تصفّح بلا حساب (App Store 5.1.1). يسبق شاشة الترحيب ويأتي
    // بعد فحص الجلسة، فلا يظهر إن كان للمستخدم جلسة محفوظة.
    if (auth.isGuest && !auth.isAuthenticated && !_loggedIn) {
      return const GuestShell();
    }

    if (auth.isAuthenticated || _loggedIn) {
      final user = auth.user;

      // تسجيل البصمة أولاً: الجلسة قائمة لكن الهاتف لم يُربط بالحساب بعد،
      // فبدونه يعود صاحبه إلى رمز واتساب في كل دخول.
      if (user != null) {
        if (_deviceEnrolled == null) {
          _checkDeviceEnrollment(user.phone);
          return const _SplashScreen();
        }
        if (_deviceEnrolled == false) {
          return DeviceEnrollPage(
            onDone: () => setState(() => _deviceEnrolled = true),
            // تخطٍّ لهذه الجلسة وحدها: الجهاز يبقى غير موثوق، فيعود صاحبه
            // برمز واتساب في الدخول القادم، ولا يقف أمام شاشة بلا مخرج.
            onSkip: () => setState(() => _deviceEnrolled = true),
          );
        }

        // حساب أُنشئ للتو: «تم إنشاء حسابك» وأدواره وخطواته التالية. حساب
        // المدرب/الملعب بلا دور لاعب لا يدخل التطبيق قبل موافقة الأدمن.
        if (auth.justRegistered) {
          return RegistrationSuccessPage(
            roles: {...user.roles, ...user.pendingRoles},
            onStart: () => context.auth.acknowledgeRegistration(),
            onBackToLogin: _logout,
          );
        }
      }

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
