import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTextStyles {
  static String get brandFontFamily => GoogleFonts.ibmPlexSansArabic().fontFamily!;

  static TextStyle get heading1 => GoogleFonts.ibmPlexSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get heading2 => GoogleFonts.ibmPlexSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get heading3 => GoogleFonts.ibmPlexSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get body => GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get bodySmall => GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.mutedForeground,
      );

  static TextStyle get label => GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.foreground,
      );

  static TextStyle get button => GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );
}
