import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/review_models.dart';

/// لون النجوم الموحّد مع بطاقات الملاعب.
const Color kStarColor = Color(0xFFFACC15);

/// نجوم للعرض فقط (تدعم أنصاف النجوم للمتوسط).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star_rounded
                : value >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: value >= i - 0.5 ? kStarColor : AppColors.border,
          ),
      ],
    );
  }
}

/// نجوم قابلة للضغط (1..5).
class StarPicker extends StatelessWidget {
  const StarPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 34,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedScale(
                scale: value == i ? 1.15 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: value >= i ? kStarColor : AppColors.border,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// شريحة جانب — خضراء للثناء وبرتقالية لما يحتاج تحسيناً.
class ReviewTagChip extends StatelessWidget {
  const ReviewTagChip({
    super.key,
    required this.tag,
    required this.score,
    this.selected = true,
    this.onTap,
    this.count,
  });

  final ReviewTag tag;
  final int score;
  final bool selected;
  final VoidCallback? onTap;

  /// عدد مرات الذكر (في الملخّصات).
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tone = score >= 4 ? AppColors.success : AppColors.warning;
    final fg = selected ? tone : AppColors.mutedForeground;
    final label = context.tr(tag.labelFor(score));
    return Material(
      color: selected ? tone.withValues(alpha: 0.12) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? tone.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tag.icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                count == null ? label : '$label · $count',
                style: AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صورة الطرف: صورة الملعب المربّعة، أو صورة/حرف الشخص الدائرية.
class ReviewAvatar extends StatelessWidget {
  const ReviewAvatar({
    super.key,
    required this.name,
    this.url,
    this.isCourt = false,
    this.size = 44,
  });

  final String name;
  final String? url;
  final bool isCourt;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = isCourt
        ? BorderRadius.circular(AppSizes.radiusLg)
        : BorderRadius.circular(size);
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      child: isCourt
          ? Icon(
              Icons.sports_tennis_rounded,
              color: AppColors.primary,
              size: size * 0.45,
            )
          : Text(
              name.trim().isEmpty ? '?' : name.trim()[0],
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        ApiEndpoints.fileUrl(url!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// شارة صفة الطرف: الملعب / مدرب / لاعب / صاحب الملعب.
class ReviewRoleBadge extends StatelessWidget {
  const ReviewRoleBadge({super.key, required this.role});

  /// court | coach | player | venue
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'court' => ('الملعب', AppColors.primary),
      'coach' => ('مدرب', const Color(0xFF7C3AED)),
      'venue' => ('صاحب الملعب', const Color(0xFFB45309)),
      _ => ('لاعب', AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        context.tr(label),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ملخّص: المتوسط الكبير + توزيع النجوم.
class RatingOverview extends StatelessWidget {
  const RatingOverview({
    super.key,
    required this.average,
    required this.count,
    required this.distribution,
  });

  final double average;
  final int count;
  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Text(
              average.toStringAsFixed(1),
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.secondary,
                fontSize: 40,
                height: 1.1,
              ),
            ),
            StarRow(value: average, size: 16),
            const SizedBox(height: 2),
            Text(
              context.trArgs('{p0} تقييم', {'p0': count}),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSizes.lg),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          '$star',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: kStarColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          child: LinearProgressIndicator(
                            value: count == 0
                                ? 0
                                : (distribution[star] ?? 0) / count,
                            minHeight: 6,
                            backgroundColor: AppColors.muted,
                            valueColor: const AlwaysStoppedAnimation(
                              kStarColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// مراجعة واحدة في قائمة تقييمات الملعب: المقيِّم وصفته والنجوم والجوانب.
class ReviewItemTile extends StatelessWidget {
  const ReviewItemTile({
    super.key,
    required this.review,
    required this.targetType,
  });

  final ReviewItem review;
  final ReviewTargetType targetType;

  @override
  Widget build(BuildContext context) {
    final r = review;
    final when = r.updatedAt ?? r.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReviewAvatar(name: r.raterName, url: r.raterAvatarUrl, size: 36),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.raterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (r.raterRole != 'player') ...[
                        const SizedBox(width: 6),
                        ReviewRoleBadge(role: r.raterRole),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      StarRow(value: r.score.toDouble(), size: 14),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${when.day}/${when.month}/${when.year}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (r.tags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final key in r.tags)
                if (ReviewTag.find(targetType, key) case final tag?)
                  ReviewTagChip(tag: tag, score: r.score),
            ],
          ),
        ],
        if (r.comment != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text(
            r.comment!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ],
    );
  }
}

/// تسمية نوع التجربة للعرض.
String reviewKindLabel(String kind) => switch (kind) {
  'americano' => 'أمريكانو',
  'tournament' => 'بطولة',
  'booking' => 'حجز ملعب',
  'session' => 'جلسة تدريب',
  _ => 'مباراة',
};
