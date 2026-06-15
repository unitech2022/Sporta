import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'create_match_field_label.dart';

/// Value/label pair for a [CreateMatchSelectField] option.
class CreateMatchSelectOption {
  const CreateMatchSelectOption(this.value, this.label);

  final String value;
  final String label;
}

/// White rounded input decoration matching the web form fields
/// (border, rounded-xl, focus ring in primary).
InputDecoration createMatchInputDecoration({String? hint}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSizes.lg,
      vertical: AppSizes.md,
    ),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary),
  );
}

/// Labeled dropdown used for the court and the min/max level selectors.
/// [dense] renders the smaller muted label used inside the level grid.
class CreateMatchSelectField extends StatelessWidget {
  const CreateMatchSelectField({
    super.key,
    required this.label,
    this.icon,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final String hint;
  final List<CreateMatchSelectOption> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dense)
          Text(label, style: AppTextStyles.caption)
        else
          CreateMatchFieldLabel(text: label, icon: icon),
        SizedBox(height: dense ? AppSizes.xs : AppSizes.sm),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.mutedForeground,
          ),
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          decoration: createMatchInputDecoration(),
          hint: Text(
            hint,
            style:
                AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
            overflow: TextOverflow.ellipsis,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}
