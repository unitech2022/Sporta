import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/state/app_scope.dart';
import '../../../../../core/utils/current_location.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/entities/court_entity.dart';
import '../../pages/court_detail_page.dart';

/// Courts plotted on an OpenStreetMap tile layer as ball pins, centred on the
/// player.
///
/// The centre comes from the player's saved profile location — the same one the
/// API measures each court's "distance" against, so the map and those labels
/// always agree. Without it, the view falls back to framing the courts.
///
/// Courts of one venue share a coordinate, so pins are grouped by position;
/// otherwise they stack invisibly on top of each other.
class CourtsMapView extends StatefulWidget {
  const CourtsMapView({super.key, required this.courts});

  final List<CourtEntity> courts;

  @override
  State<CourtsMapView> createState() => _CourtsMapViewState();
}

class _CourtsMapViewState extends State<CourtsMapView> {
  final _controller = MapController();

  /// Zoom used when centring on the player (زر «موقعي»).
  static const _userZoom = 16.0;

  /// الملاعب ضمن هذه المسافة من اللاعب تُؤطَّر معه عند فتح الخريطة.
  static const _nearbyKm = 30.0;

  /// Zoom limits for the +/- buttons and pinch. OSM serves tiles up to 19.
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;

  /// Dammam — only when neither the player nor any court has a position.
  static const _fallbackCenter = LatLng(26.4207, 50.0888);

  /// The live device position once GPS answers. Until then the profile
  /// location (if any) stands in, so the map isn't empty while we wait.
  LatLng? _deviceLocation;

  LatLng? get _userPoint {
    if (_deviceLocation != null) return _deviceLocation;
    final u = getIt<AuthCubit>().user;
    if (u == null || !u.hasLocation) return null;
    return LatLng(u.latitude!, u.longitude!);
  }

  @override
  void initState() {
    super.initState();
    _locateDevice();
  }

  /// Ask the device for its real position, then recentre on it.
  Future<void> _locateDevice() async {
    final here = await currentDeviceLocation();
    if (!mounted || here == null) return;
    setState(() => _deviceLocation = here);
    _frame();
  }

  /// Step the zoom by [delta], clamped to the tile range, keeping the centre.
  void _zoomBy(double delta) {
    final target = (_controller.camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _controller.move(_controller.camera.center, target);
  }

  List<CourtEntity> get _located =>
      widget.courts.where((c) => c.hasLocation).toList();

  /// Courts keyed by position, so one pin represents one venue.
  Map<LatLng, List<CourtEntity>> get _groups {
    final groups = <String, List<CourtEntity>>{};
    for (final c in _located) {
      groups.putIfAbsent('${c.latitude},${c.longitude}', () => []).add(c);
    }
    return {
      for (final e in groups.entries)
        LatLng(e.value.first.latitude!, e.value.first.longitude!): e.value,
    };
  }

  @override
  void didUpdateWidget(covariant CourtsMapView old) {
    super.didUpdateWidget(old);
    // Re-frame on a filter change only when there is no player location to
    // anchor to — otherwise the map would yank away from where they are.
    if (_userPoint == null && old.courts.length != widget.courts.length) {
      _applyInitialView();
    }
  }

  void _applyInitialView() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _frame());
  }

  /// يؤطّر الخريطة لتظهر الملاعب: مع موقع اللاعب يضمّه إلى الملاعب القريبة
  /// منه (أو أقرب ملعب إن لم يوجد قريب) — كان يقرّب على اللاعب وحده بمستوى
  /// الشارع فتقع الملاعب خارج الشاشة. بلا موقع يؤطّر الملاعب كلها.
  void _frame() {
    if (!mounted) return;
    final user = _userPoint;
    var points = _groups.keys.toList();
    if (user != null) {
      const distance = Distance();
      double km(LatLng p) => distance.as(LengthUnit.Kilometer, user, p);
      var nearby = points.where((p) => km(p) <= _nearbyKm).toList();
      if (nearby.isEmpty && points.isNotEmpty) {
        nearby = [points.reduce((a, b) => km(a) <= km(b) ? a : b)];
      }
      points = [user, ...nearby];
      if (points.length == 1) {
        _controller.move(user, _userZoom);
        return;
      }
    }
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, 13);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(64),
        maxZoom: 15,
      ),
    );
  }

  void _openCourt(String id) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CourtDetailPage(courtId: id)),
      );

  /// Several courts at one venue: let the player pick which one.
  void _pickFromGroup(List<CourtEntity> courts) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Text(
                '${courts.first.areaLabel} · '
                '${courts.length} ${context.tr('ملاعب')}',
                style:
                    AppTextStyles.heading3.copyWith(color: AppColors.secondary),
              ),
            ),
            for (final c in courts)
              ListTile(
                leading:
                    const Icon(Icons.sports_tennis, color: AppColors.primary),
                title: Text(c.name, style: AppTextStyles.body),
                subtitle: Text('${c.totalPrice} ${context.tr('ر.س')}',
                    style: AppTextStyles.caption),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCourt(c.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final user = _userPoint;
    final hidden = widget.courts.length - _located.length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: user ??
                (groups.isEmpty ? _fallbackCenter : groups.keys.first),
            initialZoom: 12,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            onMapReady: _applyInitialView,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sportaapp.sporta_app',
              maxNativeZoom: _maxZoom.toInt(),
            ),
            MarkerLayer(
              markers: [
                // Courts first so the player's dot is never hidden under a pin.
                for (final entry in groups.entries)
                  Marker(
                    point: entry.key,
                    width: 64,
                    height: 62,
                    alignment: Alignment.topCenter,
                    child: _BallPin(
                      courts: entry.value,
                      onTap: () => entry.value.length == 1
                          ? _openCourt(entry.value.first.id)
                          : _pickFromGroup(entry.value),
                    ),
                  ),
                if (user != null)
                  Marker(
                    point: user,
                    width: 26,
                    height: 26,
                    child: const _UserDot(),
                  ),
              ],
            ),
          ],
        ),

        PositionedDirectional(
          top: AppSizes.lg,
          end: AppSizes.lg,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.add,
                onTap: () => _zoomBy(1),
                tooltip: context.tr('تكبير'),
              ),
              const SizedBox(height: AppSizes.sm),
              _MapButton(
                icon: Icons.remove,
                onTap: () => _zoomBy(-1),
                tooltip: context.tr('تصغير'),
              ),
              if (user != null) ...[
                const SizedBox(height: AppSizes.md),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: () => _controller.move(user, _userZoom),
                  tooltip: context.tr('موقعي'),
                ),
              ],
            ],
          ),
        ),

        // Courts without coordinates can't be plotted — say so rather than
        // letting the count silently disagree with the pins.
        PositionedDirectional(
          bottom: AppSizes.lg,
          start: AppSizes.lg,
          end: AppSizes.lg,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                hidden > 0
                    ? '${_located.length} ${context.tr('من')} '
                        '${widget.courts.length} ${context.tr('ملاعب على الخريطة')}'
                    : '${_located.length} ${context.tr('ملاعب في المنطقة')}',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The player's position: the familiar blue dot with a white ring.
class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round white map control (zoom +/-, recenter).
class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Icon(icon,
                color: AppColors.primary, size: AppSizes.iconMd),
          ),
        ),
      ),
    );
  }
}

/// A padel-ball marker with the price underneath. Grouped venues show how many
/// courts sit at that spot.
class _BallPin extends StatelessWidget {
  const _BallPin({required this.courts, required this.onTap});

  final List<CourtEntity> courts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cheapest =
        courts.map((c) => c.totalPrice).reduce((a, b) => a < b ? a : b);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: CourtBallPainter()),
                ),
                if (courts.length > 1)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.rectangle,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text('${courts.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '$cheapest',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Padel ball: yellow-green sphere with the two white seams.
class CourtBallPainter extends CustomPainter {
  const CourtBallPainter();

  static const _ball = Color(0xFFD8F035);
  static const _shade = Color(0xFFA8C520);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final body = Rect.fromCircle(center: c, radius: r);

    // Body, lit from the top-left.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFEAFB7A), _ball],
        ).createShader(body),
    );

    // Seams: two big circles offset left and right, clipped to the ball so they
    // meet its edge exactly instead of poking out of it.
    canvas.save();
    canvas.clipPath(Path()..addOval(body));
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.09)
      ..color = Colors.white;
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(c.translate(side * r * 1.28, 0), r * 0.95, seam);
    }
    canvas.restore();

    // Outline last, so it covers where the seams reach the edge.
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.06)
        ..color = _shade,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
