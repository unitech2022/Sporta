import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../domain/entities/court_entity.dart';
import '../../cubit/courts_list/courts_cubit.dart';
import 'filter_chip_group.dart';

/// The collapsible filter/sort panel. Purely presentational: it reports a new
/// [CourtsFilters] through [onChanged] and never talks to the cubit directly.
class CourtsFilterPanel extends StatelessWidget {
  const CourtsFilterPanel({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.onReset,
  });

  final CourtsFilters filters;
  final ValueChanged<CourtsFilters> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSection(
              title: 'ترتيب حسب',
              child: FilterChipGroup(
                options: const [
                  ('rating', 'التقييم'),
                  ('price', 'السعر'),
                  ('distance', 'المسافة'),
                ],
                selected: filters.sortBy,
                onSelected: (v) => onChanged(filters.copyWith(sortBy: v)),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'المدينة',
              child: FilterChipGroup(
                options: const [
                  ('', 'الكل'),
                  ('الدمام', 'الدمام'),
                  ('الخبر', 'الخبر'),
                  ('القطيف', 'القطيف'),
                ],
                selected: filters.city,
                onSelected: (v) => onChanged(filters.copyWith(city: v)),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'نوع الملعب',
              child: FilterChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('indoor', 'مغطى'),
                  ('outdoor', 'مفتوح'),
                ],
                selected: _typeValue(filters.type),
                onSelected: (v) => onChanged(v == 'all'
                    ? filters.copyWith(clearType: true)
                    : filters.copyWith(
                        type: v == 'indoor'
                            ? CourtType.indoor
                            : CourtType.outdoor,
                      )),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'الجنس',
              child: FilterChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('men', 'رجال'),
                  ('women', 'نساء'),
                  ('family', 'عائلي'),
                ],
                selected: _genderValue(filters.gender),
                onSelected: (v) => onChanged(v == 'all'
                    ? filters.copyWith(clearGender: true)
                    : filters.copyWith(gender: _genderFromValue(v))),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'نطاق السعر',
              child: FilterChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('low', 'منخفض'),
                  ('medium', 'متوسط'),
                  ('high', 'مرتفع'),
                ],
                selected: filters.priceRange,
                onSelected: (v) => onChanged(filters.copyWith(priceRange: v)),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'التقييم',
              child: FilterChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('4+', '4+'),
                  ('4.5+', '4.5+'),
                ],
                selected: filters.ratingFilter,
                onSelected: (v) => onChanged(filters.copyWith(ratingFilter: v)),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            FilterSection(
              title: 'مدة الجلسة',
              child: FilterChipGroup(
                options: const [
                  ('all', 'الكل'),
                  ('60', '60 دقيقة'),
                  ('90', '90 دقيقة'),
                  ('120', '120 دقيقة'),
                ],
                selected: filters.duration,
                onSelected: (v) => onChanged(filters.copyWith(duration: v)),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: const Text('مسح الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _typeValue(CourtType? type) => type == null
      ? 'all'
      : type == CourtType.indoor
          ? 'indoor'
          : 'outdoor';

  static String _genderValue(CourtGender? gender) {
    switch (gender) {
      case CourtGender.men:
        return 'men';
      case CourtGender.women:
        return 'women';
      case CourtGender.family:
        return 'family';
      default:
        return 'all';
    }
  }

  static CourtGender _genderFromValue(String value) {
    switch (value) {
      case 'men':
        return CourtGender.men;
      case 'women':
        return CourtGender.women;
      default:
        return CourtGender.family;
    }
  }
}
