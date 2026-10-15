import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../courts/presentation/widgets/court_detail/court_detail_shared.dart';
import '../../data/review_repository.dart';
import '../../domain/review_models.dart';
import '../pages/court_reviews_page.dart';
import 'review_widgets.dart';

/// قسم «تقييمات اللاعبين» في صفحة الملعب (للاعب وللمالك): الملخّص وأبرز
/// الجوانب وأحدث مراجعتين، و«عرض الكل» لصفحة التقييمات.
class CourtReviewsSection extends StatefulWidget {
  const CourtReviewsSection({super.key, required this.courtId});

  final int courtId;

  @override
  State<CourtReviewsSection> createState() => _CourtReviewsSectionState();
}

class _CourtReviewsSectionState extends State<CourtReviewsSection> {
  CourtRatingsSummary? _summary;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await getIt<ReviewRepository>().fetchCourtRatings(
        widget.courtId,
        pageSize: 2,
      );
      if (mounted) setState(() => _summary = s);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _openAll() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CourtReviewsPage(courtId: widget.courtId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    if (_failed || s == null) return const SizedBox.shrink();
    return DetailSectionCard(
      title: context.tr('تقييمات اللاعبين'),
      icon: Icons.star_outline_rounded,
      action: s.count == 0
          ? null
          : TextButton(
              onPressed: _openAll,
              child: Text(context.tr('عرض الكل')),
            ),
      child: s.count == 0
          ? Text(
              context.tr(
                'لا توجد تقييمات بعد — يقيّمه اللاعبون بعد مبارياتهم عليه',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingOverview(
                  average: s.average,
                  count: s.count,
                  distribution: s.distribution,
                ),
                if (s.topPraised.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in s.topPraised)
                        if (ReviewTag.find(ReviewTargetType.court, t.tag)
                            case final tag?)
                          ReviewTagChip(tag: tag, score: 5, count: t.count),
                    ],
                  ),
                ],
                for (final r in s.reviews) ...[
                  const Divider(height: AppSizes.xl),
                  ReviewItemTile(review: r, targetType: ReviewTargetType.court),
                ],
              ],
            ),
    );
  }
}
