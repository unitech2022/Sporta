import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/court_entity.dart';

/// Stylized "map" placeholder showing pulsing price pins for the filtered
/// courts. The pulse animation is purely presentational, so it lives here.
class CourtsMapView extends StatefulWidget {
  const CourtsMapView({super.key, required this.courts});

  final List<CourtEntity> courts;

  @override
  State<CourtsMapView> createState() => _CourtsMapViewState();
}

class _CourtsMapViewState extends State<CourtsMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(size: Size.infinite, painter: _GridPainter()),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 280,
                height: 200,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: _buildPins(),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${widget.courts.length} ملاعب في المنطقة',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPins() {
    const positions = [
      Offset(40, 80),
      Offset(140, 30),
      Offset(220, 100),
      Offset(80, 150),
      Offset(180, 160),
    ];
    final count = math.min(widget.courts.length, positions.length);
    return List.generate(count, (i) {
      final scale = i.isEven ? _pulseAnim.value : (1.6 - _pulseAnim.value);
      return Positioned(
        left: positions[i].dx,
        top: positions[i].dy,
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.courts[i].basePrice} ر.س',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(10, 6),
                painter: _PinTailPainter(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
