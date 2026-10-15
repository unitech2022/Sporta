import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTextStyles {
  // سُلَّم الأحجام: نص 14، ثانوي 13، توضيحي 11.5، عناوين 16/18/20.
  static String get brandFontFamily => GoogleFonts.ibmPlexSansArabic().fontFamily!;

  /// خط التطبيق لا يحوي الإيموجي فكانت تظهر مربّعاً بعلامة استفهام (أعلام
  /// اللغة، تفاعلات الدردشة، إيموجي داخل الرسائل) — نُحيلها لخط النظام.
  static const List<String> emojiFallback = [
    'Apple Color Emoji',
    'Noto Color Emoji',
    'Segoe UI Emoji',
  ];

  static TextStyle _ibm({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      ).copyWith(fontFamilyFallback: emojiFallback);

  static TextStyle get heading1 => _ibm(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get heading2 => _ibm(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get heading3 => _ibm(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get body => _ibm(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get bodyMedium => _ibm(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get bodySmall => _ibm(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get caption => _ibm(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.mutedForeground,
      );

  static TextStyle get label => _ibm(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get button => _ibm(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );
}
