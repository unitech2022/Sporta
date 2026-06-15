import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Circular avatar that shows an image when available, otherwise the
/// initial letters of [name] on a tinted background.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.backgroundColor = AppColors.primary,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first;
    return parts.first.characters.first + parts[1].characters.first;
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.muted,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: AppTextStyles.bodyMedium.copyWith(
          color: backgroundColor,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
