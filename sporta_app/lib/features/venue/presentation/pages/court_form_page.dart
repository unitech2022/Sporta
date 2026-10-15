import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/image_upload_field.dart';
import '../../domain/entities/owner_venue.dart';
import 'location_picker_page.dart';
import '../../../../core/utils/system_insets.dart';

/// Result returned by [CourtFormPage] when the owner saves.
class CourtFormResult {
  CourtFormResult({
    required this.price,
    required this.isAvailable,
    required this.courtCount,
    required this.bookingTiers,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final double price;
  final bool isAvailable;
  final int courtCount;
  final List<CourtTier> bookingTiers;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
}

/// Edit form for an existing court (photo, price, price tiers, internal
/// court count, location and availability). Courts are only created as part
/// of the "ملعب جديد" flow — this page never creates one.
class CourtFormPage extends StatefulWidget {
  const CourtFormPage({super.key, required this.existing});

  final OwnerCourt existing;

  @override
  State<CourtFormPage> createState() => _CourtFormPageState();
}

class _CourtFormPageState extends State<CourtFormPage> {
  late final TextEditingController _price = TextEditingController(
    text: widget.existing.pricePerHour.toStringAsFixed(0),
  );
  late final TextEditingController _courtCount = TextEditingController(
    text: widget.existing.courtCount.toString(),
  );
  late String? _imageUrl = widget.existing.imageUrl;

  late bool _available = widget.existing.isAvailable;
  late LatLng? _picked =
      (widget.existing.latitude != null && widget.existing.longitude != null)
      ? LatLng(widget.existing.latitude!, widget.existing.longitude!)
      : null;

  late final List<_TierRow> _booking = [
    for (final t in widget.existing.bookingTiers)
      _TierRow(t.durationMinutes, t.price.toStringAsFixed(0)),
  ];

  @override
  void dispose() {
    _price.dispose();
    _courtCount.dispose();
    for (final r in _booking) {
      r.price.dispose();
    }
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      CourtFormResult(
        price: double.tryParse(_price.text.trim()) ?? 0,
        isAvailable: _available,
        courtCount: (int.tryParse(_courtCount.text.trim()) ?? 1).clamp(1, 50),
        imageUrl: (_imageUrl?.isEmpty ?? true) ? null : _imageUrl,
        bookingTiers: _buildTiers(_booking),
        latitude: _picked?.latitude,
        longitude: _picked?.longitude,
      ),
    );
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
          title: Text(context.tr('تعديل الملعب')),
        ),
        body: ListView(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          children: [
            ImageUploadField(
              label: context.tr('صورة الملعب'),
              value: _imageUrl,
              onChanged: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: AppSizes.md),
            _field(_price, context.tr('السعر للساعة'), number: true),
            const SizedBox(height: AppSizes.md),
            _field(_courtCount, context.tr('عدد الملاعب'), number: true),
            const SizedBox(height: AppSizes.md),
            _locationButton(),
            const SizedBox(height: AppSizes.lg),
            _TierEditor(
              title: context.tr('أسعار الحجز (مدة → سعر)'),
              rows: _booking,
              onChanged: () => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('متاح للحجز')),
              activeThumbColor: AppColors.primary,
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(context.tr('حفظ التعديلات')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final result = await Navigator.of(context).push<PickedLocation>(
          MaterialPageRoute(
            builder: (_) => LocationPickerPage(
              initial: _picked,
              title: context.tr('موقع الملعب'),
            ),
          ),
        );
        if (result != null) setState(() => _picked = result.latLng);
      },
      icon: Icon(
        _picked == null ? Icons.add_location_alt_outlined : Icons.location_on,
      ),
      label: Text(
        _picked == null
            ? context.tr('تحديد موقع الملعب على الخريطة')
            : '(${_picked!.latitude.toStringAsFixed(4)}, '
                  '${_picked!.longitude.toStringAsFixed(4)})',
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: context.tr(label),
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
  );

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _dec(label),
    );
  }

  List<CourtTier> _buildTiers(List<_TierRow> rows) {
    final byDuration = <int, CourtTier>{};
    for (final r in rows) {
      final p = double.tryParse(r.price.text.trim());
      if (p == null || p <= 0) continue;
      byDuration[r.duration] = CourtTier(durationMinutes: r.duration, price: p);
    }
    return byDuration.values.toList();
  }
}

/// Duration→price tier editor for court booking prices.
class _TierEditor extends StatelessWidget {
  const _TierEditor({
    required this.title,
    required this.rows,
    required this.onChanged,
  });

  final String title;
  final List<_TierRow> rows;
  final VoidCallback onChanged;

  static const _durations = [30, 60, 90, 120, 150, 180];

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
                context.tr(title),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                rows.add(_TierRow(60, ''));
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
              context.tr('لا توجد شرائح'),
              style: AppTextStyles.caption,
            ),
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<int>(
                    initialValue: rows[i].duration,
                    isDense: true,
                    decoration: InputDecoration(labelText: context.tr('المدة')),
                    items: [
                      for (final d in _durations)
                        DropdownMenuItem(
                          value: d,
                          child: Text(context.trArgs('{p0} د', {'p0': d})),
                        ),
                    ],
                    onChanged: (v) {
                      rows[i].duration = v ?? 60;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  flex: 4,
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
  _TierRow(this.duration, String price)
    : price = TextEditingController(text: price);
  int duration;
  final TextEditingController price;
}
