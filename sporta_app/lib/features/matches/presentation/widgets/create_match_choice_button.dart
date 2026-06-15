import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Selectable bordered pill button used across the create-match form
/// (duration, match type, players count, payment type, invite hours).
///
/// The selected colors default to the primary outline style
/// (border-primary / bg-primary-10 / text-primary) and can be overridden
/// for the green payment variant or the filled invite-hours variant.
class CreateMatchChoiceButton extends StatelessWidget {
  const CreateMatchChoiceButton({
    super.key,
    required this.label,
    this.subLabel,
    required this.selected,
    required this.onTap,
    this.selectedBorderColor = AppColors.primary,
    this.selectedBackground,
    this.selectedForeground = AppColors.primary,
    this.padding =
        const EdgeInsetsDirectional.symmetric(vertical: AppSizes.md),
  });

  final String label;
  final String? subLabel;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBorderColor;

  /// Defaults to primary at 10% opacity when null.
  final Color? selectedBackground;
  final Color selectedForeground;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? (selectedBackground ?? AppColors.primary.withValues(alpha: 0.1))
        : AppColors.card;
    final borderColor = selected ? selectedBorderColor : AppColors.border;
    final foreground = selected ? selectedForeground : AppColors.secondary;
    final borderRadius = BorderRadius.circular(AppSizes.radiusLg);

    final labelStyle = subLabel == null
        ? AppTextStyles.body.copyWith(color: foreground)
        : AppTextStyles.bodySmall
            .copyWith(color: foreground, fontWeight: FontWeight.w500);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: labelStyle, textAlign: TextAlign.center),
              if (subLabel != null) ...[
                SizedBox(height: 2),
                Text(
                  subLabel!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
