import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/court_entity.dart';
import 'court_detail_shared.dart';
import '../../../../../core/state/app_scope.dart';
import '../../../../../core/localization/tr_global.dart';

/// Address line plus a static map preview; tapping either opens the device's
/// maps app through [onDirections].
class CourtLocationSection extends StatelessWidget {
  const CourtLocationSection({
    super.key,
    required this.court,
    required this.onDirections,
  });

  final CourtEntity court;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final address = [court.neighborhood, court.district, court.city, court.country]
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .join(trg('، '));

    return DetailSectionCard(
      title: context.tr('الموقع'),
      icon: Icons.location_on_outlined,
      action: court.hasLocation
          ? TextButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions_outlined, size: 18),
              label: Text(context.tr('الاتجاهات')),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                visualDensity: VisualDensity.compact,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            Text(
              address,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
            ),
          if (court.distance.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(context.trArgs('يبعد عنك {p0}', {'p0': court.distance}), style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSizes.md),
          if (court.hasLocation) _map() else _noLocation(context),
        ],
      ),
    );
  }

  Widget _map() {
    final point = LatLng(court.latitude!, court.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 14,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sportaapp.sporta_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          size: 40, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            // Tap anywhere on the preview → external maps.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onDirections),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noLocation(BuildContext context) {
    return Container(
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        context.tr('لا يتوفر موقع على الخريطة'),
        style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }
}
