import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/pending_result.dart';

/// نتيجة مقترحة بانتظار التأكيد: من أدخلها وما أدخله، ثم زرّا التأكيد/الرفض
/// للاعب من الفريق الآخر، أو «بانتظار تأكيد الفريق الآخر» لفريق المقترِح.
class PendingResultBanner extends StatelessWidget {
  const PendingResultBanner({
    super.key,
    required this.pending,
    required this.team1Label,
    required this.team2Label,
    required this.canRespond,
    required this.busy,
    required this.onRespond,
    this.currentUserId = 0,
  });

  final PendingResult pending;
  final String team1Label;
  final String team2Label;

  /// المستخدم لاعب في الفريق المقابل للمقترِح.
  final bool canRespond;
  final bool busy;
  final void Function(bool accept) onRespond;
  final int currentUserId;

  @override
  Widget build(BuildContext context) {
    final mine = pending.proposedById == currentUserId;
    final who = mine ? context.tr('أنت') : pending.proposedByName;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: AppSizes.iconSm,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  context.trArgs('نتيجة أدخلها {p0} — بانتظار التأكيد', {
                    'p0': who,
                  }),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _scoreLine(team1Label, pending.team1Score),
          const SizedBox(height: 2),
          _scoreLine(team2Label, pending.team2Score),
          const SizedBox(height: AppSizes.sm),
          if (canRespond)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => onRespond(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: const BorderSide(color: AppColors.destructive),
                    ),
                    child: Text(context.tr('رفض')),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => onRespond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.tr('تأكيد النتيجة')),
                  ),
                ),
              ],
            )
          else
            Text(
              context.tr('بانتظار تأكيد لاعب من الفريق الآخر'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreLine(String label, int score) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
      ),
      Text(
        '$score',
        style: AppTextStyles.body.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
