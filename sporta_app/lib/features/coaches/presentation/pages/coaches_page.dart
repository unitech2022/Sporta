import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../data/coaches_mock_data.dart';
import '../../domain/entities/coach_entity.dart';

class CoachesPage extends StatefulWidget {
  const CoachesPage({
    super.key,
    this.onBack,
    this.onNavigate,
    this.onGoToPayment,
  });

  final VoidCallback? onBack;
  final void Function(String page, [String? coachId])? onNavigate;
  final void Function(Map<String, dynamic> details)? onGoToPayment;

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  String _searchQuery = '';
  String _levelFilter = 'الكل';
  late List<CoachEntity> _coaches;

  static const List<String> _levelFilters = ['الكل', 'مبتدئ', 'متوسط', 'متقدم'];

  @override
  void initState() {
    super.initState();
    _coaches = mockCoaches.map((c) => CoachEntity(
      id: c.id,
      name: c.name,
      avatarInitials: c.avatarInitials,
      rating: c.rating,
      reviews: c.reviews,
      students: c.students,
      levelMin: c.levelMin,
      levelMax: c.levelMax,
      location: c.location,
      distanceKm: c.distanceKm,
      price: c.price,
      specialties: c.specialties,
      badgeLabel: c.badgeLabel,
      badgeType: c.badgeType,
      avatarGradientColors: c.avatarGradientColors,
      isBooked: c.isBooked,
    )).toList();
  }

  List<CoachEntity> get _filteredCoaches {
    return _coaches.where((c) {
      final matchesQuery = _searchQuery.isEmpty ||
          c.name.contains(_searchQuery) ||
          c.location.contains(_searchQuery);
      if (!matchesQuery) return false;
      if (_levelFilter == 'الكل') return true;
      if (_levelFilter == 'مبتدئ') return c.levelMax <= 3;
      if (_levelFilter == 'متوسط') return c.levelMin >= 2 && c.levelMax <= 5;
      if (_levelFilter == 'متقدم') return c.levelMin >= 3;
      return true;
    }).toList();
  }

  void _openBookingSheet(CoachEntity coach) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(
        coach: coach,
        onConfirm: (details) {
          Navigator.of(context).pop();
          widget.onGoToPayment?.call(details);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCoaches;
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
                  _buildAssessmentBanner(),
                  const SizedBox(height: AppSizes.lg),
                  ...filtered.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: _CoachCard(
                      coach: c,
                      onTap: () {
                        if (c.isBooked) {
                          widget.onNavigate?.call('training-session', c.id);
                        } else {
                          _openBookingSheet(c);
                        }
                      },
                    ),
                  )),
                ],
              ),
            ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppSizes.md),
                  ],
                  Text(
                    'طور مستواك',
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              AppSearchField(
                hint: 'ابحث عن مدرب...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: AppSizes.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _levelFilters.map((f) {
                    final selected = _levelFilter == f;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _levelFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            f,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AppColors.primary, size: AppSizes.iconLg),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جلسة التقييم',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'اعرف مستواك الحقيقي مع مدرب معتمد',
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '250 ر.س',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          ElevatedButton(
            onPressed: () => widget.onNavigate?.call('assessment-booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: const Text('احجز التقييم', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onTap});

  final CoachEntity coach;
  final VoidCallback onTap;

  Color get _badgeBg {
    switch (coach.badgeType) {
      case 'women':
        return const Color(0xFFFFE4E6);
      case 'pro':
        return const Color(0xFFDCFCE7);
      default:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get _badgeFg {
    switch (coach.badgeType) {
      case 'women':
        return const Color(0xFFDB2777);
      case 'pro':
        return const Color(0xFF16A34A);
      default:
        return AppColors.primary;
    }
  }

  List<Color> get _avatarColors {
    final colors = coach.avatarGradientColors;
    return [
      _hexColor(colors[0]),
      _hexColor(colors[1]),
    ];
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _avatarColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Center(
                    child: Text(
                      coach.avatarInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coach.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFACC15), size: 14),
                          SizedBox(width: 2),
                          Text(
                            '${coach.rating}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ' (${coach.reviews} تقييم)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    coach.badgeLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: _badgeFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                _infoChip(Icons.people_outline, '${coach.students} طالب'),
                SizedBox(width: AppSizes.sm),
                _infoChip(Icons.bar_chart,
                    'المستوى ${coach.levelMin}-${coach.levelMax}'),
              ],
            ),
            SizedBox(height: AppSizes.sm),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: AppSizes.iconSm, color: AppColors.mutedForeground),
                SizedBox(width: AppSizes.xs),
                Flexible(
                  child: Text(
                    '${coach.location} · ${coach.distanceKm} كم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: coach.specialties
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${coach.price} ',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'ر.س / جلسة',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                if (coach.isBooked)
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('حجز مكتمل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    ),
                    child: const Text('احجز جلسة'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedForeground),
          SizedBox(width: 3),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Booking Bottom Sheet ─────────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.coach, required this.onConfirm});

  final CoachEntity coach;
  final void Function(Map<String, dynamic> details) onConfirm;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _step = 1;

  final Set<String> _selectedDomains = {};
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedLocation;

  static const List<Map<String, String>> _domains = [
    {
      'id': 'attack',
      'icon': '⚔️',
      'label': 'الهجوم',
      'sublabel': 'Attack',
      'desc': 'تحسين قوة وتوجيه الضربات الهجومية',
    },
    {
      'id': 'defense',
      'icon': '🛡️',
      'label': 'الدفاع',
      'sublabel': 'Defense',
      'desc': 'تقنيات التصدي واستعادة الكرة',
    },
    {
      'id': 'control',
      'icon': '🎯',
      'label': 'التحكم',
      'sublabel': 'Control',
      'desc': 'دقة التوجيه والتحكم في الكرة',
    },
    {
      'id': 'movement',
      'icon': '🏃',
      'label': 'الحركة',
      'sublabel': 'Movement',
      'desc': 'السرعة والرشاقة داخل الملعب',
    },
    {
      'id': 'gameiq',
      'icon': '🧠',
      'label': 'ذكاء اللعب',
      'sublabel': 'Game IQ',
      'desc': 'قراءة اللعبة واتخاذ القرار',
    },
    {
      'id': 'teamplay',
      'icon': '🤝',
      'label': 'اللعب الجماعي',
      'sublabel': 'Team Play',
      'desc': 'التنسيق والتواصل مع الشريك',
    },
    {
      'id': 'serve',
      'icon': '🎾',
      'label': 'الإرسال',
      'sublabel': 'Serve',
      'desc': 'تقنيات الإرسال وبدء النقطة',
    },
  ];

  static const List<Map<String, String>> _dates = [
    {'label': 'السبت', 'date': '6 يونيو'},
    {'label': 'الأحد', 'date': '7 يونيو'},
    {'label': 'الاثنين', 'date': '8 يونيو'},
    {'label': 'الثلاثاء', 'date': '9 يونيو'},
    {'label': 'الأربعاء', 'date': '10 يونيو'},
  ];

  static const List<Map<String, String>> _times = [
    {'time': '08:00', 'period': 'صباحاً'},
    {'time': '10:00', 'period': 'صباحاً'},
    {'time': '12:00', 'period': 'ظهراً'},
    {'time': '04:00', 'period': 'مساءً'},
    {'time': '06:00', 'period': 'مساءً'},
    {'time': '08:00', 'period': 'مساءً'},
  ];

  static const List<Map<String, String>> _locations = [
    {
      'name': 'مركز بادل المدينة',
      'distance': '5.4 كم',
      'courts': '4 ملاعب',
    },
    {
      'name': 'نادي البادل الملكي',
      'distance': '1.8 كم',
      'courts': '6 ملاعب',
    },
    {
      'name': 'بادل كلوب الشرقية',
      'distance': '3.2 كم',
      'courts': '3 ملاعب',
    },
  ];

  static const List<String> _stepTitles = [
    'اختر مجالات التدريب',
    'حدد الموعد',
    'اختر الموقع',
    'تأكيد الحجز',
  ];

  bool get _canProceed {
    switch (_step) {
      case 1:
        return _selectedDomains.isNotEmpty;
      case 2:
        return _selectedDate != null && _selectedTime != null;
      case 3:
        return _selectedLocation != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      widget.onConfirm({
        'coachId': widget.coach.id,
        'coachName': widget.coach.name,
        'domains': _selectedDomains.toList(),
        'date': _selectedDate,
        'time': _selectedTime,
        'location': _selectedLocation,
        'price': widget.coach.price,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.xxxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildSheetHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: _buildStepBody(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding, AppSizes.md, AppSizes.pagePadding, AppSizes.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Center(
                  child: Text(
                    widget.coach.avatarInitials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.coach.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _stepTitles[_step - 1],
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                'الخطوة $_step من 4',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          StepProgressBar(
            currentStep: _step,
            totalSteps: 4,
            inactiveColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: _domains.map((d) {
        final id = d['id']!;
        final selected = _selectedDomains.contains(id);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedDomains.remove(id);
              } else {
                _selectedDomains.add(id);
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(d['icon']!, style: const TextStyle(fontSize: 22)),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              d['label']!,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: AppSizes.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.xs + 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Text(
                                d['sublabel']!,
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        Text(d['desc']!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: AppSizes.iconMd)
                  else
                    Icon(Icons.circle_outlined,
                        color: AppColors.border,
                        size: AppSizes.iconMd),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التاريخ',
          style:
              AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _dates.map((d) {
              final val = '${d['label']} ${d['date']}';
              final selected = _selectedDate == val;
              return Padding(
                padding:
                    const EdgeInsetsDirectional.only(end: AppSizes.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = val),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
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
                            color: selected ? Colors.white : AppColors.foreground,
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
        ),
        SizedBox(height: AppSizes.lg),
        Text(
          'اختر الوقت',
          style:
              AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.builder(
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
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
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
                        color: selected ? Colors.white : AppColors.foreground,
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
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: _locations.map((loc) {
        final selected = _selectedLocation == loc['name'];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: GestureDetector(
            onTap: () => setState(() => _selectedLocation = loc['name']),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.iconMd,
                      color: selected
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc['name']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            Text(loc['distance']!,
                                style: AppTextStyles.caption),
                            Text(' · ', style: AppTextStyles.caption),
                            Text(loc['courts']!,
                                style: AppTextStyles.caption),
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
      }).toList(),
    );
  }

  Widget _buildStep4() {
    final domainLabels = _selectedDomains.map((id) {
      final d = _domains.firstWhere((x) => x['id'] == id,
          orElse: () => {'label': id});
      return d['label']!;
    }).join('، ');

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF16A34A), size: AppSizes.iconLg),
              SizedBox(width: AppSizes.sm),
              Text(
                'ملخص الحجز',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _summaryRow('المدرب', widget.coach.name),
          _summaryRow('المجالات', domainLabels),
          _summaryRow('التاريخ', _selectedDate ?? ''),
          _summaryRow('الوقت', _selectedTime ?? ''),
          _summaryRow('الموقع', _selectedLocation ?? ''),
          const Divider(
              height: AppSizes.lg,
              color: Color(0xFFBBF7D0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
              Text(
                '${widget.coach.price} ر.س',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF15803D),
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
            AppSizes.pagePadding, AppSizes.md,
            AppSizes.pagePadding, AppSizes.md),
        child: Row(
          children: [
            if (_step > 1) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, AppSizes.buttonHeight),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  child: const Text('رجوع'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed ? _nextStep : null,
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
                child: Text(_step < 4 ? 'التالي' : 'تأكيد الحجز'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
