import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/entities/points_entity.dart';

const kRewardGold = Color(0xFFFACC15);
const kLevelTeal = Color(0xFF5EEAD4);

/// رأس صفحة النقاط: بطاقتا «نقاط المكافآت» و«نقاط المستوى» جنباً إلى جنب
/// فوق التدرّج، ثم زر الاستبدال.
class PointsSummaryHeader extends StatelessWidget {
  const PointsSummaryHeader({
    super.key,
    required this.summary,
    required this.onBack,
    required this.onRedeem,
  });

  final PointsSummaryEntity? summary;
  final VoidCallback onBack;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const DirectionalIcon(
                        rtl: Icons.arrow_forward,
                        ltr: Icons.arrow_back,
                        color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(context.tr('نقاطي'),
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      icon: Icons.stars_rounded,
                      tint: kRewardGold,
                      label: context.tr('نقاط المكافآت'),
                      value: '${s?.balance ?? 0}',
                      caption: s == null
                          ? ''
                          : '≈ ${s.balanceValueSar.toStringAsFixed(0)} ${context.tr('ر.س')}',
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _BalanceCard(
                      icon: Icons.trending_up_rounded,
                      tint: kLevelTeal,
                      label: context.tr('نقاط المستوى'),
                      value: _signed(s?.levelPoints ?? 0),
                      caption: s == null
                          ? ''
                          : s.levelPointsUnlocked
                              ? context.tr('معتمد من مدرب')
                              : context.tr('بانتظار اعتماد مدرب'),
                      captionIcon: s == null
                          ? null
                          : s.levelPointsUnlocked
                              ? Icons.verified_rounded
                              : Icons.lock_outline_rounded,
                    ),
                  ),
                ],
              ),
              if (s != null) ...[
                if (s.multiplier > 1) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: kRewardGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '${context.tr('مشترك Sporta Plus — نقاطك مضاعفة')} ×${_trimNum(s.multiplier)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: const Color(0xFFFDE68A)),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: s.canRedeem ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      // الحالة المعطّلة تُرسم على الترويسة الداكنة، فلونها
                      // الرمادي الافتراضي كان يذوب فيها — تُعرض بنص أبيض
                      // كامل على خلفية شفافة بإطار واضح.
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                      disabledForegroundColor: Colors.white,
                      side: s.canRedeem
                          ? null
                          : BorderSide(
                              color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    icon: Icon(s.canRedeem
                        ? Icons.swap_horiz_rounded
                        : Icons.lock_outline_rounded),
                    label: Text(
                      s.canRedeem
                          ? context.tr('استبدال النقاط برصيد محفظة')
                          : '${context.tr('الحد الأدنى للاستبدال')}: ${s.minRedeemPoints} ${context.tr('نقطة')}',
                      style: AppTextStyles.body.copyWith(
                        color: s.canRedeem ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _signed(int v) => v > 0 ? '+$v' : '$v';

  static String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.caption,
    this.captionIcon,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String caption;
  final IconData? captionIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85))),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(value,
              style: AppTextStyles.heading1
                  .copyWith(color: Colors.white, fontSize: 32)),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                if (captionIcon != null) ...[
                  Icon(captionIcon, size: 14, color: tint),
                  const SizedBox(width: AppSizes.xs),
                ],
                Expanded(
                  child: Text(caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
