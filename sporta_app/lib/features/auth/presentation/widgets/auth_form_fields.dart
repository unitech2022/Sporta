import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Labeled text field styled for the gradient auth screens (white fill on a
/// translucent panel). Shared across the forgot-password / reset flows.
class AuthWhiteInput extends StatelessWidget {
  const AuthWhiteInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.icon,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? icon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            prefixIcon: icon == null
                ? null
                : Icon(icon,
                    size: AppSizes.iconMd, color: AppColors.mutedForeground),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Inline error banner shown inside the auth glass panels.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.destructive),
      ),
    );
  }
}
