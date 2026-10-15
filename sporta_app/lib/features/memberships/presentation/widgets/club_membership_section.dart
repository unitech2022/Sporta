import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../courts/presentation/widgets/court_detail/court_detail_shared.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../data/membership_repository.dart';
import '../../domain/entities/membership.dart';
import '../pages/my_memberships_page.dart';
import 'membership_benefits.dart';

/// قسم «عضوية النادي» في صفحة الملعب: خطط النادي مع زر الاشتراك، أو بطاقة
/// العضوية الحالية لمن هو عضو. يختفي كلياً إن لم يعرض النادي خططاً.
class ClubMembershipSection extends StatefulWidget {
  const ClubMembershipSection({
    super.key,
    required this.venueId,
    this.onChanged,
    this.refreshToken = 0,
  });

  final int venueId;

  /// يتغيّر بعد العودة من الحجز فيُعاد الجلب — ساعات الخصم المتبقية تنقص.
  final int refreshToken;

  /// بعد الاشتراك — لتحديث الصفحة (السعر ونافذة الحجز تتغيّر للعضو).
  final VoidCallback? onChanged;

  @override
  State<ClubMembershipSection> createState() => _ClubMembershipSectionState();
}

class _ClubMembershipSectionState extends State<ClubMembershipSection> {
  final _repo = getIt<MembershipRepository>();
  VenueMembership? _data;
  int? _busyPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClubMembershipSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    if (widget.venueId <= 0) return;
    try {
      final d = await _repo.fetchForVenue(widget.venueId);
      if (mounted) setState(() => _data = d);
    } catch (_) {
      // القسم إضافي — فشله لا يعطّل صفحة الملعب.
    }
  }

  Future<void> _subscribe(MembershipPlan plan) async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    // التجديد التلقائي اختيار اللاعب (مطفأ افتراضياً) — يُسأل قبل الدفع.
    final autoRenew = await _askAutoRenew(plan);
    if (autoRenew == null || !mounted) return;

    final ok = await showPaymentConfirmDialog(
      context,
      title: context.tr('الاشتراك في عضوية النادي'),
      amount: plan.monthlyPrice,
      details: [
        PaymentDetail(context.tr('النادي'), _data?.venueName ?? ''),
        PaymentDetail(context.tr('الخطة'), plan.name),
        PaymentDetail(
          context.tr('المدة'),
          autoRenew
              ? context.tr('شهر — يتجدد تلقائياً')
              : context.tr('شهر واحد — بلا تجديد تلقائي'),
        ),
      ],
      footnote: autoRenew
          ? context.tr(
              'يتجدد الاشتراك شهرياً من محفظتك ونذكّرك قبل التجديد بثلاثة أيام. يمكنك إيقاف التجديد متى شئت وتبقى المزايا حتى نهاية الشهر.',
            )
          : context.tr(
              'تنتهي العضوية بعد شهر ولن يُخصم شيء بعدها. نذكّرك قبل نهايتها بثلاثة أيام، ويمكنك تفعيل التجديد من «عضويات الأندية».',
            ),
      confirmLabel: context.tr('اشترك الآن'),
    );
    if (ok != true || !mounted) return;
    final welcome = context.trArgs('أهلاً بك عضواً في {p0}', {
      'p0': _data?.venueName ?? '',
    });
    setState(() => _busyPlan = plan.id);
    try {
      await _repo.subscribe(plan.id, autoRenew: autoRenew);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(welcome)));
      await _load();
      widget.onChanged?.call();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _busyPlan = null);
    }
  }

  /// يسأل عن التجديد التلقائي: true/false، أو null إن ألغى.
  Future<bool?> _askAutoRenew(MembershipPlan plan) {
    var renew = false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ctx.tr('الاشتراك في عضوية النادي')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${plan.name} · ${ctx.trArgs('{p0} ر.س', {'p0': money(plan.monthlyPrice)})} / ${ctx.tr('شهرياً')}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: renew,
                activeTrackColor: membershipGold,
                title: Text(
                  ctx.tr('تجديد تلقائي كل شهر'),
                  style: AppTextStyles.bodySmall,
                ),
                subtitle: Text(
                  renew
                      ? ctx.tr('يُخصم المبلغ من محفظتك كل شهر حتى توقفه')
                      : ctx.tr('تنتهي العضوية بعد شهر ولا يُخصم شيء آخر'),
                  style: AppTextStyles.caption,
                ),
                onChanged: (v) => setLocal(() => renew = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('تراجع')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, renew),
              child: Text(ctx.tr('متابعة للدفع')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final mine = d.myMembership;
    final plans = d.plans.where((p) => p.isActive).toList();
    if (mine == null && plans.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md),
      child: DetailSectionCard(
        title: context.tr('عضوية النادي'),
        icon: Icons.workspace_premium_outlined,
        action: mine != null ? const MemberBadge() : null,
        child: mine != null
            ? _memberCard(context, mine)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'اشترك شهرياً في هذا النادي واحصل على أسعار أقل وأولوية في الحجز.',
                    ),
                    style: AppTextStyles.caption,
                  ),
                  if (d.bookingWindowDays != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      context.trArgs(
                        'الحجز لغير الأعضاء متاح قبل {p0} أيام فقط.',
                        {'p0': d.bookingWindowDays!},
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                  if (d.isOwnVenue) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      context.tr(
                        'هذا ناديك — يرى اللاعبون الخطط التالية ويشتركون منها. عدّلها من «عضويات النادي» في حساب الملعب.',
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  for (final p in plans) _planTile(context, p, d.isOwnVenue),
                ],
              ),
      ),
    );
  }

  Widget _planTile(BuildContext context, MembershipPlan p, bool preview) {
    final busy = _busyPlan == p.id;
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: membershipGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: membershipGold.withValues(alpha: 0.35)),
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
              Text(
                context.trArgs('{p0} ر.س', {'p0': money(p.monthlyPrice)}),
                style: AppTextStyles.heading3.copyWith(
                  color: membershipGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(' / ${context.tr('شهرياً')}', style: AppTextStyles.caption),
            ],
          ),
          if ((p.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(p.description!, style: AppTextStyles.caption),
          ],
          MembershipBenefits(
            discountPercent: p.discountPercent,
            monthlyDiscountHours: p.monthlyDiscountHours,
            priorityDays: p.priorityDays,
          ),
          if (!preview) ...[
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _busyPlan != null ? null : () => _subscribe(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: membershipGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.tr('اشترك')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberCard(BuildContext context, Membership m) {
    final left = m.remainingMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.planName,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        MembershipBenefits(
          discountPercent: m.discountPercent,
          monthlyDiscountHours: m.monthlyDiscountHours,
          priorityDays: m.priorityDays,
        ),
        if (left != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text(
            context.trArgs('متبقٍ من ساعات الخصم هذا الشهر: {p0}', {
              'p0': membershipHours(context, left),
            }),
            style: AppTextStyles.caption.copyWith(color: AppColors.success),
          ),
        ],
        const SizedBox(height: AppSizes.xs),
        Text(
          m.autoRenew
              ? context.trArgs('يتجدد في {p0}', {
                  'p0': AppDates.dayMonth(m.periodEnd),
                })
              : context.trArgs('تنتهي في {p0}', {
                  'p0': AppDates.dayMonth(m.periodEnd),
                }),
          style: AppTextStyles.caption,
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyMembershipsPage(),
                ),
              );
              _load();
            },
            child: Text(context.tr('إدارة العضوية')),
          ),
        ),
      ],
    );
  }
}

/// «3 س 30 د» من الدقائق.
String membershipHours(BuildContext context, int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (m == 0) {
    // تمييز العدد العربي: ساعة واحدة، ساعتان، 3–10 ساعات، 11+ ساعة.
    return switch (h) {
      1 => context.tr('ساعة واحدة'),
      2 => context.tr('ساعتان'),
      0 || (>= 3 && <= 10) => context.trArgs('{p0} ساعات', {'p0': h}),
      _ => context.trArgs('{p0} ساعة', {'p0': h}),
    };
  }
  return context.trArgs('{p0} س {p1} د', {'p0': h, 'p1': m});
}
