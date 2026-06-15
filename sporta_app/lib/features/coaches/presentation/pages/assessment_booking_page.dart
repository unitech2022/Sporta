import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class AssessmentBookingPage extends StatefulWidget {
  const AssessmentBookingPage({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  State<AssessmentBookingPage> createState() => _AssessmentBookingPageState();
}

class _AssessmentBookingPageState extends State<AssessmentBookingPage> {
  String? _selectedCoachId;
  String? _selectedDate;
  String? _selectedTime;

  static const List<Map<String, dynamic>> _coaches = [
    {
      'id': 'coach-1',
      'name': 'محمد أحمد',
      'initials': 'م.أ',
      'rating': 4.9,
      'reviews': 87,
      'location': 'نادي البادل الملكي',
      'gradientColors': [0xFF2AB5CE, 0xFF1E9AB0],
    },
    {
      'id': 'coach-3',
      'name': 'خالد محمود',
      'initials': 'خ.م',
      'rating': 4.8,
      'reviews': 112,
      'location': 'مركز بادل المدينة',
      'gradientColors': [0xFF16A34A, 0xFF15803D],
    },
    {
      'id': 'coach-extra',
      'name': 'أحمد السالم',
      'initials': 'أ.س',
      'rating': 4.9,
      'reviews': 95,
      'location': 'بادل كلوب الشرقية',
      'gradientColors': [0xFF0A2540, 0xFF1A3A5C],
    },
  ];

  static const List<Map<String, String>> _dates = [
    {'label': 'الأربعاء', 'date': '5 يونيو'},
    {'label': 'الخميس', 'date': '6 يونيو'},
    {'label': 'الجمعة', 'date': '7 يونيو'},
    {'label': 'السبت', 'date': '8 يونيو'},
    {'label': 'الأحد', 'date': '9 يونيو'},
  ];

  static const List<Map<String, String>> _times = [
    {'time': '09:00', 'period': 'صباحاً'},
    {'time': '11:00', 'period': 'صباحاً'},
    {'time': '02:00', 'period': 'مساءً'},
    {'time': '04:00', 'period': 'مساءً'},
    {'time': '06:00', 'period': 'مساءً'},
    {'time': '08:00', 'period': 'مساءً'},
  ];

  bool get _canConfirm =>
      _selectedCoachId != null &&
      _selectedDate != null &&
      _selectedTime != null;

  Map<String, dynamic>? get _selectedCoach {
    if (_selectedCoachId == null) return null;
    try {
      return _coaches.firstWhere((c) => c['id'] == _selectedCoachId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _buildInfoCard(),
                  SizedBox(height: AppSizes.lg),
                  Text(
                    'اختر المدرب',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.md),
                  ..._coaches.map(_buildCoachCard),
                  SizedBox(height: AppSizes.lg),
                  Text(
                    'اختر التاريخ',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.md),
                  _buildDatePicker(),
                  SizedBox(height: AppSizes.lg),
                  Text(
                    'اختر الوقت',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.md),
                  _buildTimePicker(),
                  if (_canConfirm) ...[
                    const SizedBox(height: AppSizes.lg),
                    _buildSummaryCard(),
                  ],
                  const SizedBox(height: AppSizes.xxxl),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حجز جلسة التقييم',
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      'احجز جلستك مع مدرب معتمد لتقييم مستواك',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
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

  Widget _buildInfoCard() {
    const items = [
      'جلسة 60 دقيقة مع مدرب معتمد',
      'تحليل شامل لمهاراتك',
      'تحديد مستواك ELO بدقة',
      'تقرير مفصل بنقاط القوة والضعف',
      'خطة تدريبية مخصصة',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.primary, size: AppSizes.iconLg),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(color: AppColors.primary)),
                          Expanded(
                            child: Text(item,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondary)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final selected = _selectedCoachId == coach['id'];
    final colors = (coach['gradientColors'] as List<int>)
        .map((c) => Color(c))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCoachId = coach['id'] as String),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Center(
                  child: Text(
                    coach['initials'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coach['name'] as String,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            'معتمد',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFACC15), size: 13),
                        SizedBox(width: 2),
                        Text(
                          '${coach['rating']} (${coach['reviews']})',
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(width: AppSizes.sm),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.mutedForeground),
                        SizedBox(width: 2),
                        Text(
                          coach['location'] as String,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: AppSizes.iconMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _dates.map((d) {
          final val = '${d['label']} ${d['date']}';
          final selected = _selectedDate == val;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = val),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      d['label']!,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      d['date']!,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.foreground,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: _times.length,
      itemBuilder: (_, i) {
        final t = _times[i];
        final val = '${t['time']} ${t['period']}';
        final selected = _selectedTime == val;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = val),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t['time']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color:
                        selected ? Colors.white : AppColors.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  t['period']!,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.mutedForeground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final coach = _selectedCoach!;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSizes.md),
          _summaryRow(
              Icons.person_outline, 'المدرب', coach['name'] as String),
          _summaryRow(
              Icons.calendar_today_outlined, 'التاريخ', _selectedDate!),
          _summaryRow(
              Icons.access_time_outlined, 'الوقت', _selectedTime!),
          _summaryRow(Icons.timer_outlined, 'المدة', '60 دقيقة'),
          const Divider(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '250 ر.س',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
          SizedBox(width: AppSizes.sm),
          SizedBox(
            width: 64,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.sm,
          AppSizes.pagePadding,
          AppSizes.md,
        ),
        child: ElevatedButton(
          onPressed: _canConfirm ? widget.onComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.4),
            minimumSize:
                const Size(double.infinity, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          ),
          child: const Text('تأكيد الحجز والدفع'),
        ),
      ),
    );
  }
}
