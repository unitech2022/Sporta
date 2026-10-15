import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/venue_match_request.dart';
import '../match_request_format.dart';

/// بطاقة حدث واحد على ملاعب المالك. النوع (مباراة/أمريكانو/بطولة) يحدّده
/// التبويب النشط، فلا تكرّره البطاقة؛ تُظهر فقط ما يحتاجه المالك ليقرّر:
/// الحالة، الموعد، المسجّلون، وأزرار القبول/الرفض أو الإلغاء.
class VenueMatchRequestCard extends StatelessWidget {
  const VenueMatchRequestCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onCancelHosted,
  });

  final VenueMatchRequest request;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancelHosted;

  bool get _isPending => request.status == 'PendingApproval';

  /// حدث من استضافة الملعب ولم ينتهِ بعد — يمكن إلغاؤه وردّ الحصص.
  bool get _canCancelHosted =>
      request.isVenueHosted &&
      request.status != 'Cancelled' &&
      request.status != 'Completed';

  @override
  Widget build(BuildContext context) {
    final m = request;
    final statusColor = matchStatusColor(m.status);
    final hasTitle = m.title != null && m.title!.isNotEmpty;
    final place = '${m.courtName} • ${m.venueName}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTitle ? m.title! : place,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasTitle)
                        Text(
                          place,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      // المنشئ يهمّ عند طلب لاعب؛ في حدثك أنت المنشئ.
                      if (!m.isVenueHosted)
                        Text(
                          '${context.tr('المنشئ')}: ${m.creatorName}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Pill(
                      label: context.tr(matchStatusLabelAr(m.status)),
                      color: statusColor,
                    ),
                    if (m.isVenueHosted) ...[
                      const SizedBox(height: AppSizes.xs),
                      _Pill(
                        label: context.tr('من إنشائك'),
                        color: AppColors.brandGold,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            _InfoLine(
              icon: Icons.access_time,
              text: context.trArgs('{p0} · {p1} د', {
                'p0': formatMatchWhen(m.scheduledAt),
                'p1': m.durationMinutes,
              }),
            ),
            const SizedBox(height: AppSizes.xs),
            _InfoLine(
              icon: Icons.people_outline,
              text: m.isVenueHosted
                  ? '${m.registeredPlayers}/${m.maxPlayers} ${context.tr('مسجّلين')} · '
                        '${context.tr('الحصة')} ${money(m.pricePerPlayer)} ${context.tr('ر.س')}'
                  : '${m.maxPlayers} ${context.tr('لاعبين')} · '
                        '${context.tr('الحصة')} ${money(m.pricePerPlayer)} ${context.tr('ر.س')}',
            ),
            // المبلغ المحجوز وطريقة الدفع يهمّان فقط عند طلب ينتظر قرارك.
            if (_isPending) ...[
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Icon(
                    m.isFullPayment
                        ? Icons.payments_outlined
                        : Icons.call_split,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      m.paymentLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  Text(
                    '${context.tr('محجوز')} ${money(m.amountHeld)} ${context.tr('ر.س')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            if (_isPending || _canCancelHosted) ...[
              const SizedBox(height: AppSizes.md),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else if (_isPending)
                _ApproveRejectRow(onApprove: onApprove, onReject: onReject)
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCancelHosted,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(context.tr('إلغاء الحدث')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: const BorderSide(color: AppColors.destructive),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.xs),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _ApproveRejectRow extends StatelessWidget {
  const _ApproveRejectRow({required this.onApprove, required this.onReject});

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.tr('قبول')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 18),
            label: Text(context.tr('رفض')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
            ),
          ),
        ),
      ],
    );
  }
}
