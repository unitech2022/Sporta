import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../settings/data/settings_repository.dart';
import '../../domain/entities/withdrawal.dart';

/// أي حدث ينسحب منه اللاعب — يحدد المهلة والعبارات.
enum WithdrawalEventKind { match, americano, tournament }

extension on WithdrawalEventKind {
  /// مهلة الانسحاب الحرّ بالساعات (تطابق الخادم: WithdrawalPolicy).
  int get hours => this == WithdrawalEventKind.match ? 24 : 48;

  String label(BuildContext context) => switch (this) {
    WithdrawalEventKind.match => context.tr('المباراة'),
    WithdrawalEventKind.americano => context.tr('الأمريكانو'),
    WithdrawalEventKind.tournament => context.tr('البطولة'),
  };
}

/// يؤكد الانسحاب قبل إرساله، ويشرح ما سيحدث بالضبط: انسحاب مباشر قبل
/// المهلة، أو طلب ينتظر المنشئ بعدها — مع الحصة التي تُعاد ونقاط الخصم.
/// يعيد true عند التأكيد.
Future<bool> confirmWithdrawal(
  BuildContext context, {
  required WithdrawalEventKind kind,
  required bool direct,
  required double refund,
}) async {
  final penalty = await getIt<SettingsRepository>().withdrawalPenaltyPoints();
  if (!context.mounted) return false;
  final label = kind.label(context);
  final refundLine = refund > 0
      ? context.trArgs('تُعاد حصتك ({p0} ر.س) إلى محفظتك.', {
          'p0': money(refund),
        })
      : null;
  final penaltyLine = penalty > 0
      ? context.trArgs('تُخصم {p0} نقطة من نقاط مكافآتك.', {'p0': penalty})
      : null;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        direct
            ? dialogContext.trArgs('الانسحاب من {p0}', {'p0': label})
            : dialogContext.tr('طلب انسحاب'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!direct) ...[
            _NoticeBox(
              text: dialogContext.trArgs(
                'بقي أقل من {p0} ساعة على الموعد، فالانسحاب الآن طلب يحتاج موافقة المنظّم. تبقى مشاركاً حتى يوافق.',
                {'p0': kind.hours},
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          Text(
            direct
                ? dialogContext.trArgs('ستخرج من {p0} ويُفتح مقعدك لغيرك.', {
                    'p0': label,
                  })
                : dialogContext.tr('إن وافق المنظّم:'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          for (final line in [refundLine, penaltyLine].whereType<String>()) ...[
            const SizedBox(height: AppSizes.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.tr('تراجع')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
          child: Text(
            direct
                ? dialogContext.tr('تأكيد الانسحاب')
                : dialogContext.tr('إرسال الطلب'),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

/// رسالة نتيجة الانسحاب بعد نجاحه.
String withdrawalOutcomeMessage(
  BuildContext context,
  WithdrawalOutcome outcome,
  WithdrawalEventKind kind,
) {
  final label = kind.label(context);
  return switch (outcome) {
    WithdrawalOutcome.withdrawn => context.trArgs(
      'انسحبت من {p0} وأُعيدت حصتك إلى محفظتك',
      {'p0': label},
    ),
    WithdrawalOutcome.requested => context.tr(
      'أُرسل طلب انسحابك — بانتظار موافقة المنظّم',
    ),
    WithdrawalOutcome.requestCancelled => context.tr(
      'أُلغي طلب انضمامك وأُعيدت حصتك',
    ),
  };
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.schedule,
          size: AppSizes.iconSm,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    ),
  );
}

/// شريط العضو أسفل صفحة الحدث: «أنت مشارك» مع زر الانسحاب، أو حالة طلب
/// الانسحاب المعلّق. [onWithdraw] null = لا يملك الانسحاب الآن.
class MemberWithdrawBar extends StatelessWidget {
  const MemberWithdrawBar({
    super.key,
    required this.memberLabel,
    required this.withdrawalRequested,
    required this.direct,
    required this.busy,
    this.onWithdraw,
  });

  final String memberLabel;
  final bool withdrawalRequested;

  /// الانسحاب الآن مباشر (قبل المهلة)؛ وإلا يصير طلباً.
  final bool direct;
  final bool busy;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    if (withdrawalRequested) {
      return _StatusRow(
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        text: context.tr('طلب انسحابك بانتظار موافقة المنظّم'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _StatusRow(
            icon: Icons.check_circle,
            color: AppColors.success,
            text: memberLabel,
          ),
        ),
        if (onWithdraw != null) ...[
          const SizedBox(width: AppSizes.sm),
          OutlinedButton.icon(
            onPressed: busy ? null : onWithdraw,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              direct ? context.tr('انسحاب') : context.tr('طلب انسحاب'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.md,
      vertical: AppSizes.sm + 2,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: color),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// طلب انسحاب واحد أمام المنظّم.
class WithdrawalRequestItem {
  const WithdrawalRequestItem({
    required this.userId,
    required this.name,
    this.subtitle,
  });

  final int userId;
  final String name;
  final String? subtitle;
}

/// طلبات الانسحاب المتأخرة أمام المنظّم: كل طلب بزرّي قبول/رفض. القبول يفتح
/// المقعد ويردّ حصة اللاعب، والرفض يبقيه مشاركاً.
class WithdrawalRequestsCard extends StatelessWidget {
  const WithdrawalRequestsCard({
    super.key,
    required this.requests,
    required this.busy,
    required this.onRespond,
  });

  final List<WithdrawalRequestItem> requests;
  final bool busy;
  final void Function(WithdrawalRequestItem request, bool approve) onRespond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: AppSizes.iconSm,
                color: AppColors.destructive,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                context.trArgs('طلبات الانسحاب ({p0})', {
                  'p0': requests.length,
                }),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            context.tr(
              'القبول يفتح المقعد ويُعيد للاعب حصته، والرفض يبقيه مشاركاً.',
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          for (final r in requests)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        if (r.subtitle != null)
                          Text(
                            r.subtitle!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('رفض'),
                    onPressed: busy ? null : () => onRespond(r, false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.destructive,
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('قبول'),
                    onPressed: busy ? null : () => onRespond(r, true),
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
