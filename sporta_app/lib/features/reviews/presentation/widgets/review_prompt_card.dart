import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/storage/local_prefs.dart';
import '../../data/review_repository.dart';
import '../../domain/review_models.dart';
import 'rate_experience_sheet.dart';
import 'review_widgets.dart';

/// بطاقة «كيف كانت تجربتك؟» في صفحة تفاصيل التجربة (مباراة، أمريكانو،
/// بطولة، حجز، جلسة تدريب). تجلب حالتها بنفسها وتختفي ما لم يكن التقييم
/// متاحاً للمستخدم. بعد التقييم تعرض التقدّم («3 من 5») مع «تعديل».
class ReviewPromptCard extends StatefulWidget {
  const ReviewPromptCard({
    super.key,
    required this.reviewContext,
    required this.contextId,
    this.padding,
    this.onChanged,
  });

  final ReviewContext reviewContext;
  final int contextId;

  /// هامش حول البطاقة حين تظهر (لا يُترك فراغ حين تختفي).
  final EdgeInsetsGeometry? padding;

  /// بعد حفظ تقييمات (لتحديث الصفحة الأم إن لزم).
  final VoidCallback? onChanged;

  @override
  State<ReviewPromptCard> createState() => _ReviewPromptCardState();
}

class _ReviewPromptCardState extends State<ReviewPromptCard> {
  ReviewSession? _session;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReviewPromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextId != widget.contextId ||
        oldWidget.reviewContext != widget.reviewContext) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final s = await getIt<ReviewRepository>().fetchSession(
        widget.reviewContext,
        widget.contextId,
      );
      if (mounted) setState(() => _session = s);
    } catch (_) {
      // ميزة مساعدة: الفشل يخفي البطاقة فقط.
    }
  }

  Future<void> _open() async {
    final s = _session;
    if (s == null) return;
    final updated = await showRateExperienceSheet(context, s);
    if (updated != null && mounted) {
      setState(() => _session = updated);
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null || !s.canReview || s.targets.isEmpty) {
      return const SizedBox.shrink();
    }
    final done = s.allRated;
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: done
                ? null
                : LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      kStarColor.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.10),
                    ],
                  ),
            color: done ? AppColors.card : null,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(
              color: done
                  ? AppColors.border
                  : kStarColor.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ReviewAvatarStack(targets: s.targets),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            done ? 'شكراً لتقييمك' : 'كيف كانت تجربتك؟',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          done
                              ? context.trArgs('قيّمت {p0} — يمكنك التعديل', {
                                  'p0': reviewWhom(context, s.targets),
                                })
                              : context.trArgs('قيّم {p0}', {
                                  'p0': reviewWhom(context, s.targets),
                                }),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: s.ratedCount / s.targets.length,
                        minHeight: 6,
                        backgroundColor: AppColors.muted,
                        valueColor: const AlwaysStoppedAnimation(kStarColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    context.trArgs('{p0} من {p1}', {
                      'p0': s.ratedCount,
                      'p1': s.targets.length,
                    }),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    context.tr(done ? 'تعديل' : 'قيّم الآن'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return widget.padding == null
        ? card
        : Padding(padding: widget.padding!, child: card);
  }
}

/// «الملعب و3 لاعبين» — ملخّص من سيُقيَّم.
String reviewWhom(BuildContext context, List<ReviewTarget> targets) {
  final court = targets.any((t) => t.type == ReviewTargetType.court);
  final coach = targets.any((t) => t.type == ReviewTargetType.coach);
  final players = targets
      .where((t) => t.type == ReviewTargetType.player)
      .length;
  final parts = <String>[
    if (court) context.tr('الملعب'),
    if (coach) context.tr('المدرب'),
    if (players == 1)
      context.tr('اللاعب')
    else if (players > 1)
      context.trArgs('{p0} لاعبين', {'p0': players}),
  ];
  return parts.join(context.tr(' و'));
}

/// صور أول ثلاثة أطراف متداخلة.
class ReviewAvatarStack extends StatelessWidget {
  const ReviewAvatarStack({super.key, required this.targets});

  final List<ReviewTarget> targets;

  @override
  Widget build(BuildContext context) {
    final shown = targets.take(3).toList();
    const size = 38.0;
    const step = 24.0;
    return SizedBox(
      width: size + step * (shown.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * step,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: shown[i].type == ReviewTargetType.court
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius: shown[i].type == ReviewTargetType.court
                      ? BorderRadius.circular(AppSizes.radiusLg)
                      : null,
                ),
                child: ReviewAvatar(
                  name: shown[i].name,
                  url: shown[i].imageUrl,
                  isCourt: shown[i].type == ReviewTargetType.court,
                  size: size - 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة الرئيسية (للاعب والمدرب وصاحب الملعب): أحدث تجربة انتهت وفيها
/// أطراف لم تُقيَّم. تخفي نفسها إن لم يوجد شيء (ومنه الزائر).
class PendingReviewsCard extends StatefulWidget {
  const PendingReviewsCard({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  State<PendingReviewsCard> createState() => _PendingReviewsCardState();
}

class _PendingReviewsCardState extends State<PendingReviewsCard> {
  List<PendingReview> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await getIt<ReviewRepository>().fetchPending();
      // ما أخفاه المستخدم بعلامة الإغلاق لا يعود — التقييم اختياري.
      final visible = items
          .where((p) => !LocalPrefs.isReviewDismissed(_key(p)))
          .toList();
      if (mounted) setState(() => _items = visible);
    } catch (_) {
      // الزائر أو تعذّر الجلب: لا بطاقة.
    }
  }

  Future<void> _open(PendingReview p) async {
    final updated = await openReviewSheet(context, p.context, p.contextId);
    if (updated != null && mounted) _load();
  }

  static String _key(PendingReview p) => '${p.context.apiName}-${p.contextId}';

  /// علامة الإغلاق: تُخفي هذه التجربة من الرئيسية (تبقى قابلة للتقييم من
  /// صفحة تفاصيلها) وتظهر التالية إن وُجدت.
  Future<void> _dismiss(PendingReview p) async {
    await LocalPrefs.dismissReview(_key(p));
    if (!mounted) return;
    setState(() => _items = _items.where((e) => e != p).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final p = _items.first;
    final card = Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        side: BorderSide(color: kStarColor.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () => _open(p),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              ReviewAvatar(
                name: p.title,
                url: p.imageUrl,
                isCourt: p.kind != 'session' || p.imageUrl == null,
                size: 52,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('كيف كانت تجربتك؟'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        context.tr(reviewKindLabel(p.kind)),
                        if (p.title.isNotEmpty) p.title,
                        AppDates.dayMonth(p.startsAt),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          const Icon(
                            Icons.star_outline_rounded,
                            size: 20,
                            color: kStarColor,
                          ),
                        const SizedBox(width: AppSizes.sm),
                        Flexible(
                          child: Text(
                            context.trArgs('{p0} بانتظار تقييمك', {
                              'p0': p.pendingCount,
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_items.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '+${_items.length - 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final withClose = Stack(
      children: [
        card,
        PositionedDirectional(
          top: 4,
          end: 4,
          child: IconButton(
            tooltip: context.tr('إخفاء'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _dismiss(p),
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
    return widget.padding == null
        ? withClose
        : Padding(padding: widget.padding!, child: withClose);
  }
}
