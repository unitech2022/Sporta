import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/americano_entity.dart';

/// طلبات الانضمام أمام المنظّم (أمريكانو أو بطولة): كل طلب بزرّي قبول/رفض.
/// لا يدخل أحد الحدث إلا بموافقته، والحصة محجوزة حتى يبتّ فيها.
class JoinRequestsCard extends StatelessWidget {
  const JoinRequestsCard({
    super.key,
    required this.requests,
    required this.busy,
    required this.onRespond,
    this.teamLabel,
  });

  final List<AmericanoPlayer> requests;
  final bool busy;
  final void Function(AmericanoPlayer player, bool approve) onRespond;

  /// اسم فريق الطالب (في أمريكانو الفرق والبطولة)؛ null في الفردي.
  final String Function(int team)? teamLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_outlined,
                size: AppSizes.iconSm,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                context.trArgs('طلبات الانضمام ({p0})', {
                  'p0': requests.length,
                }),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          for (final p in requests)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        if (p.team != null && teamLabel != null)
                          Text(
                            teamLabel!(p.team!),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('رفض'),
                    onPressed: busy ? null : () => onRespond(p, false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.destructive,
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('قبول'),
                    onPressed: busy ? null : () => onRespond(p, true),
                    icon: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
