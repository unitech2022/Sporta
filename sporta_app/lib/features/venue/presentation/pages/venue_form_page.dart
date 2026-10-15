import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/image_upload_field.dart';
import '../../../locations/data/location_models.dart';
import '../../../locations/presentation/city_district_selector.dart';
import '../../domain/entities/owner_venue.dart';
import 'location_picker_page.dart';
import '../../../../core/utils/system_insets.dart';

/// Result returned by [VenueFormPage] when the owner saves.
class VenueFormResult {
  VenueFormResult({
    required this.name,
    required this.nameEn,
    required this.address,
    required this.cityId,
    required this.districtId,
    required this.courtCount,
    required this.pricePerHour,
    required this.bookingTiers,
    required this.imageUrls,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
  });

  final String name;

  /// اسم الملعب بالإنجليزية.
  final String nameEn;

  final String address;

  /// معرّفا المدينة والحي — إلزاميان: الخادم يرفض إنشاء ملعب بدونهما.
  final int cityId;
  final int districtId;

  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;
  final int courtCount;
  final double pricePerHour;
  final List<CourtTier> bookingTiers;
  final List<String> imageUrls;
}

/// Full-page form for creating a new ملعب: name, photos, city/district,
/// location on the map, number of internal courts and its booking prices —
/// all collected in a single step.
class VenueFormPage extends StatefulWidget {
  const VenueFormPage({super.key});

  @override
  State<VenueFormPage> createState() => _VenueFormPageState();
}

class _VenueFormPageState extends State<VenueFormPage> {
  final _name = TextEditingController();
  final _nameEn = TextEditingController();
  final _price = TextEditingController();
  final _courtCount = TextEditingController(text: '1');
  final List<String> _images = [];
  final List<_TierRow> _tiers = [];

  CityEntity? _city;
  DistrictEntity? _district;
  PickedLocation? _picked;

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _price.dispose();
    _courtCount.dispose();
    for (final r in _tiers) {
      r.duration.dispose();
      r.price.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: _picked?.latLng,
          title: context.tr('موقع الملعب'),
        ),
      ),
    );
    if (result != null) setState(() => _picked = result);
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('اسم الملعب مطلوب'))));
      return;
    }
    if (_nameEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('اسم الملعب بالإنجليزية مطلوب'))),
      );
      return;
    }
    if (_city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('يرجى اختيار المدينة'))),
      );
      return;
    }
    if (_district == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('يرجى اختيار الحي'))));
      return;
    }
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('يرجى تحديد موقع الملعب'))),
      );
      return;
    }
    final tierError = _validateTiers();
    if (tierError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tierError)));
      return;
    }
    Navigator.pop(
      context,
      VenueFormResult(
        name: _name.text.trim(),
        nameEn: _nameEn.text.trim(),
        address: _picked!.displayAddress ?? '',
        cityId: _city!.id,
        districtId: _district!.id,
        city: _city!.nameAr,
        district: _district!.nameAr,
        latitude: _picked!.latLng.latitude,
        longitude: _picked!.latLng.longitude,
        courtCount: (int.tryParse(_courtCount.text.trim()) ?? 1).clamp(1, 50),
        pricePerHour: double.tryParse(_price.text.trim()) ?? 0,
        bookingTiers: _buildTiers(),
        imageUrls: _images,
      ),
    );
  }

  /// Mirrors the backend's `[Range(15, 480)]` on `DurationMinutes` so a bad
  /// value is caught here instead of surfacing as a raw 400 from the server.
  String? _validateTiers() {
    for (final r in _tiers) {
      final durText = r.duration.text.trim();
      final priceText = r.price.text.trim();
      if (durText.isEmpty && priceText.isEmpty) continue;
      final d = int.tryParse(durText);
      if (d == null || d < 15 || d > 480) {
        return context.tr('مدة الشريحة يجب أن تكون بين 15 و480 دقيقة');
      }
      final p = double.tryParse(priceText);
      if (p == null || p <= 0) {
        return context.tr('يرجى إدخال سعر صحيح لكل شريحة');
      }
    }
    return null;
  }

  List<CourtTier> _buildTiers() {
    final byDuration = <int, CourtTier>{};
    for (final r in _tiers) {
      final d = int.tryParse(r.duration.text.trim());
      final p = double.tryParse(r.price.text.trim());
      if (d == null || d <= 0 || p == null || p <= 0) continue;
      byDuration[d] = CourtTier(durationMinutes: d, price: p);
    }
    return byDuration.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('ملعب جديد')),
        ),
        body: ListView(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          children: [
            _sectionLabel(context.tr('صور الملعب')),
            const SizedBox(height: AppSizes.sm),
            _photosGrid(),
            const SizedBox(height: AppSizes.xl),
            _field(_name, context.tr('اسم الملعب *')),
            const SizedBox(height: AppSizes.xl),
            _field(_nameEn, context.tr('اسم الملعب بالإنجليزية *')),
            const SizedBox(height: AppSizes.xl),
            CityDistrictSelector(
              required: true,
              onChanged: (city, district) => setState(() {
                _city = city;
                _district = district;
              }),
            ),
            const SizedBox(height: AppSizes.xl),
            _sectionLabel(context.tr('الموقع على الخريطة')),
            const SizedBox(height: AppSizes.sm),
            _locationButton(),
            const SizedBox(height: AppSizes.xl),
            _field(
              _courtCount,
              context.tr('عدد الملاعب الداخلية *'),
              number: true,
            ),
            const SizedBox(height: AppSizes.md),
            _field(_price, context.tr('السعر للساعة'), number: true),
            const SizedBox(height: AppSizes.xl),
            _TierEditor(rows: _tiers, onChanged: () => setState(() {})),
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(context.tr('إضافة الملعب')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    context.tr(text),
    style: AppTextStyles.bodySmall.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _photosGrid() {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: [
        for (var i = 0; i < _images.length; i++)
          SizedBox(
            width: 100,
            height: 100,
            child: ImageUploadField(
              height: 100,
              value: _images[i],
              onChanged: (url) => setState(() {
                if (url == null) {
                  _images.removeAt(i);
                } else {
                  _images[i] = url;
                }
              }),
            ),
          ),
        SizedBox(
          width: 100,
          height: 100,
          child: ImageUploadField(
            height: 100,
            value: null,
            onChanged: (url) {
              if (url != null) setState(() => _images.add(url));
            },
          ),
        ),
      ],
    );
  }

  Widget _locationButton() {
    return OutlinedButton.icon(
      onPressed: _pickLocation,
      icon: Icon(
        _picked == null ? Icons.add_location_alt_outlined : Icons.location_on,
      ),
      label: Text(
        _picked == null
            ? context.tr('تحديد موقع الملعب على الخريطة *')
            : (_picked!.displayAddress ?? context.tr('تم تحديد الموقع')),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: context.tr(label),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
    );
  }
}

/// Duration→price tier editor. Durations are free-form (20, 45, 120 دقيقة…).
class _TierEditor extends StatelessWidget {
  const _TierEditor({required this.rows, required this.onChanged});

  final List<_TierRow> rows;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('أسعار الشرائح (المدة بالدقائق → السعر)'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                rows.add(_TierRow());
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.tr('شريحة')),
            ),
          ],
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.xs),
            child: Text(
              context.tr('مثال: 20 دقيقة، 60 دقيقة، 120 دقيقة أو غيرها'),
              style: AppTextStyles.caption,
            ),
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rows[i].duration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.tr('المدة (دقيقة)'),
                      hintText: '15-480',
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: rows[i].price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.tr('السعر'),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    rows.removeAt(i);
                    onChanged();
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TierRow {
  final duration = TextEditingController();
  final price = TextEditingController();
}
