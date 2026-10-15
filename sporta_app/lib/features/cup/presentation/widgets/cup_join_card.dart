import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/cup_entity.dart';

/// طريقة الانضمام التي اختارها اللاعب.
enum CupJoinMode { solo, withPartner }

/// بطاقة الانضمام في أعلى صفحة البطولة: تشرح كيف يسجّل اللاعب — والنظام
/// يضعه تلقائياً في أول مقعد شاغر؛ الأزرار في [CupJoinActions] الثابت أسفلها. تُخفى لمن هو مشارك أو
/// مدعوّ أو للمنظّم المستضيف، وتعرض حالته إن كان طلبه ينتظر الموافقة.
class CupJoinCard extends StatelessWidget {
  const CupJoinCard({
    super.key,
    required this.cup,
    required this.currentUserId,
  });

  final CupEntity cup;
  final int currentUserId;

  /// هل تظهر البطاقة لهذا المستخدم أصلاً.
  static bool visibleFor(CupEntity cup, int userId) {
    final hostOrganizer = cup.isVenueHosted && cup.creatorId == userId;
    final involved = cup.players.any((p) => p.userId == userId);
    // الملغاة تُعرض لغير المشارك كتنبيه «لا يمكن الانضمام» بدل الزر.
    if (cup.isCancelled) return !hostOrganizer && !involved;
    if (hostOrganizer || cup.isDrawn || cup.isCompleted) return false;
    // من طلبه ينتظر الموافقة يرى حالته هنا؛ المشارك والمدعوّ لهما ما يخصّهما.
    if (involved) return cup.hasPendingRequest(userId);
    return cup.isOpen || cup.isPendingApproval;
  }

  @override
  Widget build(BuildContext context) {
    if (cup.isCancelled) {
      return _shell(
        context,
        icon: Icons.cancel_outlined,
        color: AppColors.destructive,
        title: context.tr('أُلغيت البطولة — لا يمكن الانضمام إليها'),
        body: null,
      );
    }
    if (cup.hasPendingRequest(currentUserId)) {
      return _shell(
        context,
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        title: context.tr('طلب انضمامك بانتظار موافقة المنظّم'),
        body: context.tr('حصتك محجوزة، وتُعاد إلى محفظتك إن رُفض الطلب.'),
      );
    }
    if (cup.isPendingApproval) {
      return _shell(
        context,
        icon: Icons.lock_outline,
        color: AppColors.mutedForeground,
        title: context.tr('التسجيل يُفتح بعد موافقة الملعب'),
        body: context.tr(
          'ستتمكن من الانضمام فور موافقة الملعب على استضافة البطولة.',
        ),
      );
    }
    return _shell(
      context,
      icon: Icons.emoji_events_outlined,
      color: AppColors.primary,
      title: context.tr('انضم للبطولة'),
      body: null,
      children: [
        _step(
          context,
          Icons.check_circle_outline,
          context.tr('اضغط «انضم» ونضعك تلقائياً في أول مقعد شاغر.'),
        ),
        _step(
          context,
          Icons.group_add_outlined,
          context.tr(
            'تريد اللعب مع صديق؟ اختر «مع شريك» فتصله دعوة ويكون معك في الفريق نفسه.',
          ),
        ),
        if (cup.pricePerPlayer > 0)
          _step(
            context,
            Icons.account_balance_wallet_outlined,
            context.trArgs(
              'حصتك {p0} ر.س تُخصم من محفظتك، وتُعاد إن رُفض طلبك.',
              {'p0': money(cup.pricePerPlayer)},
            ),
          ),
        _step(
          context,
          Icons.verified_outlined,
          context.tr(
            'يوافق المنظّم على طلبك، وتُجرى القرعة تلقائياً عند اكتمال الفرق.',
          ),
        ),
      ],
    );
  }

  /// هل يظهر شريط أزرار الانضمام الثابت أسفل الصفحة.
  static bool actionsVisibleFor(CupEntity cup, int userId) =>
      visibleFor(cup, userId) &&
      !cup.isCancelled &&
      !cup.isPendingApproval &&
      !cup.hasPendingRequest(userId);

  Widget _shell(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String? body,
    List<Widget> children = const [],
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSizes.iconMd),
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
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
          if (children.isNotEmpty) const SizedBox(height: AppSizes.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _step(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
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

/// شريط الانضمام الثابت أسفل صفحة البطولة: المقاعد المتبقية وزرّا «انضم»
/// و«انضم مع شريك». الشرح يبقى في [CupJoinCard] أعلى الصفحة.
class CupJoinActions extends StatelessWidget {
  const CupJoinActions({
    super.key,
    required this.cup,
    required this.joining,
    required this.onJoin,
  });

  final CupEntity cup;
  final bool joining;
  final void Function(CupJoinMode mode) onJoin;

  int get _freeSeats =>
      cup.teams.fold(0, (sum, t) => sum + (2 - t.players.length).clamp(0, 2));
  bool get _hasEmptyTeam => cup.teams.any((t) => t.players.isEmpty);

  @override
  Widget build(BuildContext context) {
    final seats = _freeSeats;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          seats == 0
              ? context.tr('اكتمل العدد — لا توجد مقاعد شاغرة')
              : context.trArgs('متبقٍ {p0} من {p1} مقعد', {
                  'p0': seats,
                  'p1': cup.teamCount * 2,
                }),
          style: AppTextStyles.caption.copyWith(
            color: seats == 0
                ? AppColors.destructive
                : AppColors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (seats == 0 || joining)
                ? null
                : () => onJoin(CupJoinMode.solo),
            icon: joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(context.tr('انضم')),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: (!_hasEmptyTeam || joining)
                ? null
                : () => onJoin(CupJoinMode.withPartner),
            icon: const Icon(Icons.group_add_outlined),
            label: Text(
              _hasEmptyTeam
                  ? context.tr('انضم مع شريك')
                  : context.tr('لا يوجد فريق فارغ للانضمام مع شريك'),
            ),
          ),
        ),
      ],
    );
  }
}
