import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/current_location.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/nominatim_service.dart';
import '../../../../core/service_zone/service_zone_service.dart';
import '../../../../core/state/app_scope.dart';

/// Result returned by [LocationPickerPage]: the picked point plus whatever
/// address Nominatim resolved for it (may be null if reverse geocoding
/// failed or never completed — callers should fall back to [latLng]).
class PickedLocation {
  const PickedLocation({
    required this.latLng,
    this.displayAddress,
    this.city,
    this.district,
  });

  final LatLng latLng;
  final String? displayAddress;
  final String? city;
  final String? district;
}

/// Full-screen map where the user pans the map under a fixed center pin (or
/// searches for an address) to choose a location. The resolved address is
/// shown live and returned alongside the coordinates via [Navigator.pop].
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial, this.title});

  final LatLng? initial;
  final String? title;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  final _nominatim = NominatimService();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  // Default center: Eastern Province, Saudi Arabia.
  static const _fallback = LatLng(26.4207, 50.0888);

  late LatLng _center = widget.initial ?? _fallback;

  ResolvedAddress? _resolved;
  bool _resolving = false;
  Timer? _reverseDebounce;

  List<GeocodeResult> _searchResults = [];
  bool _searching = false;
  Timer? _searchDebounce;

  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
    // Open on the user's current location when no explicit start was given.
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _useMyLocation(silent: true),
      );
    }
  }

  /// Gets the device's current GPS position (asking for permission if needed)
  /// and recenters the map on it. When [silent] it stays quiet on failure
  /// (used for the initial auto-locate).
  Future<void> _useMyLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final target = await currentDeviceLocation();
      if (target == null) {
        if (!silent && mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'تعذّر تحديد موقعك. تأكد من تفعيل الموقع والصلاحيات.',
                ),
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      _mapController.move(target, 15);
      setState(() => _center = target);
      _reverseDebounce?.cancel();
      _reverseGeocode();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onMapMoved(LatLng center) {
    setState(() => _center = center);
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(
      const Duration(milliseconds: 700),
      _reverseGeocode,
    );
  }

  Future<void> _reverseGeocode() async {
    setState(() => _resolving = true);
    unawaited(_checkServiceZone(_center));
    final result = await _nominatim.reverse(
      _center.latitude,
      _center.longitude,
    );
    if (!mounted) return;
    setState(() {
      _resolved = result;
      _resolving = false;
    });
  }

  /// نطاق الخدمة للنقطة المختارة — تنبيه فقط، لا يمنع التأكيد.
  ServiceZoneCheck? _zoneCheck;

  Future<void> _checkServiceZone(LatLng point) async {
    final check = await ServiceZoneService.instance.probe(
      point.latitude,
      point.longitude,
    );
    // تجاهل نتيجة نقطة قديمة إن تحرّكت الخريطة بعدها.
    if (!mounted || point != _center) return;
    setState(() => _zoneCheck = check);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _searching = true);
      final results = await _nominatim.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  void _selectSearchResult(GeocodeResult result) {
    final target = LatLng(result.latitude, result.longitude);
    _mapController.move(target, _mapController.camera.zoom);
    _searchFocus.unfocus();
    setState(() {
      _center = target;
      _searchResults = [];
      _searchCtrl.text = result.displayName;
    });
    _reverseDebounce?.cancel();
    _reverseGeocode();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? context.tr('اختر موقع النادي')),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) _onMapMoved(camera.center);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sportaapp.sporta_app',
                ),
              ],
            ),
            // Fixed center pin (offset up so its tip marks the center).
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            // Search bar + results dropdown.
            PositionedDirectional(
              top: AppSizes.lg,
              start: AppSizes.lg,
              end: AppSizes.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    loading: _searching,
                    onChanged: _onSearchChanged,
                  ),
                  if (_searchResults.isNotEmpty)
                    _SearchResultsList(
                      results: _searchResults,
                      onSelect: _selectSearchResult,
                    ),
                ],
              ),
            ),
            // "Use my location" button, sitting just above the address pill.
            PositionedDirectional(
              bottom: 76,
              end: AppSizes.lg,
              child: FloatingActionButton.small(
                heroTag: 'useMyLocation',
                onPressed: _locating ? null : () => _useMyLocation(),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                child: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
            // Resolved-address readout.
            PositionedDirectional(
              bottom: AppSizes.lg,
              start: AppSizes.lg,
              end: AppSizes.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_zoneCheck?.isOutside == true) ...[
                    _OutsideZoneNotice(message: _zoneCheck!.message),
                    const SizedBox(height: AppSizes.sm),
                  ],
                  _AddressPill(
                    resolving: _resolving,
                    resolved: _resolved,
                    center: _center,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  PickedLocation(
                    latLng: _center,
                    displayAddress: _resolved?.displayName,
                    city: _resolved?.city,
                    district: _resolved?.district,
                  ),
                ),
                icon: const Icon(Icons.check),
                label: Text(context.tr('تأكيد الموقع')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: context.tr('ابحث عن عنوان...'),
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.mutedForeground,
          ),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.mutedForeground,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results, required this.onSelect});

  final List<GeocodeResult> results;
  final ValueChanged<GeocodeResult> onSelect;

  @override
  Widget build(BuildContext context) {
    // اللون والظل يأتيان من Material نفسه لا من Container ملوّن، وإلا حجب
    // خلفية ListTile وتموّج اللمس (تحذير Flutter عن ink splashes).
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.sm),
      constraints: const BoxConstraints(maxHeight: 240),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = results[index];
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                r.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              onTap: () => onSelect(r),
            );
          },
        ),
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.resolving,
    required this.resolved,
    required this.center,
  });

  final bool resolving;
  final ResolvedAddress? resolved;
  final LatLng center;

  @override
  Widget build(BuildContext context) {
    final coords =
        '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            size: AppSizes.iconSm,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: resolving
                ? Text(
                    context.tr('جارٍ تحديد العنوان...'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  )
                : Text(
                    resolved?.displayName ?? coords,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// تنبيه أن النقطة المختارة خارج مناطق خدمة التطبيق المفعّلة.
class _OutsideZoneNotice extends StatelessWidget {
  const _OutsideZoneNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Colors.white,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
