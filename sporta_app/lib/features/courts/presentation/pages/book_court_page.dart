import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/courts_mock_data.dart';
import '../../domain/entities/court_entity.dart';

class BookCourtPage extends StatefulWidget {
  const BookCourtPage({
    super.key,
    required this.onBack,
    this.courtId,
    this.onComplete,
  });
  final VoidCallback onBack;
  final String? courtId;
  final VoidCallback? onComplete;

  @override
  State<BookCourtPage> createState() => _BookCourtPageState();
}

class _BookCourtPageState extends State<BookCourtPage> {
  late final List<DateTime> _dates;
  late final List<String> _timeSlots;

  CourtEntity? _court;
  DateTime? _selectedDate;
  int? _selectedCourt;
  int? _selectedDuration;
  String? _selectedTime;

  static const List<String> _dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const List<String> _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const Set<String> _bookedSlots = {
    '08:00',
    '10:00',
    '14:00',
    '18:00',
    '20:00',
  };

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(15, (i) => today.add(Duration(days: i)));
    _timeSlots = List.generate(
      18,
      (i) {
        final hour = 6 + i;
        return '${hour.toString().padLeft(2, '0')}:00';
      },
    );
    if (widget.courtId != null) {
      _court = findCourtById(widget.courtId!);
    }
    _court ??= mockCourts.first;
  }

  bool get _allSelected =>
      _selectedDate != null &&
      _selectedCourt != null &&
      _selectedDuration != null &&
      _selectedTime != null;

  bool _isPeakHour(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 0;
    return hour >= 16;
  }

  int _slotPrice(String time) {
    return _isPeakHour(time)
        ? (_court?.peakHourPrice ?? 0)
        : (_court?.basePrice ?? 0);
  }

  int get _totalPrice {
    if (_selectedTime == null || _selectedDuration == null) return 0;
    final hourlyRate = _slotPrice(_selectedTime!);
    return (hourlyRate * (_selectedDuration! / 60)).round();
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]}';
  }

  String _dayName(DateTime date) {
    return _dayNames[date.weekday % 7];
  }

  String _formatFullDate(DateTime date) {
    return '${_dayNames[date.weekday % 7]}، ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  String _priceTypeLabel() {
    if (_selectedTime == null) return '';
    return _isPeakHour(_selectedTime!) ? 'ساعة الذروة' : 'سعر اعتيادي';
  }

  @override
  Widget build(BuildContext context) {
    final court = _court;
    if (court == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('الملعب غير موجود')),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            GradientPageHeader(
              title: 'حجز الملعب',
              subtitle: court.name,
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourtInfoCard(court),
                    const SizedBox(height: AppSizes.xl),
                    _buildDatePicker(),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: AppSizes.xl),
                      _buildCourtNumberPicker(court),
                    ],
                    if (_selectedCourt != null) ...[
                      const SizedBox(height: AppSizes.xl),
                      _buildDurationPicker(court),
                    ],
                    if (_selectedDuration != null) ...[
                      SizedBox(height: AppSizes.xl),
                      _buildTimeSlots(),
                    ],
                    if (_allSelected) ...[
                      SizedBox(height: AppSizes.xl),
                      _buildBookingSummary(court),
                    ],
                    SizedBox(height: AppSizes.xxxl),
                    _buildActionButtons(),
                    SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtInfoCard(CourtEntity court) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.name,
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          SizedBox(height: AppSizes.sm),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: AppSizes.iconSm,
                color: Color(0xFFFACC15),
              ),
              SizedBox(width: 3),
              Text(
                court.rating.toStringAsFixed(1),
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: AppSizes.xs),
              Text(
                '(${court.reviews} تقييم)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
              SizedBox(width: AppSizes.md),
              Icon(
                Icons.location_on_outlined,
                size: AppSizes.iconSm,
                color: AppColors.mutedForeground,
              ),
              SizedBox(width: 2),
              Text(
                court.distance,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(width: AppSizes.md),
              _SmallBadge(label: courtTypeLabel(court.type)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PriceStrip(
                    label: 'السعر الاعتيادي',
                    price: court.basePrice,
                    isLeft: true,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _PriceStrip(
                    label: 'ساعة الذروة',
                    price: court.peakHourPrice,
                    isLeft: false,
                    isPeak: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التاريخ',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.sm),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isToday = index == 0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedCourt = null;
                    _selectedDuration = null;
                    _selectedTime = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayName(date),
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.mutedForeground,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.secondary,
                        ),
                      ),
                      if (isToday)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourtNumberPicker(CourtEntity court) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر رقم الملعب',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 1,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            final number = index + 1;
            final isSelected = _selectedCourt == number;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCourt = number;
                  _selectedDuration = null;
                  _selectedTime = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDurationPicker(CourtEntity court) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر المدة',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: court.availableDurations.map((dur) {
            final isSelected = _selectedDuration == dur;
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDuration = dur;
                    _selectedTime = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '$dur دقيقة',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'اختر الوقت',
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.secondary),
            ),
            const Spacer(),
            _LegendItem(
              color: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFF86EFAC),
              label: 'متاح',
            ),
            SizedBox(width: AppSizes.sm),
            _LegendItem(
              color: const Color(0xFFE5E7EB),
              borderColor: const Color(0xFFE5E7EB),
              label: 'محجوز',
            ),
          ],
        ),
        SizedBox(height: AppSizes.xs),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFB923C),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSizes.xs),
            Text(
              'ساعة الذروة (16:00 - 23:00)',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 1.8,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final time = _timeSlots[index];
            final isBooked = _bookedSlots.contains(time);
            final isPeak = _isPeakHour(time);
            final isSelected = _selectedTime == time;
            if (isBooked) {
              return _BookedSlot(time: time);
            }
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFF86EFAC),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            time,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                          Text(
                            '${_slotPrice(time)} ر.س',
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF16A34A),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPeak && !isSelected)
                      const Positioned(
                        top: 4,
                        left: 4,
                        child: _PeakDot(),
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

  Widget _buildBookingSummary(CourtEntity court) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ',
            value: _selectedDate != null ? _formatFullDate(_selectedDate!) : '',
          ),
          _SummaryRow(
            icon: Icons.grid_4x4_rounded,
            label: 'رقم الملعب',
            value: 'ملعب $_selectedCourt',
          ),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'الوقت',
            value: _selectedTime ?? '',
          ),
          _SummaryRow(
            icon: Icons.timelapse_rounded,
            label: 'المدة',
            value: '$_selectedDuration دقيقة',
          ),
          _SummaryRow(
            icon: Icons.info_outline_rounded,
            label: 'نوع السعر',
            value: _priceTypeLabel(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                '$_totalPrice ر.س',
                style: AppTextStyles.heading2.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize:
                  const Size(double.infinity, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _allSelected
                ? () {
                    _showConfirmationDialog();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              minimumSize:
                  const Size(double.infinity, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: const Text('تأكيد الحجز'),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          title: const Text('تأكيد الحجز'),
          content: Text(
            'هل تريد تأكيد حجز ملعب $_selectedCourt بتاريخ ${_formatDate(_selectedDate!)} الساعة $_selectedTime؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onComplete?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PriceStrip extends StatelessWidget {
  const _PriceStrip({
    required this.label,
    required this.price,
    required this.isLeft,
    this.isPeak = false,
  });

  final String label;
  final int price;
  final bool isLeft;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPeak) ...[
                const Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: Color(0xFFFB923C),
                ),
                SizedBox(width: 2),
              ],
              Text(
                '$price ر.س',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPeak
                      ? const Color(0xFFFB923C)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookedSlot extends StatelessWidget {
  const _BookedSlot({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'محجوز',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeakDot extends StatelessWidget {
  const _PeakDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFFB923C),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });
  final Color color;
  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor),
          ),
        ),
        SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
          SizedBox(width: AppSizes.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
