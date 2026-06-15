import 'package:flutter/material.dart';

/// Design tokens extracted from the Sporta design system (theme.css).
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF2AB5CE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF0A2540);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color brandGold = Color(0xFFF0C040);

  // Surfaces
  static const Color background = Color(0xFFF8F9FA);
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFE8EEF2);
  static const Color mutedForeground = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color switchBackground = Color(0xFFD1D5DB);

  // Feedback
  static const Color destructive = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  /// Navy gradient used on page headers (from-secondary to-secondary/90).
  static const LinearGradient headerGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [secondary, Color(0xE60A2540)],
  );

  /// Cyan gradient used on primary call-to-action surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [primary, Color(0xFF1E9AB0)],
  );
}
