import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import '../../../../../core/state/app_scope.dart';
import 'court_slots_row.dart';

/// A court summary card in the courts list. Tapping it opens the court's
/// profile ([onTap]).
///
/// في البحث بالوقت (`court.freeSlots` غير null) تعرض البطاقة مواعيد الملعب
/// الفارغة، والضغط على موعد يحجزه مباشرة ([onSlotTap]). بدونه (المفضّلة مثلاً)
/// يبقى زر «احجز الآن» ([onBookTap]).
class CourtCard extends StatelessWidget {
  const CourtCard({
    super.key,
    required this.court,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onBookTap,
    this.onTap,
    this.onSlotTap,
    this.slotDuration = 60,
  });

  final CourtEntity court;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onBookTap;

  /// Opens the court details page.
  final VoidCallback? onTap;

  /// يحجز موعداً فارغاً (HH:mm) من صف المواعيد.
  final ValueChanged<String>? onSlotTap;

  /// مدة البحث بالوقت — يُكتب بها سطر السعر («ساعة من …»).
  final int slotDuration;

  bool get _timeSearch => court.freeSlots != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: AppSizes.radiusXl,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(context),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppSizes.radiusXl),
        topRight: Radius.circular(AppSizes.radiusXl),
      ),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _coverImage(),
            // تدرّج داكن أسفل الصورة حتى يُقرأ الاسم والسعر فوق أي صورة.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.45, 1],
                  colors: [Colors.transparent, Color(0xB3000000)],
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSizes.sm,
              end: AppSizes.sm,
              child: _FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteTap),
            ),
            PositionedDirectional(
              start: AppSizes.md,
              end: AppSizes.md,
              bottom: AppSizes.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      court.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _priceTag(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceTag(BuildContext context) {
    final price = _timeSearch
        ? (court.fromPrice ?? court.bookingPriceFor(slotDuration)?.round() ??
            court.totalPrice)
        : court.totalPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _timeSearch ? _durationFromLabel(context) : context.tr('يبدأ من'),
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
        Text(
          context.trArgs('{p0} ر.س', {'p0': price}),
          style: AppTextStyles.heading3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _durationFromLabel(BuildContext context) => switch (slotDuration) {
        60 => context.tr('ساعة من'),
        90 => context.tr('ساعة ونصف من'),
        120 => context.tr('ساعتان من'),
        _ => context.trArgs('{p0} دقيقة من', {'p0': slotDuration}),
      };

  /// صورة الملعب حين يرفعها صاحبه، وإلا بطاقة الاسم البديلة. الفشل والتحميل
  /// يسقطان إلى البديلة كذلك، فلا يظهر مربع أبيض ولا أيقونة عطب.
  Widget _coverImage() {
    final url = court.imageUrl;
    if (url == null || url.isEmpty) return _coverPlaceholder();

    return Image.network(
      ApiEndpoints.fileUrl(url),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _coverPlaceholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return ColoredBox(
      color: AppColors.secondary.withValues(alpha: 0.85),
      child: Center(
        child: Icon(
          Icons.sports_tennis_rounded,
          size: 56,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final place = [court.distance, court.areaLabel, court.city]
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: AppSizes.iconSm, color: AppColors.mutedForeground),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ),
              Icon(
                court.type == CourtType.indoor
                    ? Icons.roofing_rounded
                    : Icons.wb_sunny_outlined,
                size: AppSizes.iconSm,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 3),
              Text(
                courtTypeLabel(court.type),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
              // الرجال هو الغالب؛ النسائي والعائلي يُنبَّه عليهما.
              if (court.gender == CourtGender.women ||
                  court.gender == CourtGender.family) ...[
                const SizedBox(width: AppSizes.sm),
                Text(
                  courtGenderLabel(court.gender),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ],
              if (court.reviews > 0) ...[
                const SizedBox(width: AppSizes.sm),
                const Icon(Icons.star_rounded,
                    size: AppSizes.iconSm, color: Color(0xFFFACC15)),
                const SizedBox(width: 2),
                Text(
                  court.rating.toStringAsFixed(1),
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (_timeSearch)
            CourtSlotsRow(slots: court.freeSlots!, onSlotTap: onSlotTap)
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton(
                onPressed: onBookTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                ),
                child: Text(context.tr('احجز الآن')),
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: AppSizes.iconMd,
          color: isFavorite ? Colors.red : AppColors.mutedForeground,
        ),
      ),
    );
  }
}
