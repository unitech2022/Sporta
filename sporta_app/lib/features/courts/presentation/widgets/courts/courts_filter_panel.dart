import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/filter_chip_group.dart';
import '../../../../locations/data/location_models.dart';
import '../../../domain/entities/court_entity.dart';
import '../../cubit/courts_list/courts_cubit.dart';
import '../../../../../core/localization/tr_global.dart';

/// The courts filter/sort sections shown inside the shared filter sheet. Purely
/// presentational: it reports a new [CourtsFilters] through [onChanged] and
/// never talks to the cubit directly.
class CourtsFilterPanel extends StatelessWidget {
  const CourtsFilterPanel({
    super.key,
    required this.filters,
    required this.cities,
    this.districts = const [],
    required this.onChanged,
  });

  final CourtsFilters filters;

  /// Cities to offer in the picker — the ones added in the database.
  final List<CityEntity> cities;

  /// Districts of the currently selected city (empty when none is selected).
  final List<DistrictEntity> districts;

  final ValueChanged<CourtsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSection(
          title: context.tr('ترتيب حسب'),
          child: FilterChipGroup(
            options: [
              ('available', trg('المتاح الأقرب')),
              ('rating', trg('التقييم')),
              ('price', trg('السعر')),
              ('distance', trg('المسافة')),
            ],
            selected: filters.sortBy,
            onSelected: (v) => onChanged(filters.copyWith(sortBy: v)),
          ),
        ),
        if (cities.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FilterSection(
                  title: context.tr('المدينة'),
                  child: _PickerDropdown(
                    icon: Icons.location_city_outlined,
                    // Values are Arabic names: that's what a venue stores
                    // and what the list is filtered against.
                    options: [
                      for (final city in cities)
                        (
                          city.nameAr,
                          _label(context, city.nameAr, city.nameEn),
                        ),
                    ],
                    selected: filters.city,
                    allLabel: context.tr('كل المدن'),
                    onSelected: (v) => onChanged(filters.copyWith(city: v)),
                  ),
                ),
              ),
              // The district only makes sense once a city narrows it down.
              if (filters.city.isNotEmpty) ...[
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: FilterSection(
                    title: context.tr('الحي'),
                    child: _PickerDropdown(
                      icon: Icons.location_on_outlined,
                      options: [
                        for (final d in districts)
                          (d.nameAr, _label(context, d.nameAr, d.nameEn)),
                      ],
                      selected: filters.district,
                      allLabel: districts.isEmpty
                          ? context.tr('لا توجد أحياء')
                          : context.tr('كل الأحياء'),
                      enabled: districts.isNotEmpty,
                      onSelected: (v) =>
                          onChanged(filters.copyWith(district: v)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSizes.md),
        FilterSection(
          title: context.tr('نوع الملعب'),
          child: FilterChipGroup(
            options: [
              ('all', trg('الكل')),
              ('indoor', trg('مغطى')),
              ('outdoor', trg('مفتوح')),
            ],
            selected: _typeValue(filters.type),
            onSelected: (v) => onChanged(
              v == 'all'
                  ? filters.copyWith(clearType: true)
                  : filters.copyWith(
                      type: v == 'indoor'
                          ? CourtType.indoor
                          : CourtType.outdoor,
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        FilterSection(
          title: context.tr('الجنس'),
          child: FilterChipGroup(
            options: [
              ('all', trg('الكل')),
              ('men', trg('رجال')),
              ('women', trg('نساء')),
              ('family', trg('عائلي')),
            ],
            selected: _genderValue(filters.gender),
            onSelected: (v) => onChanged(
              v == 'all'
                  ? filters.copyWith(clearGender: true)
                  : filters.copyWith(gender: _genderFromValue(v)),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        FilterSection(
          title: context.tr('نطاق السعر'),
          child: FilterChipGroup(
            options: [
              ('all', trg('الكل')),
              ('low', trg('منخفض')),
              ('medium', trg('متوسط')),
              ('high', trg('مرتفع')),
            ],
            selected: filters.priceRange,
            onSelected: (v) => onChanged(filters.copyWith(priceRange: v)),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        FilterSection(
          title: context.tr('التقييم'),
          child: FilterChipGroup(
            options: [('all', trg('الكل')), ('4+', '4+'), ('4.5+', '4.5+')],
            selected: filters.ratingFilter,
            onSelected: (v) => onChanged(filters.copyWith(ratingFilter: v)),
          ),
        ),
      ],
    );
  }

  /// Arabic name in an RTL layout (and whenever there's no English one).
  static String _label(BuildContext context, String nameAr, String nameEn) {
    final useArabic =
        Directionality.of(context) == TextDirection.rtl || nameEn.isEmpty;
    return useArabic ? nameAr : nameEn;
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

/// A compact single-select dropdown for the long location lists — a chip wrap
/// of every city would push the rest of the filters off the panel.
class _PickerDropdown extends StatelessWidget {
  const _PickerDropdown({
    required this.icon,
    required this.options,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
    this.enabled = true,
  });

  final IconData icon;

  /// (value, label) pairs; the value is what the filter stores.
  final List<(String, String)> options;

  /// Current filter value — empty means "no restriction".
  final String selected;

  /// Label of the empty option ("كل المدن" / "كل الأحياء").
  final String allLabel;

  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // A stale filter (e.g. a city removed from the database) falls back to the
    // empty option so the dropdown never gets a value that isn't in its items.
    final value = options.any((o) => o.$1 == selected) ? selected : '';

    // A plain DropdownButton (not the form field) so it always renders the
    // filter it is given — "مسح الفلاتر" has to visibly reset it too.
    return Container(
      height: AppSizes.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.mutedForeground),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.mutedForeground,
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      allLabel,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  for (final option in options)
                    DropdownMenuItem(
                      value: option.$1,
                      child: Text(option.$2, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: enabled ? (v) => onSelected(v ?? '') : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
