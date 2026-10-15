import 'package:flutter/material.dart';

import '../core/state/app_scope.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../features/auth/presentation/pages/guest_account_page.dart';
import '../features/coaches/presentation/pages/coaches_page.dart';
import '../features/courts/presentation/pages/court_detail_page.dart';
import '../features/courts/presentation/pages/courts_page.dart';
import '../features/matches/presentation/pages/matches_page.dart';
import '../features/settings/presentation/pages/contact_us_page.dart';
import '../features/settings/presentation/pages/language_settings_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../features/settings/presentation/pages/refund_policy_page.dart';
import '../features/settings/presentation/pages/terms_page.dart';

/// شل الزائر: تصفّح بلا حساب — الملاعب والمباريات والمدربون، مع تبويب «حسابي»
/// يدعو لتسجيل الدخول. مطلوب لتلبية App Store 5.1.1: الميزات غير المرتبطة
/// بحساب يجب أن تكون متاحة بلا تسجيل. أي إجراء يخص حساباً يمر عبر
/// `guestBlocked` فيعرض دعوة تسجيل الدخول.
class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    CourtsPage(onNavigateToCourt: _openCourt),
    const MatchesPage(),
    const CoachesPage(),
    GuestAccountPage(onNavigate: _navigate),
  ];

  /// الزائر لا يحجز، فلمس الملعب يفتح تفاصيله؛ زر الحجز داخلها يطلب التسجيل.
  void _openCourt(String courtId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourtDetailPage(courtId: courtId),
      ),
    );
  }

  void _navigate(String page) {
    void pop() => Navigator.of(context).pop();
    final builder = switch (page) {
      'language' => (_) => LanguageSettingsPage(onBack: pop),
      'contact' => (_) => ContactUsPage(onBack: pop),
      'terms' => (_) => TermsPage(onBack: pop),
      'privacy' => (_) => PrivacyPolicyPage(onBack: pop),
      'refund' => (_) => RefundPolicyPage(onBack: pop),
      _ => null,
    } as WidgetBuilder?;
    if (builder == null) return;
    // هذه الصفحات ترسم رأسها وجسمها بلا Scaffold، فتحتاج أصل Material شفافاً.
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: builder(ctx),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          AppBottomNavItem(
              icon: Icons.calendar_today_outlined,
              label: context.tr('courts')),
          AppBottomNavItem(
              icon: Icons.emoji_events_outlined,
              label: context.tr('matches')),
          AppBottomNavItem(
              icon: Icons.menu_book_outlined, label: context.tr('coaches')),
          AppBottomNavItem(
              icon: Icons.person_outline, label: context.tr('حسابي')),
        ],
      ),
    );
  }
}
