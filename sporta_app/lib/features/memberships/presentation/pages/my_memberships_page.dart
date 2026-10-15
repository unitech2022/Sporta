import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/membership_repository.dart';
import '../../domain/entities/membership.dart';
import '../widgets/club_membership_section.dart';
import '../widgets/membership_benefits.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// «عضوياتي»: عضويات اللاعب الفعّالة في الأندية مع التحكم في التجديد
/// التلقائي. إيقاف التجديد لا يلغي العضوية فوراً — تبقى حتى نهاية الشهر.
class MyMembershipsPage extends StatefulWidget {
  const MyMembershipsPage({super.key});

  @override
  State<MyMembershipsPage> createState() => _MyMembershipsPageState();
}

class _MyMembershipsPageState extends State<MyMembershipsPage> {
  final _repo = getIt<MembershipRepository>();
  List<Membership>? _items;
  String? _error;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.fetchMine();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.display);
    }
  }

  Future<void> _toggle(Membership m, bool autoRenew) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!autoRenew) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('إيقاف التجديد التلقائي؟')),
          content: Text(
            ctx.trArgs(
              'تبقى عضويتك ومزاياها حتى {p0} ثم تنتهي ولن يُخصم شيء.',
              {'p0': AppDates.dayMonth(m.periodEnd)},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('تراجع')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive,
              ),
              child: Text(ctx.tr('إيقاف التجديد')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy.add(m.id));
    try {
      final updated = await _repo.setAutoRenew(m.id, autoRenew);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final x in _items ?? <Membership>[]) x.id == m.id ? updated : x,
        ];
      });
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: context.tr('عضوياتي'),
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: items == null
                ? Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Text(_error!, style: AppTextStyles.body),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              const Icon(
                                Icons.workspace_premium_outlined,
                                size: 56,
                                color: membershipGold,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                context.tr('لا توجد عضويات بعد'),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading3,
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.xl,
                                ),
                                child: Text(
                                  context.tr(
                                    'افتح صفحة أي ملعب واشترك في عضوية ناديه لتحصل على خصومات وأولوية في الحجز.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: context.safeBottom(
                              const EdgeInsets.all(AppSizes.pagePadding),
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSizes.md),
                            itemBuilder: (_, i) => _card(context, items[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Membership m) {
    final left = m.remainingMinutes;
    final image = m.venueImageUrl;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: membershipGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: membershipGold.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس البطاقة: كبطاقة عضوية ذهبية.
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [Color(0xFF0A2540), Color(0xFF1F3B5C)],
              ),
            ),
            child: Row(
              children: [
                NetworkCircleAvatar(
                  imageUrl: image,
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.sports_tennis, color: Colors.white),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.venueName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.planName,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFFE8A3),
                        ),
                      ),
                    ],
                  ),
                ),
                const MemberBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MembershipBenefits(
                  discountPercent: m.discountPercent,
                  monthlyDiscountHours: m.monthlyDiscountHours,
                  priorityDays: m.priorityDays,
                ),
                if (left != null) ...[
                  const SizedBox(height: AppSizes.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: m.monthlyDiscountHours! == 0
                          ? 0
                          : (m.usedDiscountMinutes /
                                    (m.monthlyDiscountHours! * 60))
                                .clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.muted,
                      color: membershipGold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    context.trArgs('متبقٍ من ساعات الخصم هذا الشهر: {p0}', {
                      'p0': membershipHours(context, left),
                    }),
                    style: AppTextStyles.caption,
                  ),
                ],
                const Divider(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('التجديد التلقائي'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            m.autoRenew
                                ? context.trArgs(
                                    'يتجدد في {p0} بـ {p1} ر.س من محفظتك',
                                    {
                                      'p0': AppDates.dayMonth(m.periodEnd),
                                      'p1': money(m.price),
                                    },
                                  )
                                : context.trArgs('تنتهي في {p0} — لن تتجدد', {
                                    'p0': AppDates.dayMonth(m.periodEnd),
                                  }),
                            style: AppTextStyles.caption.copyWith(
                              color: m.autoRenew
                                  ? AppColors.mutedForeground
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: m.autoRenew,
                      activeTrackColor: membershipGold,
                      onChanged: _busy.contains(m.id)
                          ? null
                          : (v) => _toggle(m, v),
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
}
