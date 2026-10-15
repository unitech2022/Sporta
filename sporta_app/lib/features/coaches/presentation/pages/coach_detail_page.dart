import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_entity.dart';
import '../../domain/entities/coach_offer_entity.dart';
import 'coaches_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// صفحة تفاصيل المدرب — تُفتح بالضغط على بطاقته في قائمة المدربين. تعرض نبذته
/// وتخصصاته وشهاداته وعروضه، وزر الحجز في الأسفل يفتح نفس ورقة حجز الجلسة.
///
/// [initial] هي بطاقة القائمة: تُرسم فوراً ريثما تصل التفاصيل الكاملة من
/// المسار GET /api/coaches/{id} (النبذة والشهادات لا تأتي مع القائمة).
class CoachDetailPage extends StatefulWidget {
  const CoachDetailPage({super.key, required this.coachId, this.initial});

  final int coachId;
  final CoachEntity? initial;

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  final _repository = getIt<CoachRepository>();

  CoachEntity? _coach;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _coach = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coach = await _repository.fetchCoachById(widget.coachId);
      if (!mounted) return;
      setState(() {
        _coach = coach;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // البطاقة الأولية تكفي للعرض، فلا نُظهر خطأ إلا حين لا نملك شيئاً.
        _error = _coach == null
            ? e.localized(context.appSettings.language.isRtl)
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = _coach;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        title: Text(context.tr('تفاصيل المدرب')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const DirectionalIcon(
            rtl: Icons.arrow_forward,
            ltr: Icons.arrow_back,
          ),
        ),
      ),
      body: coach == null
          ? (_loading
                ? const SkeletonDetail(memberRows: 0)
                : _ErrorView(message: _error ?? '', onRetry: _load))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: context.safeBottom(
                  const EdgeInsets.all(AppSizes.pagePadding),
                ),
                children: [
                  _Header(coach: coach),
                  const SizedBox(height: AppSizes.lg),
                  _StatsRow(coach: coach),
                  if (coach.bio != null && coach.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.person_outline,
                      title: context.tr('نبذة عن المدرب'),
                      child: Text(
                        coach.bio!.trim(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                  if (coach.specialties.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.sports_tennis_outlined,
                      title: context.tr('التخصصات'),
                      child: Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          for (final s in coach.specialties) _Chip(label: s),
                        ],
                      ),
                    ),
                  ],
                  if (_details(coach).isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.info_outline,
                      title: context.tr('معلومات التدريب'),
                      child: Column(
                        children: [
                          for (final row in _details(coach))
                            _InfoRow(label: row.$1, value: row.$2),
                        ],
                      ),
                    ),
                  ],
                  if (coach.availableDays.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.event_available_outlined,
                      title: context.tr('أيام التوفّر'),
                      child: Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          for (final d in coach.availableDays)
                            _Chip(label: _dayLabels[d] ?? d),
                        ],
                      ),
                    ),
                  ],
                  if (coach.certifications != null &&
                      coach.certifications!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.workspace_premium_outlined,
                      title: context.tr('الشهادات والدورات'),
                      child: Text(
                        coach.certifications!.trim(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                  if (_activeOffers(coach).isNotEmpty) ...[
                    const SizedBox(height: AppSizes.lg),
                    _Section(
                      icon: Icons.local_offer_outlined,
                      title: context.tr('العروض والخصومات'),
                      child: Column(
                        children: [
                          for (final offer in _activeOffers(coach))
                            _OfferRow(offer: offer),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xxxl),
                ],
              ),
            ),
      bottomNavigationBar: coach == null
          ? null
          : _BookingBar(coach: coach, onBooked: _load),
    );
  }

  /// صفوف «معلومات التدريب» — يُتجاهل ما لم يملأه المدرب.
  List<(String, String)> _details(CoachEntity coach) => [
    if (coach.sportName != null && coach.sportName!.isNotEmpty)
      (context.tr('اللعبة'), coach.sportName!),
    if (_experienceLabels[coach.experienceLevel] != null)
      (context.tr('سنوات الخبرة'), _experienceLabels[coach.experienceLevel]!),
    if (coach.preferredVenueName != null &&
        coach.preferredVenueName!.isNotEmpty)
      (context.tr('النادي'), coach.preferredVenueName!),
    if (coach.packagePrice != null && coach.packagePrice! > 0)
      (
        context.tr('سعر الباقة'),
        context.trArgs('{p0} ر.س', {'p0': money(coach.packagePrice ?? 0)}),
      ),
    (
      context.tr('المستوى'),
      context.trArgs('من {p0} إلى {p1}', {
        'p0': coach.levelMin,
        'p1': coach.levelMax,
      }),
    ),
  ];

  static List<CoachOfferEntity> _activeOffers(CoachEntity coach) =>
      coach.offers.where((o) => o.isActive && !o.isExpired).toList();

  static Map<String, String> get _dayLabels => {
    'sat': trg('السبت'),
    'sun': trg('الأحد'),
    'mon': trg('الإثنين'),
    'tue': trg('الثلاثاء'),
    'wed': trg('الأربعاء'),
    'thu': trg('الخميس'),
    'fri': trg('الجمعة'),
  };

  static Map<String, String> get _experienceLabels => {
    'lessThanYear': trg('أقل من سنة'),
    'oneToThree': trg('من سنة إلى ٣ سنوات'),
    'threeToFive': trg('من ٣ إلى ٥ سنوات'),
    'moreThanFive': trg('أكثر من ٥ سنوات'),
  };
}

/// بطاقة الرأس: الصورة والاسم والتقييم والموقع.
class _Header extends StatelessWidget {
  const _Header({required this.coach});

  final CoachEntity coach;

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          NetworkDecorationImage(
            imageUrl: coach.avatarUrl,
            builder: (_, image) => Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2AB5CE), Color(0xFF1E9AB0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                image: image,
              ),
              child: image != null
                  ? null
                  : Center(
                      child: Text(
                        coach.avatarInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            coach.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFACC15),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                coach.rating.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${coach.reviews} ${context.tr('تقييم')})',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            alignment: WrapAlignment.center,
            children: [
              _Chip(label: coach.badgeLabel),
              if (coach.location.isNotEmpty)
                _Chip(
                  label: coach.distanceKm != null
                      ? context.trArgs('{p0} · {p1} كم', {
                          'p0': coach.location,
                          'p1': coach.distanceKm,
                        })
                      : coach.location,
                  icon: Icons.location_on_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريط الأرقام: الطلاب والتقييمات والسعر.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.coach});

  final CoachEntity coach;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.people_outline,
            value: '${coach.students}',
            label: context.tr('طالب'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.star_outline_rounded,
            value: '${coach.reviews}',
            label: context.tr('تقييم'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            value: '${coach.priceAfterOffer}',
            label: context.tr('ر.س / جلسة'),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(context.tr(label), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.tr(title),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(label),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final CoachOfferEntity offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 14,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              offer.title,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
          Text(
            '${context.tr('خصم')} ${offer.discountPercent}%',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFFEA580C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط الحجز السفلي: السعر (قبل/بعد الخصم) وزر فتح ورقة الحجز.
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.coach, required this.onBooked});

  final CoachEntity coach;
  final VoidCallback onBooked;

  @override
  Widget build(BuildContext context) {
    final discounted = coach.priceAfterOffer < coach.price;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('السعر'), style: AppTextStyles.caption),
                Row(
                  children: [
                    Text(
                      '${money(coach.priceAfterOffer)} ${context.tr('ر.س')}',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (discounted) ...[
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        '${coach.price}',
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              // الحجز يحتاج حساباً؛ صفحة المدرب نفسها مفتوحة للزائر.
              onPressed: () async {
                if (await guestBlocked(context)) return;
                if (!context.mounted) return;
                showCoachBookingSheet(context, coach, onBooked: onBooked);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xxl,
                  vertical: AppSizes.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              child: Text(context.tr('احجز الآن')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            context.tr(label),
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.isEmpty
                  ? context.tr('تعذّر تحميل بيانات المدرب')
                  : message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}
