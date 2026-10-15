import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../cubit/my_events_cubit.dart';

/// العنوان المعروض لأحداث المستخدم المنتهية بحسب النوع.
String finishedEventsTitle(BuildContext context, MyEventsKind kind) =>
    switch (kind) {
      MyEventsKind.match => context.tr('مبارياتي المنتهية'),
      MyEventsKind.americano => context.tr('الأمريكانو المنتهي'),
      MyEventsKind.tournament => context.tr('البطولات المنتهية'),
    };

/// زرّ في أعلى تبويب المباريات/الأمريكانو/البطولات يفتح صفحة ما انتهى أو
/// أُلغي من أحداث المستخدم — هذه لا تظهر في القوائم الحالية. يظهر دائماً
/// للمسجّل حتى لو لم يكن له حدث حالي (قسم «مبارياتي» يختفي حينها).
class FinishedEventsButton extends StatelessWidget {
  const FinishedEventsButton({
    super.key,
    required this.kind,
    required this.onTap,
  });

  final MyEventsKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  finishedEventsTitle(context, kind),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const DirectionalIcon(
                rtl: Icons.chevron_left,
                ltr: Icons.chevron_right,
                size: AppSizes.iconMd,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
