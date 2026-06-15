import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tinted_card.dart';
import 'dashboard_blocks.dart';

const _green = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _blueDark = Color(0xFF2563EB);
const _orange = Color(0xFFF97316);

/// Venue owner home dashboard (converted from VenueHomePage.tsx).
class VenueDashboard extends StatelessWidget {
  const VenueDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardHeader(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [_blueDark, Color(0xFF1D4ED8)],
          ),
          userName: 'أحمد السعيد',
          roleLabel: 'مالك ملعب',
          stats: [
            ('6', 'ملاعب'),
            ('89%', 'نسبة الحجز'),
            ('4.6', 'التقييم'),
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
                      value: '8,400 ر.س',
                      label: 'إيرادات هذا الأسبوع',
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OverviewStatCard(
                      icon: Icons.calendar_today_outlined,
                      color: _blueDark,
                      value: '42',
                      label: 'حجوزات اليوم',
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('حالة الملاعب الآن',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.secondary)),
                  Text('تحديث مباشر', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSizes.md,
                crossAxisSpacing: AppSizes.md,
                childAspectRatio: 1.7,
                children: const [
                  _CourtStatusCard(
                      name: 'ملعب 1',
                      status: _CourtStatus.booked,
                      detail: '4:00 - 5:30 مساءً'),
                  _CourtStatusCard(
                      name: 'ملعب 2',
                      status: _CourtStatus.booked,
                      detail: '6:00 - 7:30 مساءً'),
                  _CourtStatusCard(
                      name: 'ملعب 3',
                      status: _CourtStatus.available,
                      detail: 'متاح للحجز'),
                  _CourtStatusCard(
                      name: 'ملعب 4',
                      status: _CourtStatus.maintenance,
                      detail: 'قيد الصيانة'),
                  _CourtStatusCard(
                      name: 'ملعب 5',
                      status: _CourtStatus.booked,
                      detail: '7:00 - 8:30 مساءً'),
                  _CourtStatusCard(
                      name: 'ملعب 6',
                      status: _CourtStatus.available,
                      detail: 'متاح للحجز'),
                ],
              ),
              SizedBox(height: AppSizes.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الحجوزات القادمة',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.secondary)),
                  Text('عرض الكل',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              SizedBox(height: AppSizes.lg),
              _upcomingBooking('ملعب 1', 'محمد وأحمد', 'ملعب داخلي',
                  'غداً، 5:00 - 6:30 مساءً', '120 ر.س'),
              SizedBox(height: AppSizes.md),
              _upcomingBooking('ملعب 3', 'خالد وسعد', 'ملعب خارجي',
                  'غداً، 7:00 - 8:30 مساءً', '100 ر.س'),
              SizedBox(height: AppSizes.xxl),
              Text('إحصائيات هذا الأسبوع',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSizes.lg),
              const _WeekStatsCard(),
              const SizedBox(height: AppSizes.xxl),
              const QuickActionsRow(
                primaryIcon: Icons.calendar_today_outlined,
                primaryLabel: 'إدارة الحجوزات',
                secondaryIcon: Icons.bar_chart,
                secondaryLabel: 'التقارير المالية',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _upcomingBooking(String court, String players, String type,
      String time, String price) {
    return BookingInfoCard(
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: court,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500)),
                    TextSpan(
                        text: '  • $players',
                        style: AppTextStyles.caption),
                  ]),
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.mutedForeground),
                    SizedBox(width: AppSizes.sm),
                    Text(type, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text('مؤكدة',
                style: AppTextStyles.caption.copyWith(color: _blueDark)),
          ),
        ],
      ),
      time: time,
      price: price,
    );
  }
}

enum _CourtStatus { booked, available, maintenance }

class _CourtStatusCard extends StatelessWidget {
  const _CourtStatusCard({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final _CourtStatus status;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final (tint, badgeColor, badgeTextColor, badgeLabel) = switch (status) {
      _CourtStatus.booked => (_green, _green, Colors.white, 'محجوز'),
      _CourtStatus.available => (
          null,
          const Color(0xFFE5E7EB),
          const Color(0xFF4B5563),
          'متاح'
        ),
      _CourtStatus.maintenance => (_orange, _orange, Colors.white, 'صيانة'),
    };

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(badgeLabel,
                  style: AppTextStyles.caption
                      .copyWith(color: badgeTextColor, fontSize: 10)),
            ),
          ],
        ),
        SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Icon(
              status == _CourtStatus.maintenance
                  ? Icons.error_outline
                  : Icons.access_time,
              size: 12,
              color: AppColors.mutedForeground,
            ),
            SizedBox(width: AppSizes.xs),
            Expanded(
              child: Text(detail,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
    );

    if (tint != null) {
      return TintedCard(
          tint: tint,
          borderWidth: 2,
          padding: const EdgeInsets.all(AppSizes.lg),
          child: body);
    }
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: body,
    );
  }
}

class _WeekStatsCard extends StatelessWidget {
  const _WeekStatsCard();

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: _blueDark,
      child: Column(
        children: [
          _row('إجمالي الحجوزات', '156 حجز'),
          SizedBox(height: AppSizes.md),
          _row('ساعات اللعب', '234 ساعة'),
          SizedBox(height: AppSizes.md),
          _row('متوسط سعر الساعة', '80 ر.س'),
          SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإيرادات الإجمالية',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500)),
              Text('8,400 ر.س',
                  style: AppTextStyles.heading3.copyWith(
                      color: _greenDark, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
