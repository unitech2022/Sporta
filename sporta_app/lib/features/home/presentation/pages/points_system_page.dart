import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/points_banner.dart';

/// Points system explainer (converted from PointsSystemPage.tsx).
class PointsSystemPage extends StatefulWidget {
  const PointsSystemPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PointsSystemPage> createState() => _PointsSystemPageState();
}

class _PointsSystemPageState extends State<PointsSystemPage> {
  int? _openFaq;

  static const _tiers = [
    (
      'برونزي',
      '0 – 99 نقطة',
      '🥉',
      [Color(0xFFB45309), Color(0xFFD97706)],
      ['خصم 5% على الحجوزات', 'أولوية في القوائم'],
    ),
    (
      'فضي',
      '100 – 299 نقطة',
      '🥈',
      [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
      ['خصم 10% على الحجوزات', 'حصة تدريبية مجانية شهرياً', 'أولوية في التسجيل'],
    ),
    (
      'ذهبي',
      '300 – 999 نقطة',
      '🥇',
      [Color(0xFFEAB308), Color(0xFFFACC15)],
      ['خصم 15% على الحجوزات', 'حصتان مجانيتان شهرياً', 'دعوة البطولات الحصرية'],
    ),
    (
      'بلاتيني',
      '1,000 – 4,999 نقطة',
      '💎',
      [Color(0xFF06B6D4), Color(0xFF22D3EE)],
      ['خصم 20% على كل شيء', 'جلسات VIP', 'مدرب شخصي مجاني'],
    ),
    (
      'أسطوري',
      '5,000+ نقطة',
      '👑',
      [Color(0xFF9333EA), Color(0xFFEC4899)],
      ['جميع المزايا', 'دعوات خاصة', 'شارة حصرية في الملف الشخصي'],
    ),
  ];

  static const _levelBonus = [
    ('فاز بمباراة كاملة على نفس المستوى', '+3 نقاط',
        Color(0xFFDCFCE7), Color(0xFF15803D)),
    ('فاز بمباراة كاملة بخصم أقل من المستوى', '+1 نقطة',
        Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    ('فاز بمباراة كاملة بخصم أعلى من المستوى', '+5 نقاط',
        Color(0xFFF3E8FF), Color(0xFF7E22CE)),
  ];

  static const _earningWays = [
    (Icons.emoji_events_outlined, 'لكل مباراة تلعبها', '+1 نقطة',
        Color(0xFFDCFCE7), Color(0xFF16A34A)),
    (Icons.access_time, 'لكل ساعة تدريبية تحضرها', '+1 نقطة تدريبية',
        Color(0xFFDBEAFE), Color(0xFF2563EB)),
    (Icons.menu_book_outlined, 'لكل حجز ملعب تنفذه', '+1 نقطة',
        Color(0xFFEDE9FE), Color(0xFF7C3AED)),
    (Icons.bolt, 'لكل بطولة تنضم إليها', '+5 نقاط',
        Color(0xFFFFEDD5), Color(0xFFEA580C)),
    (Icons.star_outline, 'دعوة لاعب جديد للتطبيق', '+3 نقاط',
        Color(0xFFFCE7F3), Color(0xFFDB2777)),
    (Icons.card_giftcard, 'تقييم (مدرب – ملعب – التطبيق)', '+2 نقطتان',
        Color(0xFFCCFBF1), Color(0xFF0D9488)),
  ];

  static const _faqs = [
    (
      'كيف أستخدم النقاط؟',
      'يمكنك استبدال النقاط بخصومات على الحجوزات أو الحصص التدريبية مباشرةً عند الدفع.'
    ),
    (
      'هل أخسر نقاطاً عند الإلغاء؟',
      'نعم، عند إلغاء حجز بعد انتهاء المدة المسموحة يُخصم نقطتان من رصيدك.'
    ),
    (
      'هل يمكن تحويل النقاط لشخص آخر؟',
      'حالياً النقاط غير قابلة للتحويل وهي مرتبطة بحسابك الشخصي فقط.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                children: [
                  _sectionCard(
                    icon: Icons.military_tech_outlined,
                    iconBackground: const Color(0xFFFEF9C3),
                    iconColor: const Color(0xFFCA8A04),
                    title: 'مستويات اللاعب',
                    subtitle: 'بناءً على نتائج المباريات التي تلعبها',
                    child: Column(
                      children: [
                        for (final (name, range, emoji, colors, perks)
                            in _tiers) ...[
                          _tierCard(name, range, emoji, colors, perks),
                          if ((name, range, emoji, colors, perks) !=
                              _tiers.last)
                            const SizedBox(height: AppSizes.md),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  _sectionCard(
                    icon: Icons.track_changes,
                    iconBackground:
                        AppColors.primary.withValues(alpha: 0.1),
                    iconColor: AppColors.primary,
                    title: 'مضاعفات النقاط',
                    subtitle: 'بناءً على نتائج المباريات التي تلعبها',
                    child: Column(
                      children: [
                        for (final (label, points, bg, fg)
                            in _levelBonus) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.md,
                                      vertical: AppSizes.xs),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLg),
                                  ),
                                  child: Text(points,
                                      style: AppTextStyles.heading3
                                          .copyWith(color: fg)),
                                ),
                                SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Text(label,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color: AppColors.secondary)),
                                ),
                              ],
                            ),
                          ),
                          if ((label, points, bg, fg) != _levelBonus.last)
                            const SizedBox(height: AppSizes.sm),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  _sectionCard(
                    icon: Icons.bolt,
                    iconBackground: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    title: 'نقاط نشاط اللاعب',
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSizes.md,
                      crossAxisSpacing: AppSizes.md,
                      childAspectRatio: 1.45,
                      children: [
                        for (final (icon, label, points, bg, fg)
                            in _earningWays)
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusXl),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusLg),
                                  ),
                                  child: Icon(icon,
                                      size: AppSizes.iconSm, color: fg),
                                ),
                                const Spacer(),
                                Text(label,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.secondary)),
                                SizedBox(height: AppSizes.xs),
                                Text(points,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXl + 8),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                          ),
                          child: const Icon(Icons.warning_amber_rounded,
                              size: AppSizes.iconSm,
                              color: AppColors.destructive),
                        ),
                        SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تنبيه الإلغاء',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFFB91C1C))),
                              SizedBox(height: AppSizes.xs),
                              Text(
                                'عند إلغاء الحجز بعد انتهاء المدة المتاحة للإلغاء يُخصم نقطتان من رصيدك.',
                                style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  _sectionCard(
                    icon: Icons.shield_outlined,
                    iconBackground: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: 'الأسئلة الشائعة',
                    child: Column(
                      children: [
                        for (var i = 0; i < _faqs.length; i++) ...[
                          _faqTile(i),
                          if (i != _faqs.length - 1)
                            const SizedBox(height: AppSizes.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration:
          const BoxDecoration(gradient: PointsBanner.nightGradient),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        40,
        AppSizes.pagePadding,
        80,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.1),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onBack,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.chevron_right,
                        size: AppSizes.iconMd, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Text('الرئيسية',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: AppSizes.xxxl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFACC15), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events,
                size: 40, color: Colors.white),
          ),
          SizedBox(height: AppSizes.lg),
          Text('نظام النقاط',
              style: AppTextStyles.heading1
                  .copyWith(fontSize: 30, color: Colors.white)),
          SizedBox(height: AppSizes.sm),
          Text(
            'اكسب نقاطاً مع كل نشاط وارتقِ للمستويات الأعلى للحصول على مزايا حصرية',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
              ),
              SizedBox(width: AppSizes.sm),
              Text(title,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.secondary)),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSizes.sm),
            Text(subtitle, style: AppTextStyles.caption),
          ],
          SizedBox(height: AppSizes.lg),
          child,
        ],
      ),
    );
  }

  Widget _tierCard(String name, String range, String emoji,
      List<Color> colors, List<String> perks) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(range,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8))),
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  SizedBox(width: AppSizes.sm),
                  Text(name,
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSizes.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: [
                for (final perk in perks)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(perk,
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(int index) {
    final (question, answer) = _faqs[index];
    final open = _openFaq == index;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _openFaq = open ? null : index),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(question,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondary)),
                  ),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: open
                        ? AppColors.primary
                        : const Color(0xFFF3F4F6),
                    child: Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 14,
                      color: open
                          ? Colors.white
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(answer, style: AppTextStyles.caption),
              ),
            ),
        ],
      ),
    );
  }
}
