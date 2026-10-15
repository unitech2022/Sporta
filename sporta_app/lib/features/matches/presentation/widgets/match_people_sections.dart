import '../../../../core/widgets/level_avatar.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/match_entity.dart';

/// الأعضاء المعتمدون في المباراة (تبويب «المشاركون» للمنشئ، أو قسم في
/// صفحة اللاعب).
class MatchMembersSection extends StatelessWidget {
  const MatchMembersSection({
    super.key,
    required this.players,
    required this.creatorId,
    this.showPayment = true,
  });

  final List<MatchPlayerEntity> players;
  final int creatorId;

  /// مباراة مجانية (بلا حصة) لا معنى فيها لـ«دفع / لم يدفع».
  final bool showPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('الأعضاء المشتركون')} (${players.length})',
          style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        if (players.isEmpty)
          Text(
            context.tr('لا يوجد أعضاء بعد'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          )
        else
          for (final p in players) ...[
            _PersonTile(
              player: p,
              trailing: p.userId == creatorId
                  ? _Tag(context.tr('المنشئ'), AppColors.primary)
                  : null,
              paymentLabel: showPayment ? _paymentLabel(context, p) : null,
            ),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

Widget _paymentLabel(BuildContext context, MatchPlayerEntity p) => _PaidBadge(
  paid: p.hasPaid,
  text: p.hasPaid ? context.tr('دفع') : context.tr('لم يدفع'),
);

/// المدعوون الذين لم يردّوا بعد: لا حصة عليهم ولم يدفعوا حتى يقبلوا.
class MatchInvitedSection extends StatelessWidget {
  const MatchInvitedSection({
    super.key,
    required this.invited,
    this.showPayment = true,
  });

  final List<MatchPlayerEntity> invited;
  final bool showPayment;

  @override
  Widget build(BuildContext context) {
    if (invited.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('مدعوون بانتظار الرد')} (${invited.length})',
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.md),
          for (final p in invited) ...[
            _PersonTile(
              player: p,
              pending: true,
              paymentLabel: showPayment ? _paymentLabel(context, p) : null,
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ],
      ),
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({required this.paid, required this.text});

  final bool paid;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.destructive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          paid ? Icons.check_circle : Icons.schedule,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// طلبات الانضمام المعلّقة أمام المنشئ: كل طلب بزرّي قبول/رفض. الحصة محجوزة
/// حتى يبتّ فيها، وتُعاد للطالب عند الرفض.
class MatchRequestsSection extends StatelessWidget {
  const MatchRequestsSection({
    super.key,
    required this.requests,
    required this.busyUserId,
    required this.onRespond,
  });

  final List<MatchPlayerEntity> requests;

  /// الطلب الذي يُبتّ فيه الآن (يعرض مؤشراً بدل الزرّين).
  final int? busyUserId;
  final void Function(MatchPlayerEntity request, bool approve) onRespond;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('طلبات الانضمام')} (${requests.length})',
          style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        if (requests.isEmpty)
          Text(
            context.tr('لا توجد طلبات انضمام'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          )
        else
          for (final r in requests) ...[
            _PersonTile(
              player: r,
              pending: true,
              trailing: busyUserId == r.userId
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconAction(
                          Icons.check,
                          AppColors.success,
                          () => onRespond(r, true),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _IconAction(
                          Icons.close,
                          AppColors.destructive,
                          () => onRespond(r, false),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

/// صفّ لاعب: صورته أو أحرفه الأولى، اسمه ومستواه، وما يُلحق به في الطرف.
/// الطلب المعلّق بلون تحذيري ليتميّز عن العضو المعتمد.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.player,
    this.trailing,
    this.pending = false,
    this.paymentLabel,
  });

  final MatchPlayerEntity player;
  final Widget? trailing;

  /// حالة الدفع تحت اسم اللاعب (دفع / لم يدفع).
  final Widget? paymentLabel;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: pending
            ? AppColors.warning.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: pending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          LevelAvatar(
            name: p.name,
            imageUrl: p.avatarUrl,
            level: p.level,
            radius: 20,
            fallbackColor: pending ? const Color(0xFFB45309) : null,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // الرقم في دائرة أسفل الصورة؛ هنا اسم المستوى بلونه.
                if (p.level != null)
                  Text(
                    PlayerLevelStyle.name(p.level!),
                    style: AppTextStyles.caption.copyWith(
                      color: PlayerLevelStyle.color(p.level!),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (paymentLabel != null) ...[
                  const SizedBox(height: 2),
                  paymentLabel!,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.md,
      vertical: AppSizes.sm,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _IconAction extends StatelessWidget {
  const _IconAction(this.icon, this.color, this.onTap);

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: 0.12),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Icon(icon, color: color, size: AppSizes.iconMd),
      ),
    ),
  );
}
