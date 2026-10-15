import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../state/app_scope.dart';

// ─────────────────────────────────────────────────────────────────────────────
// شكل التحميل الموحّد في التطبيق.
//
// 1) الهيكل المتوهج (Skeleton) — الافتراضي: مستطيلات رمادية بشكل المحتوى
//    القادم يمرّ عليها لمعان. [Shimmer] يلفّ مجموعة [SkeletonBox] فتلمع معاً
//    بحركة واحدة. أشكال جاهزة: [SkeletonList] (صفوف/بطاقات قائمة)،
//    [SkeletonCardList] (بطاقات بصورة)، [SkeletonDetail] (صفحة تفاصيل).
// 2) [BrandedLoader] — حيث لا يناسب الهيكل (محتوى غير متوقع الشكل): دائرة
//    دوّارة حول أيقونة التطبيق وتحتها «جارٍ التحميل…».
//
// القاعدة: الترويسة وزر الرجوع يبقيان ظاهرين دائماً؛ يُستبدل المحتوى وحده.
// ─────────────────────────────────────────────────────────────────────────────

const Color _base = Color(0xFFE9EDF1);
const Color _highlight = Color(0xFFF6F8FA);

/// يلمّع كل [SkeletonBox] تحته بحركة واحدة متزامنة. كل مستطيل يرسم لمعانه
/// بنفسه من هذه الحركة المشتركة، فالبطاقات البيضاء حولها تبقى بيضاء.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(notifier: _c, child: widget.child);
}

class _ShimmerScope extends InheritedNotifier<Animation<double>> {
  const _ShimmerScope({required super.notifier, required super.child});

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.notifier;
}

/// يزيح التدرّج أفقياً مع تقدّم الحركة (من خارج اليسار إلى خارج اليمين).
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// مستطيل رمادي بحجم عنصر قادم (نص، صورة، زر…). يلمع داخل [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSizes.radiusSm,
  });

  /// null = بعرض المساحة المتاحة.
  final double? width;
  final double height;
  final double radius;

  /// دائرة (صورة شخصية، أيقونة).
  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = AppSizes.radiusFull;

  @override
  Widget build(BuildContext context) {
    final t = _ShimmerScope.of(context)?.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t == null ? _base : null,
        gradient: t == null
            ? null
            : LinearGradient(
                colors: const [_base, _highlight, _base],
                stops: const [0.3, 0.5, 0.7],
                transform: _SlideGradient(t),
              ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// إطار بطاقة بيضاء (كبطاقات التطبيق) يضم هيكلاً بداخله.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

/// صفوف قائمة: دائرة + سطران + شارة — لقوائم المباريات والحجوزات والإشعارات
/// والأصدقاء وأمثالها. [shrinkWrap] حين تكون داخل قائمة/عمود أكبر.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppSizes.pagePadding),
    this.shrinkWrap = false,
    this.showAvatar = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var i = 0; i < itemCount; i++) ...[
        _SkeletonCard(
          child: Row(
            children: [
              if (showAvatar) ...[
                const SkeletonBox.circle(size: 44),
                const SizedBox(width: AppSizes.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: i.isEven ? 160 : 120),
                    const SizedBox(height: AppSizes.sm),
                    SkeletonBox(height: 10, width: i.isEven ? 110 : 140),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const SkeletonBox(width: 56, height: 24, radius: AppSizes.radiusFull),
            ],
          ),
        ),
        if (i != itemCount - 1) const SizedBox(height: AppSizes.md),
      ],
    ];
    return Shimmer(
      child: shrinkWrap
          ? Padding(padding: padding, child: Column(children: rows))
          : ListView(
              padding: padding,
              physics: const NeverScrollableScrollPhysics(),
              children: rows,
            ),
    );
  }
}

/// بطاقات بصورة (ملاعب، مدربون، بطولات، إعلانات): صورة ثم سطور ثم زر.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.itemCount = 3,
    this.imageHeight = 140,
    this.padding = const EdgeInsets.all(AppSizes.pagePadding),
    this.shrinkWrap = false,
  });

  final int itemCount;
  final double imageHeight;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (var i = 0; i < itemCount; i++) ...[
        _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: imageHeight, radius: AppSizes.radiusLg),
              const SizedBox(height: AppSizes.md),
              const SkeletonBox(height: 16, width: 180),
              const SizedBox(height: AppSizes.sm),
              const SkeletonBox(height: 10, width: 130),
              const SizedBox(height: AppSizes.md),
              const Row(
                children: [
                  SkeletonBox(width: 70, height: 20),
                  Spacer(),
                  SkeletonBox(width: 96, height: 36, radius: AppSizes.radiusLg),
                ],
              ),
            ],
          ),
        ),
        if (i != itemCount - 1) const SizedBox(height: AppSizes.lg),
      ],
    ];
    return Shimmer(
      child: shrinkWrap
          ? Padding(padding: padding, child: Column(children: cards))
          : ListView(
              padding: padding,
              physics: const NeverScrollableScrollPhysics(),
              children: cards,
            ),
    );
  }
}

/// صفحة تفاصيل (مباراة، أمريكانو، بطولة، حجز، ملعب، مدرب…): صف إحصاءات،
/// بطاقة معلومات بأسطر، ثم قائمة أعضاء. يوضع تحت الترويسة مكان المحتوى.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({
    super.key,
    this.padding = const EdgeInsets.all(AppSizes.pagePadding),
    this.showStats = true,
    this.memberRows = 3,
  });

  final EdgeInsetsGeometry padding;
  final bool showStats;
  final int memberRows;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (showStats) ...[
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 72, radius: AppSizes.radiusLg)),
                SizedBox(width: AppSizes.md),
                Expanded(child: SkeletonBox(height: 72, radius: AppSizes.radiusLg)),
                SizedBox(width: AppSizes.md),
                Expanded(child: SkeletonBox(height: 72, radius: AppSizes.radiusLg)),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
          ],
          _SkeletonCard(
            child: Column(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  Row(
                    children: [
                      const SkeletonBox.circle(size: 20),
                      const SizedBox(width: AppSizes.sm),
                      SkeletonBox(height: 12, width: i.isEven ? 70 : 90),
                      const Spacer(),
                      SkeletonBox(height: 12, width: i.isEven ? 110 : 80),
                    ],
                  ),
                  if (i != 4) const SizedBox(height: AppSizes.lg),
                ],
              ],
            ),
          ),
          if (memberRows > 0) ...[
            const SizedBox(height: AppSizes.xl),
            const SkeletonBox(height: 16, width: 140),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < memberRows; i++) ...[
              _SkeletonCard(
                child: Row(
                  children: [
                    const SkeletonBox.circle(size: 40),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 12, width: i.isEven ? 130 : 100),
                          const SizedBox(height: AppSizes.sm),
                          const SkeletonBox(height: 10, width: 70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i != memberRows - 1) const SizedBox(height: AppSizes.sm),
            ],
          ],
        ],
      ),
    );
  }
}

/// الخيار الثاني: دائرة دوّارة حول أيقونة التطبيق وتحتها نص — للمحتوى الذي
/// لا يُتوقّع شكله (نموذج، محادثة، صفحة حالة…). يتوسّط المساحة المتاحة.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key, this.label, this.icon = Icons.sports_tennis});

  /// null = «جارٍ التحميل…».
  final String? label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox.expand(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.muted,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            label ?? context.tr('جارٍ التحميل…'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
