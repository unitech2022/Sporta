import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Numeric score box used across all result-entry flows.
/// Border / fill / text colors are driven by the parent so the box can
/// highlight the winning side, mirroring the TSX inputs.
class MatchResultScoreInput extends StatelessWidget {
  const MatchResultScoreInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.focusBorderColor,
    this.borderColor,
    this.fillColor,
    this.textColor,
    this.large = true,
    this.maxLength = 3,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Color focusBorderColor;
  final Color? borderColor;
  final Color? fillColor;
  final Color? textColor;
  final bool large;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      large ? AppSizes.radiusLg : AppSizes.radiusMd,
    );
    return TextFormField(
      initialValue: value,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: TextStyle(
        fontSize: large ? 30 : 20,
        color: textColor ?? AppColors.secondary,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          fontSize: large ? 30 : 20,
          color: AppColors.mutedForeground.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: fillColor ?? AppColors.card,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: large ? AppSizes.md : AppSizes.sm,
          horizontal: AppSizes.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: borderColor ?? AppColors.border,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: focusBorderColor, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
