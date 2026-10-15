import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';

/// Full-screen block shown when the admin has enabled `in_maintenance` in
/// system settings.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: context.safeBottom(const EdgeInsets.all(AppSizes.xxl)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      size: 52,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    context.tr('التطبيق تحت الصيانة'),
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr(
                      context.tr(
                        'نعمل حاليًا على تحسين التطبيق. الرجاء المحاولة بعد قليل.',
                      ),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
