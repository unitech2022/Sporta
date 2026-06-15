import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tinted_card.dart';
import 'dashboard_blocks.dart';

const _green = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _blue = Color(0xFF3B82F6);
const _blueDark = Color(0xFF2563EB);
const _yellow = Color(0xFFEAB308);
const _orange = Color(0xFFF97316);

/// Coach home dashboard (converted from CoachHomePage.tsx).
class CoachDashboard extends StatelessWidget {
  const CoachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardHeader(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [_green, _greenDark],
          ),
          userName: 'أحمد السعيد',
          roleLabel: 'مدرب',
          stats: [
            ('24', 'طلاب نشطين'),
            ('4.8', 'التقييم'),
            ('156', 'حصة مكتملة'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نظرة عامة',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSizes.lg),
              const Row(
                children: [
                  Expanded(
                    child: OverviewStatCard(
                      icon: Icons.attach_money,
                      color: _greenDark,
                      value: '3,200 ر.س',
                      label: 'إيرادات هذا الشهر',
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OverviewStatCard(
                      icon: Icons.menu_book_outlined,
                      color: _blueDark,
                      value: '8',
                      label: 'حصص هذا الأسبوع',
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('طلبات جديدة',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.secondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text('3 طلبات',
                        style: AppTextStyles.caption
                            .copyWith(color: const Color(0xFFDC2626))),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              const _SessionRequestCard(
                name: 'سعد أحمد',
                request: 'يريد حصة تدريبية',
                avatarColor: AppColors.primary,
                time: 'غداً، 5:00 مساءً',
                price: '150 ر.س',
                highlighted: true,
              ),
              SizedBox(height: AppSizes.md),
              const _SessionRequestCard(
                name: 'محمد علي',
                request: 'يريد حصة جماعية',
                avatarColor: _green,
                time: 'الجمعة، 7:00 مساءً',
                price: '100 ر.س',
              ),
              SizedBox(height: AppSizes.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الحصص القادمة',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.secondary)),
                  Text('عرض الكل',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              SizedBox(height: AppSizes.lg),
              BookingInfoCard(
                tint: _green,
                header: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حصة تدريبية خاصة',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500)),
                          Text('مع أحمد محمد',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text('مؤكدة',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white)),
                    ),
                  ],
                ),
                time: 'اليوم، 5:00 مساءً',
                price: '150 ر.س',
                priceColor: _greenDark,
              ),
              SizedBox(height: AppSizes.md),
              BookingInfoCard(
                header: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حصة جماعية',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500)),
                          Text('4 طلاب', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text('مؤكدة',
                          style: AppTextStyles.caption
                              .copyWith(color: _blueDark)),
                    ),
                  ],
                ),
                time: 'غداً، 7:00 مساءً',
                price: '400 ر.س',
              ),
              SizedBox(height: AppSizes.xxl),
              Text('آخر التقييمات',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSizes.lg),
              const _ReviewCard(
                name: 'أحمد عبدالله',
                avatarColor: _yellow,
                stars: 5,
                time: 'منذ يومين',
                comment: '"مدرب ممتاز، استفدت كثيراً من الحصص معه"',
                tinted: true,
              ),
              const SizedBox(height: AppSizes.md),
              const _ReviewCard(
                name: 'محمد سعد',
                avatarColor: _blue,
                stars: 4,
                time: 'منذ 3 أيام',
                comment: '"تجربة جيدة وتطور ملحوظ"',
              ),
              const SizedBox(height: AppSizes.xxl),
              const QuickActionsRow(
                primaryIcon: Icons.group_outlined,
                primaryLabel: 'إدارة الطلاب',
                secondaryIcon: Icons.trending_up,
                secondaryLabel: 'التقارير',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionRequestCard extends StatelessWidget {
  const _SessionRequestCard({
    required this.name,
    required this.request,
    required this.avatarColor,
    required this.time,
    required this.price,
    this.highlighted = false,
  });

  final String name;
  final String request;
  final Color avatarColor;
  final String time;
  final String price;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: highlighted ? const Color(0xFFFED7AA) : AppColors.border,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor,
                child: Text(name.characters.first,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 18)),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500)),
                    Text(request, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _actionButton(Icons.check_circle_outline,
                  const Color(0xFFDCFCE7), _greenDark),
              SizedBox(width: AppSizes.sm),
              _actionButton(Icons.cancel_outlined, const Color(0xFFFEE2E2),
                  const Color(0xFFDC2626)),
            ],
          ),
          SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.mutedForeground),
                  SizedBox(width: AppSizes.sm),
                  Text(time, style: AppTextStyles.caption),
                ],
              ),
              Text(price,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color background, Color foreground) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Icon(icon, size: AppSizes.iconMd, color: foreground),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.avatarColor,
    required this.stars,
    required this.time,
    required this.comment,
    this.tinted = false,
  });

  final String name;
  final Color avatarColor;
  final int stars;
  final String time;
  final String comment;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: Text(name.characters.first,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(Icons.star,
                            size: 12,
                            color: i < stars
                                ? _yellow
                                : const Color(0xFFD1D5DB)),
                    ],
                  ),
                ],
              ),
            ),
            Text(time, style: AppTextStyles.caption),
          ],
        ),
        SizedBox(height: AppSizes.sm),
        Text(comment,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.secondary)),
      ],
    );

    if (tinted) return TintedCard(tint: _orange, child: body);
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: body,
    );
  }
}
