import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';

/// عنوان قسم في قائمة المباريات («مبارياتي» / «مباريات أخرى») مع زر
/// «عرض الكل» اختياري يفتح الصفحة المقسّمة بكل ما يخصّ المستخدم.
class MineSectionHeader extends StatelessWidget {
  const MineSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.tr('عرض الكل'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
