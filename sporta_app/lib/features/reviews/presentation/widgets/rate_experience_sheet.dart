import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/review_repository.dart';
import '../../domain/review_models.dart';
import 'review_widgets.dart';

/// يفتح نافذة تقييم التجربة من أي مكان (إشعار، بطاقة الرئيسية…): يجلب
/// الحالة أولاً ويُظهر رسالة إن لم يكن التقييم متاحاً.
Future<ReviewSession?> openReviewSheet(
  BuildContext context,
  ReviewContext reviewContext,
  int id,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final session = await getIt<ReviewRepository>().fetchSession(
      reviewContext,
      id,
    );
    if (!context.mounted) return null;
    if (!session.canReview) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr(reviewReasonText(session.reason)))),
      );
      return null;
    }
    return showRateExperienceSheet(context, session);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.display)));
    return null;
  }
}

String reviewReasonText(String? reason) => switch (reason) {
  'not_ended' => 'يمكنك التقييم بعد انتهاء التجربة',
  'cancelled' => 'التجربة ملغاة',
  'not_paid' => 'يمكن التقييم بعد دفع الجلسة',
  'not_confirmed' => 'الحجز غير مؤكد',
  'nothing' => 'لا يوجد من تقيّمه في هذه التجربة',
  _ => 'التقييم لأطراف التجربة فقط',
};

/// نافذة «كيف كانت تجربتك؟»: كل طرف يحقّ للمستخدم تقييمه (الملعب، المدرب،
/// اللاعبون) ببطاقة فيها نجوم ثم جوانب بحسب النجوم وتعليق اختياري. تُرسل
/// الدفعة كلها مرة واحدة وتعيد الحالة المحدّثة.
Future<ReviewSession?> showRateExperienceSheet(
  BuildContext context,
  ReviewSession session,
) => showModalBottomSheet<ReviewSession>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _RateExperienceSheet(session: session),
);

class _Draft {
  _Draft({this.score = 0, Set<String>? tags, this.comment = ''})
    : tags = tags ?? <String>{};

  int score;
  final Set<String> tags;
  String comment;
  bool showComment = false;
}

class _RateExperienceSheet extends StatefulWidget {
  const _RateExperienceSheet({required this.session});

  final ReviewSession session;

  @override
  State<_RateExperienceSheet> createState() => _RateExperienceSheetState();
}

class _RateExperienceSheetState extends State<_RateExperienceSheet> {
  late final Map<String, _Draft> _drafts = {
    for (final t in widget.session.targets)
      t.key: _Draft(
        score: t.myReview?.score ?? 0,
        tags: {...?t.myReview?.tags},
        comment: t.myReview?.comment ?? '',
      )..showComment = (t.myReview?.comment?.isNotEmpty ?? false),
  };
  bool _saving = false;

  /// ما تغيّر عن التقييم المحفوظ (أو جديد) — هو ما يُرسل.
  List<ReviewDraft> get _changes {
    final out = <ReviewDraft>[];
    for (final t in widget.session.targets) {
      final d = _drafts[t.key]!;
      if (d.score == 0) continue;
      final m = t.myReview;
      final same =
          m != null &&
          m.score == d.score &&
          (m.comment ?? '') == d.comment.trim() &&
          m.tags.toSet().length == d.tags.length &&
          m.tags.toSet().containsAll(d.tags);
      if (same) continue;
      out.add(
        ReviewDraft(
          type: t.type,
          id: t.id,
          score: d.score,
          tags: d.tags.toList(),
          comment: d.comment,
        ),
      );
    }
    return out;
  }

  Future<void> _submit() async {
    final changes = _changes;
    if (changes.isEmpty || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // أول تقييم للملعب يمنح نقاط مكافآت — تُذكر في رسالة الشكر.
    final rewardsCourt = widget.session.targets.any(
      (t) =>
          t.type == ReviewTargetType.court &&
          t.myReview == null &&
          changes.any((c) => c.type == ReviewTargetType.court),
    );
    setState(() => _saving = true);
    try {
      final updated = await getIt<ReviewRepository>().submit(
        widget.session.context,
        widget.session.contextId,
        changes,
      );
      if (!mounted) return;
      navigator.pop(updated);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              rewardsCourt
                  ? 'شكراً لتقييمك! أُضيفت نقاط المكافآت لرصيدك'
                  : 'شكراً — حُفظت تقييماتك',
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final changes = _changes.length;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.sm,
              ),
              child: _header(context, s),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.sm,
                  AppSizes.lg,
                  AppSizes.lg,
                ),
                itemCount: s.targets.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
                itemBuilder: (_, i) => _targetCard(context, s.targets[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.sm,
                AppSizes.lg,
                AppSizes.md,
              ),
              child: SizedBox(
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: changes == 0 || _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          changes == 0
                              ? context.tr('اختر النجوم للتقييم')
                              : context.trArgs('إرسال التقييمات ({p0})', {
                                  'p0': changes,
                                }),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ReviewSession s) {
    final when = s.startsAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('كيف كانت تجربتك؟'),
          style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          [
            context.tr(reviewKindLabel(s.kind)),
            if (s.title.isNotEmpty) s.title,
            if (when != null) AppDates.dayMonth(when),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          context.tr('قيّم كل طرف — تقييمات اللاعبين لا تظهر بأسماء مقيّميها'),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _targetCard(BuildContext context, ReviewTarget t) {
    final d = _drafts[t.key]!;
    final rated = t.myReview != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: d.score > 0
            ? kStarColor.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: d.score > 0
              ? kStarColor.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReviewAvatar(
                name: t.name,
                url: t.imageUrl,
                isCourt: t.type == ReviewTargetType.court,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ReviewRoleBadge(role: t.role),
                        if (rated) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.tr('قيّمته'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              StarPicker(
                value: d.score,
                onChanged: (v) => setState(() {
                  // الجوانب تتبع النجوم: الانتقال بين الثناء والتحسين يفرغها.
                  if ((v >= 4) != (d.score >= 4)) d.tags.clear();
                  d.score = v;
                }),
              ),
              const SizedBox(width: AppSizes.sm),
              if (d.score > 0)
                Flexible(
                  child: Text(
                    context.tr(reviewScoreLabel(d.score)),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (d.score > 0) ...[
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in ReviewTag.forType(t.type))
                  ReviewTagChip(
                    tag: tag,
                    score: d.score,
                    selected: d.tags.contains(tag.key),
                    onTap: () => setState(() {
                      if (!d.tags.remove(tag.key)) d.tags.add(tag.key);
                    }),
                  ),
              ],
            ),
            if (d.showComment)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.sm),
                child: TextFormField(
                  initialValue: d.comment,
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 500,
                  onChanged: (v) => setState(() => d.comment = v),
                  decoration: InputDecoration(
                    hintText: context.tr('اكتب تعليقاً (اختياري)'),
                    isDense: true,
                  ),
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => d.showComment = true),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(context.tr('أضف تعليقاً')),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
