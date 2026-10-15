import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/level_avatar.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/membership_repository.dart';
import '../../domain/entities/membership.dart';
import '../widgets/club_membership_section.dart';
import '../widgets/membership_benefits.dart';
import '../widgets/membership_plan_sheet.dart';

/// عضويات النادي (المالك): خطط شهرية بخصم وأولوية، نافذة الحجز المسبق
/// لغير الأعضاء، والأعضاء الحاليون وصافي إيراد الشهر.
class VenueMembershipsPage extends StatefulWidget {
  const VenueMembershipsPage({
    super.key,
    required this.venueId,
    this.venueName = '',
  });

  final int venueId;
  final String venueName;

  @override
  State<VenueMembershipsPage> createState() => _VenueMembershipsPageState();
}

class _VenueMembershipsPageState extends State<VenueMembershipsPage> {
  final _repo = getIt<MembershipRepository>();
  VenueMembers? _data;
  String? _error;
  bool _windowBusy = false;

  static const _windowChoices = [3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _repo.fetchVenueAdmin(widget.venueId);
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.display);
    }
  }

  Future<void> _setWindow(int? days) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _windowBusy = true);
    try {
      await _repo.setBookingWindow(widget.venueId, days);
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _windowBusy = false);
    }
  }

  Future<void> _editPlan([MembershipPlan? plan]) async {
    final d = _data;
    if (d == null) return;
    final saved = await showMembershipPlanSheet(
      context,
      venueId: widget.venueId,
      sportaFeePercent: d.sportaFeePercent,
      plan: plan,
    );
    if (saved != null) _load();
  }

  Future<void> _deletePlan(MembershipPlan plan) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('حذف الخطة؟')),
        content: Text(
          plan.activeMembers > 0
              ? ctx.trArgs(
                  'لدى الخطة {p0} عضو حالي — تبقى عضوياتهم حتى نهاية شهرهم ولن تتجدد.',
                  {'p0': plan.activeMembers},
                )
              : ctx.tr('لن تظهر الخطة للاعبين بعد الآن.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('تراجع')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(ctx.tr('حذف')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deletePlan(plan.id);
      _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        title: Text(context.tr('عضويات النادي')),
      ),
      floatingActionButton: d == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _editPlan,
              backgroundColor: membershipGold,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(context.tr('خطة جديدة')),
            ),
      body: d == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!, style: AppTextStyles.body),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: context.safeBottom(
                  const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    AppSizes.pagePadding,
                    AppSizes.pagePadding,
                    96,
                  ),
                ),
                children: [
                  if (widget.venueName.isNotEmpty) ...[
                    Text(
                      widget.venueName,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                  ],
                  Text(
                    context.tr(
                      'اشتراك شهري يدفعه اللاعب من محفظته مقابل خصم على حجوزاته في ناديك وأولوية في الحجز المسبق. يتجدد تلقائياً ويُضاف لرصيدك فوراً.',
                    ),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _stats(context, d),
                  const SizedBox(height: AppSizes.lg),
                  _windowCard(context, d),
                  const SizedBox(height: AppSizes.xl),
                  _title(context.tr('الخطط')),
                  const SizedBox(height: AppSizes.sm),
                  if (d.plans.isEmpty)
                    _emptyBox(
                      context.tr(
                        'لا توجد خطط بعد — أضف خطة ليظهر قسم العضوية في صفحات ملاعبك.',
                      ),
                    )
                  else
                    for (final p in d.plans) _planCard(context, p),
                  const SizedBox(height: AppSizes.xl),
                  _title(
                    context.trArgs('الأعضاء ({p0})', {'p0': d.members.length}),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (d.members.isEmpty)
                    _emptyBox(context.tr('لا يوجد أعضاء حالياً.'))
                  else
                    for (final m in d.members) _memberTile(context, m),
                ],
              ),
            ),
    );
  }

  Widget _stats(BuildContext context, VenueMembers d) {
    Widget tile(String value, String label, IconData icon) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: membershipGold, size: 20),
            const SizedBox(height: AppSizes.xs),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(
          '${d.members.length}',
          context.tr('عضو فعّال'),
          Icons.groups_2_outlined,
        ),
        const SizedBox(width: AppSizes.md),
        tile(
          context.trArgs('{p0} ر.س', {'p0': money(d.monthlyRevenue)}),
          context.tr('صافي هذا الشهر'),
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  Widget _windowCard(BuildContext context, VenueMembers d) {
    final days = d.bookingWindowDays;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _title(context.tr('نافذة الحجز المسبق'))),
              if (_windowBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            days == null
                ? context.tr(
                    'الحجز مفتوح للجميع بلا حد. حدّد نافذة لتصبح «أولوية الحجز» ميزة حقيقية لأعضائك.',
                  )
                : context.trArgs(
                    'غير الأعضاء يحجزون قبل {p0} أيام كحد أقصى، والعضو يضيف أيام أولوية خطته.',
                    {'p0': days},
                  ),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              ChoiceChip(
                label: Text(context.tr('بلا حد')),
                selected: days == null,
                onSelected: _windowBusy
                    ? null
                    : (_) {
                        if (days != null) _setWindow(null);
                      },
              ),
              for (final c in _windowChoices)
                ChoiceChip(
                  label: Text(context.trArgs('{p0} أيام', {'p0': c})),
                  selected: days == c,
                  onSelected: _windowBusy
                      ? null
                      : (_) {
                          if (days != c) _setWindow(c);
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, MembershipPlan p) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: p.isActive
              ? membershipGold.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!p.isActive)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                  child: Text(
                    context.tr('موقوفة'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                context.trArgs('{p0} ر.س', {'p0': money(p.monthlyPrice)}),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: membershipGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(' / ${context.tr('شهرياً')}', style: AppTextStyles.caption),
            ],
          ),
          MembershipBenefits(
            discountPercent: p.discountPercent,
            monthlyDiscountHours: p.monthlyDiscountHours,
            priorityDays: p.priorityDays,
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Text(
                context.trArgs('{p0} عضو', {'p0': p.activeMembers}),
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _editPlan(p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.tr('تعديل')),
              ),
              IconButton(
                onPressed: () => _deletePlan(p),
                tooltip: context.tr('حذف'),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberTile(BuildContext context, VenueMember m) {
    final cap = m.monthlyDiscountHours;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          LevelAvatar(
            name: m.name,
            imageUrl: m.avatarUrl,
            level: m.level,
            radius: 20,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${m.planName} · ${m.autoRenew ? context.trArgs('يتجدد {p0}', {'p0': AppDates.dayMonth(m.periodEnd)}) : context.trArgs('ينتهي {p0}', {'p0': AppDates.dayMonth(m.periodEnd)})}',
                  style: AppTextStyles.caption,
                ),
                if (cap != null)
                  Text(
                    context.trArgs('استخدم {p0} من {p1} ساعات خصم', {
                      'p0': membershipHours(context, m.usedDiscountMinutes),
                      'p1': cap,
                    }),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _emptyBox(String text) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, style: AppTextStyles.caption),
  );
}
