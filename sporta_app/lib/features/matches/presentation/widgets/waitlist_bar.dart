import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../domain/entities/waitlist.dart';

/// شريط قائمة الانتظار أسفل صفحة الحدث لغير المشارك. يجلب حالته بنفسه
/// ويعرض واحداً من:
/// * **دورك جاء** — المقعد محجوز لك دقائق معدودة، وزر طلب الانضمام.
/// * **أنت في القائمة** — ترتيبك وزر المغادرة.
/// * **الحدث مكتمل** — زر التسجيل في القائمة وعدد المنتظرين.
/// * وإلا [fallback] (زر الانضمام العادي): لا قائمة لهذا الحدث أو فيه مقعد متاح.
///
/// غيّر [key] حين يتغيّر الحدث (عدد اللاعبين/حالته) ليُعاد جلب الحالة.
class WaitlistBar extends StatefulWidget {
  const WaitlistBar({
    super.key,
    required this.fetch,
    required this.join,
    required this.leave,
    required this.onRequestJoin,
    required this.fallback,
    this.requesting = false,
  });

  final Future<WaitlistStatus> Function() fetch;
  final Future<WaitlistStatus> Function() join;
  final Future<WaitlistStatus> Function() leave;

  /// طلب الانضمام الفعلي حين يأتي الدور (نفس مسار زر الانضمام: تأكيد الحصة…).
  final VoidCallback onRequestJoin;

  /// ما يُعرض حين لا تخصّ القائمة المستخدم.
  final Widget fallback;

  /// طلب الانضمام قيد الإرسال (يعطّل الزر).
  final bool requesting;

  @override
  State<WaitlistBar> createState() => _WaitlistBarState();
}

class _WaitlistBarState extends State<WaitlistBar> {
  WaitlistStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await widget.fetch();
      if (mounted) setState(() => _status = s);
    } catch (_) {
      // تعذّر الجلب: يبقى زر الانضمام العادي — القائمة ميزة مساعدة.
    }
  }

  Future<void> _run(
    Future<WaitlistStatus> Function() action,
    String Function() done,
  ) async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final s = await action();
      if (!mounted) return;
      setState(() {
        _status = s;
        _busy = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(done())));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null || !s.supported) return widget.fallback;

    if (s.offerActive) return _offer(context, s);
    if (s.isWaiting) return _waiting(context, s);
    if (s.canJoin) return _joinPrompt(context, s);
    if (s.seatReservedForOthers) {
      return _note(
        context,
        icon: Icons.lock_clock_outlined,
        color: AppColors.mutedForeground,
        text: context.tr('المقعد الشاغر محجوز لمن ينتظر في قائمة الانتظار'),
      );
    }
    return widget.fallback;
  }

  /// جاء دوره: المقعد محجوز له، وطلب الانضمام بضغطة.
  Widget _offer(BuildContext context, WaitlistStatus s) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_seat_rounded,
                color: AppColors.success,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.tr('فرغ مقعد لك — جاء دورك!'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            context.trArgs(
              'المقعد محجوز لك {p0} دقيقة، ثم ينتقل للتالي في القائمة.',
              {'p0': s.offerMinutesLeft ?? s.offerWindowMinutes},
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.requesting ? null : widget.onRequestJoin,
              icon: widget.requesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(context.tr('طلب الانضمام الآن')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                    widget.leave,
                    () => context.tr('غادرت قائمة الانتظار'),
                  ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedForeground,
            ),
            child: Text(context.tr('لم أعد مهتماً — مرّره للتالي')),
          ),
        ],
      ),
    );
  }

  /// في القائمة ينتظر دوره.
  Widget _waiting(BuildContext context, WaitlistStatus s) {
    return Row(
      children: [
        Expanded(
          child: _note(
            context,
            icon: Icons.hourglass_top_rounded,
            color: AppColors.primary,
            text: context.trArgs('أنت رقم {p0} في قائمة الانتظار', {
              'p0': s.position!,
            }),
            sub: context.tr('يصلك إشعار فور أن يفرغ مقعد'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(
                  widget.leave,
                  () => context.tr('غادرت قائمة الانتظار'),
                ),
          style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
          child: Text(context.tr('مغادرة')),
        ),
      ],
    );
  }

  /// الحدث مكتمل: التسجيل في القائمة.
  Widget _joinPrompt(BuildContext context, WaitlistStatus s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.count == 0
              ? context.tr('مكتمل — كن أول من في قائمة الانتظار')
              : context.trArgs('مكتمل — {p0} في قائمة الانتظار', {
                  'p0': s.count,
                }),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                    widget.join,
                    () => context.tr(
                      'سُجّلت في قائمة الانتظار — يصلك إشعار حين يأتي دورك',
                    ),
                  ),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.playlist_add_rounded),
            label: Text(context.tr('انضم لقائمة الانتظار')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          context.trArgs('مجاني — يُحجز لك المقعد {p0} دقيقة حين يأتي دورك', {
            'p0': s.offerWindowMinutes,
          }),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _note(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
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
