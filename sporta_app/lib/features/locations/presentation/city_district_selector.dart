import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/state/app_scope.dart';
import '../data/location_models.dart';
import '../data/location_repository.dart';

/// Two dependent dropdowns: pick a city, then its district loads. Reusable in
/// registration and profile editing. Reports selections via [onChanged].
class CityDistrictSelector extends StatefulWidget {
  const CityDistrictSelector({
    super.key,
    this.initialCityId,
    this.initialDistrictId,
    this.required = true,
    required this.onChanged,
  });

  final int? initialCityId;
  final int? initialDistrictId;
  final bool required;

  /// Called whenever the city or district selection changes.
  final void Function(CityEntity? city, DistrictEntity? district) onChanged;

  @override
  State<CityDistrictSelector> createState() => _CityDistrictSelectorState();
}

class _CityDistrictSelectorState extends State<CityDistrictSelector> {
  final _repo = getIt<LocationRepository>();

  List<CityEntity> _cities = [];
  List<DistrictEntity> _districts = [];
  CityEntity? _city;
  DistrictEntity? _district;

  bool _loadingCities = true;
  bool _loadingDistricts = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _loadingCities = true;
      _error = false;
    });
    try {
      final cities = await _repo.fetchCities();
      if (!mounted) return;
      CityEntity? initial;
      for (final c in cities) {
        if (c.id == widget.initialCityId) {
          initial = c;
          break;
        }
      }
      setState(() {
        _cities = cities;
        _city = initial;
        _loadingCities = false;
      });
      if (initial != null) await _loadDistricts(initial, widget.initialDistrictId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
        _error = true;
      });
    }
  }

  Future<void> _loadDistricts(CityEntity city, [int? preselectId]) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _district = null;
    });
    try {
      final districts = await _repo.fetchDistricts(city.id);
      if (!mounted) return;
      DistrictEntity? pre;
      for (final d in districts) {
        if (d.id == preselectId) {
          pre = d;
          break;
        }
      }
      setState(() {
        _districts = districts;
        _district = pre;
        _loadingDistricts = false;
      });
      if (pre != null) widget.onChanged(city, pre);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDistricts = false);
    }
  }

  void _onCityChanged(CityEntity? city) {
    setState(() {
      _city = city;
      _district = null;
      _districts = [];
    });
    widget.onChanged(city, null);
    if (city != null) _loadDistricts(city);
  }

  String _cityName(CityEntity c) =>
      Directionality.of(context) == TextDirection.rtl ? c.nameAr : c.nameEn;
  String _districtName(DistrictEntity d) =>
      Directionality.of(context) == TextDirection.rtl ? d.nameAr : d.nameEn;

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _ErrorBox(onRetry: _loadCities);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('${context.tr('city')}${widget.required ? ' *' : ''}'),
        const SizedBox(height: AppSizes.sm),
        DropdownButtonFormField<CityEntity>(
          initialValue: _city,
          isExpanded: true,
          hint: Text(
            _loadingCities ? context.tr('جارٍ التحميل...') : context.tr('اختر المدينة'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
          ),
          icon: _loadingCities
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.arrow_drop_down),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_city_outlined,
                size: AppSizes.iconMd, color: AppColors.mutedForeground),
          ),
          items: _cities
              .map((c) => DropdownMenuItem(value: c, child: Text(_cityName(c))))
              .toList(),
          onChanged: _loadingCities ? null : _onCityChanged,
          validator: (v) => widget.required && v == null
              ? context.tr('cityRequired')
              : null,
        ),
        const SizedBox(height: AppSizes.xl),
        _label(context.tr('district')),
        const SizedBox(height: AppSizes.sm),
        DropdownButtonFormField<DistrictEntity>(
          initialValue: _district,
          isExpanded: true,
          hint: Text(
            _city == null
                ? context.tr('اختر المدينة أولاً')
                : _loadingDistricts
                    ? context.tr('جارٍ التحميل...')
                    : _districts.isEmpty
                        ? context.tr('لا توجد أحياء لهذه المدينة')
                        : context.tr('اختر الحي'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
          ),
          icon: _loadingDistricts
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.arrow_drop_down),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined,
                size: AppSizes.iconMd, color: AppColors.mutedForeground),
          ),
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(_districtName(d))))
              .toList(),
          onChanged: (_city == null || _districts.isEmpty)
              ? null
              : (d) {
                  setState(() => _district = d);
                  widget.onChanged(_city, d);
                },
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('تعذّر تحميل المدن'),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.tr('إعادة المحاولة'))),
        ],
      ),
    );
  }
}
