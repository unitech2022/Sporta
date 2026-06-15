import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Circular gradient avatar showing player initials or a level number,
/// mirroring the `bg-gradient-to-br ... rounded-full` avatars of the TSX.
class MatchesPlayerAvatar extends StatelessWidget {
  const MatchesPlayerAvatar({
    super.key,
    this.label,
    this.icon,
    this.iconColor,
    this.gradient,
    this.color,
    this.size = 40,
    this.fontSize = 14,
    this.borderColor,
    this.borderWidth = 2,
    this.dashed = false,
    this.dashColor = AppColors.primary,
  });

  /// Text shown inside the avatar (initials or level).
  final String? label;

  /// Icon shown instead of [label] (e.g. the empty-slot Users icon).
  final IconData? icon;
  final Color? iconColor;

  /// Two-stop background gradient (top-start to bottom-end).
  final List<Color>? gradient;

  /// Solid background color when no [gradient] is given.
  final Color? color;

  final double size;
  final double fontSize;
  final Color? borderColor;
  final double borderWidth;

  /// Draws a dashed circular border instead of a filled background
  /// (the "needs players" placeholder slot).
  final bool dashed;
  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: icon != null
          ? Icon(
              icon,
              size: size * 0.5,
              color: iconColor ?? (dashed ? dashColor : Colors.white),
            )
          : Text(
              label ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1,
              ),
            ),
    );

    if (dashed) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedCirclePainter(dashColor, borderWidth),
          child: content,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? color : null,
        gradient: gradient == null
            ? null
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: gradient!,
              ),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: content,
    );
  }
}

/// Horizontally overlapping avatars (the `-space-x-2` stacks).
class MatchesAvatarStack extends StatelessWidget {
  const MatchesAvatarStack({
    super.key,
    required this.children,
    this.size = 40,
    this.overlap = 8,
  });

  final List<Widget> children;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final width = size + (children.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < children.length; i++)
            PositionedDirectional(
              start: i * (size - overlap),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    const dashCount = 12;
    const sweep = 2 * math.pi / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
