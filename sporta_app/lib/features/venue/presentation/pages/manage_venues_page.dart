import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/entities/owner_court_slot.dart';
import '../../domain/entities/owner_venue.dart';
import '../cubit/manage_venues_cubit.dart';
import 'court_detail_page.dart';
import 'court_form_page.dart';
import 'venue_form_page.dart';
import 'venue_pricing_page.dart';
import '../../../memberships/presentation/pages/venue_memberships_page.dart';
import '../../../memberships/presentation/widgets/membership_benefits.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Venue-owner management: list venues + their courts, create venues, add/edit courts.
class ManageVenuesPage extends StatelessWidget {
  const ManageVenuesPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageVenuesCubit>(
      create: (_) => getIt<ManageVenuesCubit>()..load(),
      child: _ManageVenuesView(onBack: onBack),
    );
  }
}

class _ManageVenuesView extends StatelessWidget {
  const _ManageVenuesView({this.onBack});

  final VoidCallback? onBack;

  Future<void> _snack(BuildContext context, String? error, String ok) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: BlocBuilder<ManageVenuesCubit, ManageVenuesState>(
                builder: (context, state) => _body(context, state),
              ),
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<ManageVenuesCubit, ManageVenuesState>(
          builder: (context, state) {
            if (state.status != ManageVenuesStatus.success ||
                state.venues.isEmpty) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              onPressed: () => _addVenue(context),
              icon: const Icon(Icons.add),
              label: Text(context.tr('ملعب جديد')),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSizes.md),
              ],
              Text(
                context.tr('إدارة ملاعبي'),
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ManageVenuesState state) {
    switch (state.status) {
      case ManageVenuesStatus.initial:
      case ManageVenuesStatus.loading:
        return const SkeletonCardList(itemCount: 2, imageHeight: 120);
      case ManageVenuesStatus.failure:
        return Center(
          child: Text(
            state.error ?? context.tr('تعذّر تحميل الأندية'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
        );
      case ManageVenuesStatus.success:
        if (state.venues.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stadium_outlined,
                    color: AppColors.mutedForeground,
                    size: 56,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr('لا توجد ملاعب بعد — أضف ملعبك الأول'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton.icon(
                    onPressed: () => _addVenue(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('إضافة ملعب')),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: context.safeBottom(
            const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              AppSizes.pagePadding,
              AppSizes.pagePadding,
              88,
            ),
          ),
          children: [
            for (final v in state.venues) ...[
              _venueCard(context, v),
              const SizedBox(height: AppSizes.lg),
            ],
          ],
        );
    }
  }

  Widget _venueCard(BuildContext context, OwnerVenue v) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (v.imageUrl != null && v.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Image.network(
                    ApiEndpoints.fileUrl(v.imageUrl!),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.stadium_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.stadium_outlined, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  v.name,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              if (!v.isApproved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    context.tr('بانتظار موافقة الإدارة'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text('${v.city} • ${v.genderLabel}', style: AppTextStyles.caption),
          if (v.courts.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            // أسعار النادي حسب الوقت — فترات اليوم لكل ملاعبه دفعة واحدة.
            OutlinedButton.icon(
              onPressed: () => _openPricing(context, v),
              icon: const Icon(Icons.schedule_outlined, size: 18),
              label: Text(context.tr('الأسعار حسب الوقت')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          // عضويات النادي: خطط شهرية بخصم وأولوية حجز.
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    VenueMembershipsPage(venueId: v.id, venueName: v.name),
              ),
            ),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: Text(context.tr('عضويات النادي')),
            style: OutlinedButton.styleFrom(
              foregroundColor: membershipGold,
              side: BorderSide(color: membershipGold.withValues(alpha: 0.6)),
              minimumSize: const Size.fromHeight(42),
            ),
          ),
          const Divider(height: AppSizes.xl),
          Text(
            context.trArgs('الملاعب ({p0})', {'p0': v.courts.length}),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (v.courts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Text(
                context.tr('لا توجد ملاعب بعد'),
                style: AppTextStyles.caption,
              ),
            )
          else
            for (final c in v.courts) _courtCard(context, c),
        ],
      ),
    );
  }

  Widget _courtCard(BuildContext context, OwnerCourt c) {
    return GestureDetector(
      onTap: () => _openCourtDetail(context, c),
      child: Container(
        margin: const EdgeInsets.only(top: AppSizes.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFC),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner with status + type chips.
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: (c.imageUrl != null && c.imageUrl!.isNotEmpty)
                      ? Image.network(
                          ApiEndpoints.fileUrl(c.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
                PositionedDirectional(
                  top: AppSizes.sm,
                  start: AppSizes.sm,
                  child: _chip(
                    c.isAvailable ? trg('متاح') : trg('موقوف'),
                    c.isAvailable
                        ? AppColors.success
                        : AppColors.mutedForeground,
                  ),
                ),
                PositionedDirectional(
                  top: AppSizes.sm,
                  end: AppSizes.sm,
                  child: _chip(c.typeLabel, AppColors.primary),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (c.latitude != null && c.longitude != null)
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    context.trArgs('حجز: {p0}', {
                      'p0': _tiersLabel(c.bookingTiers),
                    }),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editCourt(context, c),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(context.tr('تعديل')),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      OutlinedButton.icon(
                        onPressed: () => _deleteCourt(context, c),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(context.tr('حذف')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                          side: const BorderSide(color: AppColors.destructive),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: const Color(0xFFEFF6FF),
    child: const Center(
      child: Icon(Icons.stadium_outlined, size: 40, color: AppColors.primary),
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  String _tiersLabel(List<CourtTier> tiers) {
    if (tiers.isEmpty) return '—';
    final sorted = [...tiers]
      ..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    return sorted
        .map(
          (t) => trgArgs('{p0}د:{p1}', {
            'p0': t.durationMinutes,
            'p1': money(t.price),
          }),
        )
        .join(' / ');
  }

  // ── dialogs ────────────────────────────────────────────────────────────────

  Future<void> _addVenue(BuildContext context) async {
    final cubit = context.read<ManageVenuesCubit>();
    final result = await Navigator.of(context).push<VenueFormResult>(
      MaterialPageRoute(builder: (_) => const VenueFormPage()),
    );
    if (result == null) return;
    final error = await cubit.createVenue(
      name: result.name,
      nameEn: result.nameEn,
      city: result.city,
      district: result.district,
      cityId: result.cityId,
      districtId: result.districtId,
      address: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
      imageUrls: result.imageUrls,
      courtCount: result.courtCount,
      pricePerHour: result.pricePerHour,
      bookingTiers: result.bookingTiers,
    );
    if (context.mounted) _snack(context, error, trg('تمت إضافة الملعب'));
  }

  Future<void> _openPricing(BuildContext context, OwnerVenue v) async {
    final cubit = context.read<ManageVenuesCubit>();
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => VenuePricingPage(venue: v)));
    if (saved == true) cubit.load();
  }

  Future<void> _openCourtDetail(BuildContext context, OwnerCourt c) async {
    final action = await Navigator.of(context).push<CourtDetailAction>(
      MaterialPageRoute(builder: (_) => CourtDetailPage(court: c)),
    );
    if (!context.mounted) return;
    if (action == CourtDetailAction.edit) {
      await _editCourt(context, c);
    } else if (action == CourtDetailAction.delete) {
      await _deleteCourt(context, c);
    }
  }

  Future<void> _editCourt(BuildContext context, OwnerCourt c) async {
    final cubit = context.read<ManageVenuesCubit>();
    final result = await Navigator.of(context).push<CourtFormResult>(
      MaterialPageRoute(builder: (_) => CourtFormPage(existing: c)),
    );
    if (result == null) return;
    final error = await cubit.updateCourt(
      courtId: c.id,
      pricePerHour: result.price,
      isAvailable: result.isAvailable,
      courtCount: result.courtCount,
      imageUrl: result.imageUrl,
      latitude: result.latitude,
      longitude: result.longitude,
      bookingTiers: result.bookingTiers,
    );
    if (context.mounted) _snack(context, error, trg('تم تحديث الملعب'));
  }

  Future<void> _deleteCourt(BuildContext context, OwnerCourt c) async {
    final cubit = context.read<ManageVenuesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: Text(context.tr('حذف الملعب')),
          content: Text(
            context.trArgs('هل أنت متأكد من حذف "{p0}"؟', {'p0': c.name}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('إلغاء')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                context.tr('حذف'),
                style: const TextStyle(color: AppColors.destructive),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final error = await cubit.deleteCourt(c.id);
    if (context.mounted) _snack(context, error, trg('تم حذف الملعب'));
  }
}
