import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class TrainingSessionPage extends StatefulWidget {
  const TrainingSessionPage({
    super.key,
    required this.onBack,
    this.sessionData,
  });

  final VoidCallback onBack;
  final Map<String, dynamic>? sessionData;

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  bool _submitted = false;
  final Map<String, int?> _ratings = {
    'attack': null,
    'defense': null,
    'control': null,
    'movement': null,
    'gameiq': null,
    'teamplay': null,
    'serve': null,
  };
  final TextEditingController _notesController = TextEditingController();

  static const List<Map<String, String>> _skills = [
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

  Map<String, dynamic> get _session {
    return widget.sessionData ??
        {
          'coachName': 'محمد أحمد',
          'coachAvatar': 'م.أ',
          'coachRating': 4.9,
          'date': 'الخميس 6 يونيو',
          'time': '04:00 مساءً',
          'location': 'نادي البادل الملكي',
          'duration': '60 دقيقة',
          'price': 250,
        };
  }

  int get _ratedCount =>
      _ratings.values.where((v) => v != null).length;

  bool get _allRated => _ratedCount == _skills.length;

  double get _average {
    final rated = _ratings.values.where((v) => v != null).toList();
    if (rated.isEmpty) return 0;
    return rated.fold<int>(0, (sum, v) => sum + v!) / rated.length;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen();
    }
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
                  _buildCoachCard(),
                  SizedBox(height: AppSizes.md),
                  _buildSessionDetailsCard(),
                  SizedBox(height: AppSizes.lg),
                  Text(
                    'تقييم المهارات',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.md),
                  ..._skills.map(_buildSkillCard),
                  if (_ratedCount > 0) ...[
                    SizedBox(height: AppSizes.md),
                    _buildAverageCard(),
                  ],
                  SizedBox(height: AppSizes.lg),
                  Text(
                    'ملاحظات إضافية',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'أضف ملاحظاتك هنا...',
                      hintStyle: AppTextStyles.caption,
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
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

  Widget _buildSuccessScreen() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF16A34A),
                    size: 48,
                  ),
                ),
                SizedBox(height: AppSizes.lg),
                Text(
                  'تم تسجيل نتيجة التمرين',
                  style: AppTextStyles.heading2
                      .copyWith(color: const Color(0xFF15803D)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusXl),
                    border:
                        Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'متوسط التقييم',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      SizedBox(height: AppSizes.sm),
                      Text(
                        '${_average.toStringAsFixed(1)} / 7',
                        style: AppTextStyles.heading2.copyWith(
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      LinearProgressIndicator(
                        value: _average / 7,
                        backgroundColor:
                            const Color(0xFFBBF7D0),
                        color: const Color(0xFF16A34A),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity,
                        AppSizes.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
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
                child: Text(
                  'تفاصيل التمرين',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Text(
                  'حجز مكتمل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachCard() {
    final session = _session;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2AB5CE), Color(0xFF1E9AB0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                session['coachAvatar'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
                      session['coachName'] as String,
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
                      '${session['coachRating']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailsCard() {
    final session = _session;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _detailRow(Icons.calendar_today_outlined, 'التاريخ',
              session['date'] as String),
          _detailRow(Icons.access_time_outlined, 'الوقت',
              session['time'] as String),
          _detailRow(Icons.location_on_outlined, 'الموقع',
              session['location'] as String),
          _detailRow(Icons.timer_outlined, 'المدة',
              session['duration'] as String),
          _detailRow(Icons.payments_outlined, 'السعر',
              '${session['price']} ر.س',
              isLast: true),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.sm),
      child: Row(
        children: [
          Icon(icon,
              size: AppSizes.iconSm, color: AppColors.primary),
          SizedBox(width: AppSizes.sm),
          SizedBox(
            width: 56,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Map<String, String> skill) {
    final id = skill['id']!;
    final currentRating = _ratings[id];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: currentRating != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(skill['icon']!,
                    style: const TextStyle(fontSize: 20)),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skill['label']!,
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
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull),
                            ),
                            child: Text(
                              skill['sublabel']!,
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Text(skill['desc']!,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (currentRating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '$currentRating / 7',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: List.generate(7, (i) {
                final val = i + 1;
                final isSelected = currentRating == val;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: i == 6 ? 0 : AppSizes.xs / 2),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _ratings[id] = val),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd),
                        ),
                        child: Center(
                          child: Text(
                            '$val',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.mutedForeground,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCard() {
    final avg = _average;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'متوسط التقييم',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(' / 7', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_ratedCount / ${_skills.length} مهارات',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (_allRated) ...[
            const SizedBox(height: AppSizes.sm),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: avg / 7,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
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
          onPressed:
              _allRated ? () => setState(() => _submitted = true) : null,
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
          child: const Text('حفظ نتيجة التمرين'),
        ),
      ),
    );
  }
}
