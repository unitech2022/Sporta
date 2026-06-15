import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../state/auth_scope.dart';
import '../widgets/sports_selection_widgets.dart';

/// Post-login screen: pick a favorite sport (only Padel is available; the rest
/// are shown as "coming soon"). The choice is saved to the backend before
/// continuing. Rendered over a dark "night sky" gradient.
class SportsSelectionPage extends StatefulWidget {
  const SportsSelectionPage({super.key, required this.onContinue});

  /// Called after the favorite sport has been saved.
  final VoidCallback onContinue;

  @override
  State<SportsSelectionPage> createState() => _SportsSelectionPageState();
}

class _SportsSelectionPageState extends State<SportsSelectionPage> {
  static const _nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A1A), Color(0xFF0F1A2E), Color(0xFF0A1628)],
  );

  bool _saving = false;

  Future<void> _select(String sport) async {
    if (_saving) return;
    setState(() => _saving = true);
    final auth = context.auth;
    final ok = await auth.setFavoriteSport(sport);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      widget.onContinue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'حدث خطأ غير متوقع')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _nightGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: SportsStarsBackground()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                    vertical: AppSizes.xxl,
                  ),
                  child: _buildContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SportsHeaderBadge(label: 'اختر رياضتك المفضلة'),
        const SizedBox(height: AppSizes.xxl),
        Text(
          'مرحباً بك في SPORTA',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'لكل رياضة تجربة مخصصة في التطبيق',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: SportCard(
                emoji: '🎾',
                nameAr: 'البادل',
                nameEn: 'Padel',
                available: true,
                onTap: () => _select('padel'),
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            const Expanded(
              child: SportCard(
                emoji: '⚽',
                nameAr: 'كرة القدم',
                nameEn: 'Football',
                available: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xxl),
        const ComingSoonRow(),
        const SizedBox(height: AppSizes.xxxl),
        Text(
          'ندعوك للاستمتاع بالتجربة 🎯',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: AppSizes.xxxl),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _select('padel'),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('ابدأ تجربة البادل'),
          ),
        ),
      ],
    );
  }
}
