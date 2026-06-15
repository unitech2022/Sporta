import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'create_match_field_label.dart';

/// Labeled tappable field that opens a date/time picker. Mirrors the
/// native `input type="date|time"` boxes of the web form.
class CreateMatchPickerField extends StatelessWidget {
  const CreateMatchPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(text: label, icon: icon),
        SizedBox(height: AppSizes.sm),
        Material(
          color: AppColors.inputBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              child: Text(
                hasValue ? value : hint,
                style: AppTextStyles.body.copyWith(
                  color: hasValue
                      ? AppColors.secondary
                      : AppColors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
