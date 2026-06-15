import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Circular avatar filled with a diagonal gradient and short initials,
/// mirroring the TSX `bg-gradient-to-br` avatar circles.
class MatchResultGradientAvatar extends StatelessWidget {
  const MatchResultGradientAvatar({
    super.key,
    required this.text,
    required this.gradient,
    this.size = 36,
    this.borderColor,
    this.borderWidth = 0,
    this.fontSize,
  });

  final String text;
  final List<Color> gradient;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: gradient,
        ),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppColors.card, width: borderWidth)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? size * 0.3,
          height: 1,
        ),
      ),
    );
  }
}

/// Overlapping row of avatars (TSX `-space-x-*`).
class MatchResultAvatarStack extends StatelessWidget {
  const MatchResultAvatarStack({
    super.key,
    required this.avatars,
    required this.size,
    this.overlap = 8,
  });

  final List<Widget> avatars;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final width = avatars.isEmpty
        ? 0.0
        : size + (avatars.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            PositionedDirectional(
              start: i * (size - overlap),
              child: avatars[i],
            ),
        ],
      ),
    );
  }
}
