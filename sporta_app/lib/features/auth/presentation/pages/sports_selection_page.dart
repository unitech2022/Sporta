import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../state/auth_scope.dart';

/// Post-login screen: pick a favorite sport (only Padel is available; the rest
/// are shown as "coming soon" and are not selectable). The choice is saved to
/// the backend before continuing. Rendered over a dark "night sky" gradient.
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
            const Positioned.fill(child: _StarsBackground()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                    vertical: AppSizes.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    _HeaderBadge(label: 'اختر رياضتك المفضلة'),
                    SizedBox(height: AppSizes.xxl),
                    Text(
                      'مرحباً بك في SPORTA',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1
                          .copyWith(color: Colors.white),
                    ),
                    SizedBox(height: AppSizes.sm),
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
                          child: _SportCard(
                            emoji: '🎾',
                            nameAr: 'البادل',
                            nameEn: 'Padel',
                            available: true,
                            onTap: () => _select('padel'),
                          ),
                        ),
                        SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: _SportCard(
                            emoji: '⚽',
                            nameAr: 'كرة القدم',
                            nameEn: 'Football',
                            available: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.xxl),
                    const _ComingSoonRow(),
                    SizedBox(height: AppSizes.xxxl),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsBackground extends StatelessWidget {
  const _StarsBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarsPainter());
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 20; i++) {
      final dx = size.width * ((3 + (i * 17.3) % 94) / 100);
      final dy = size.height * ((5 + (i * 13.7) % 80) / 100);
      paint.color =
          Colors.white.withValues(alpha: 0.3 + (i % 4) * 0.15);
      canvas.drawCircle(Offset(dx, dy), i % 3 == 0 ? 1.5 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSizes.sm),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.emoji,
    required this.nameAr,
    required this.nameEn,
    required this.available,
    this.onTap,
  });

  final String emoji;
  final String nameAr;
  final String nameEn;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: available
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 8),
        side: BorderSide(
          color: available
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 8),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _AvailabilityTag(available: available),
              ),
              SizedBox(height: AppSizes.sm),
              Text(emoji, style: const TextStyle(fontSize: 48)),
              SizedBox(height: AppSizes.md),
              Text(
                nameAr,
                style: AppTextStyles.body.copyWith(
                  color: available
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                nameEn,
                style: AppTextStyles.caption.copyWith(
                  color: available
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return available ? card : Opacity(opacity: 0.7, child: card);
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: available
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        available ? 'متاح' : 'قريباً',
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'قريباً',
              style: AppTextStyles.caption
                  .copyWith(color: const Color(0xFFD8B4FE)),
            ),
          ),
          Row(
            children: [
              const _MiniSportCircle(emoji: '🎾', color: Color(0xFFEAB308)),
              SizedBox(width: AppSizes.xs),
              const _MiniSportCircle(emoji: '🏀', color: Color(0xFFF97316)),
              SizedBox(width: AppSizes.xs),
              const _MiniSportCircle(emoji: '🏊', color: Color(0xFF3B82F6)),
              SizedBox(width: AppSizes.xs),
              _MiniSportCircle(
                emoji: '+',
                color: Colors.white.withValues(alpha: 0.4),
              ),
              SizedBox(width: AppSizes.md),
              Text(
                'رياضات أخرى',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSportCircle extends StatelessWidget {
  const _MiniSportCircle({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}
