import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../state/app_scope.dart';

/// حوار النجاح بعد حجز أو إنشاء (مباراة / أمريكانو / بطولة): أيقونة وعنوان
/// ورسالة وملاحظة اختيارية، وشريط يعدّ تنازلياً ثم يُغلق الحوار وحده بعد
/// [autoClose]. «متابعة» تغلقه وتنفّذ [onContinue] (فتح صفحة التفاصيل).
///
/// يُعرض على [nav] بعد إغلاق صفحة الإضافة، فيبقى المستخدم على القائمة إن
/// أُغلق الحوار، ويعود إليها — لا إلى حقول الإضافة — إن رجع من التفاصيل.
Future<void> showSuccessDialog(
  NavigatorState nav, {
  required String title,
  required String message,
  String? note,
  required VoidCallback onContinue,
  Duration autoClose = const Duration(seconds: 6),
}) async {
  final go = await showGeneralDialog<bool>(
    context: nav.context,
    barrierDismissible: true,
    barrierLabel: 'success',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => _SuccessDialog(
      title: title,
      message: message,
      note: note,
      autoClose: autoClose,
    ),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
  if (go == true) onContinue();
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.note,
    required this.autoClose,
  });

  final String title;
  final String message;
  final String? note;
  final Duration autoClose;

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown =
      AnimationController(vsync: this, duration: widget.autoClose)
        ..addStatusListener((s) {
          // يُغلق وحده ما دام ظاهراً (لم يُغلقه المستخدم قبل انتهاء العدّ).
          if (s == AnimationStatus.completed &&
              mounted &&
              ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop(false);
          }
        })
        ..forward();

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.xl, AppSizes.xxl, AppSizes.xl, AppSizes.lg),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 44),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                          color: AppColors.secondary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.secondary),
                    ),
                    if (widget.note != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_outlined,
                                size: AppSizes.iconSm, color: AppColors.primary),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                widget.note!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(context.tr('متابعة')),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(context.tr('إغلاق'),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.mutedForeground)),
                    ),
                  ],
                ),
              ),
              // العدّ التنازلي حتى الإغلاق التلقائي.
              AnimatedBuilder(
                animation: _countdown,
                builder: (_, _) => LinearProgressIndicator(
                  value: 1 - _countdown.value,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
